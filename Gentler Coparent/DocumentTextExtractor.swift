import Foundation
import PDFKit
@preconcurrency import Vision
#if canImport(UIKit)
import UIKit
#endif

// MARK: - High-quality text extraction for decrees / legal PDFs & images
/// Full-document extraction — no arbitrary “first N pages only” for native PDF text.
/// OCR may take longer on huge scanned PDFs but processes **all** pages.
enum DocumentTextExtractor {
    
    struct ExtractionResult: Sendable {
        let text: String
        let pageCount: Int
        let pagesWithNativeText: Int
        let pagesOCR: Int
        let usedOCR: Bool
    }
    
    /// Extract text from PDF (all pages native text; OCR every page when sparse).
    static func extractText(from url: URL) async -> String? {
        let result = await extractDetailed(from: url)
        return result?.text
    }
    
    /// Same as `extractText` plus page/OCR stats for UI.
    static func extractDetailed(from url: URL) async -> ExtractionResult? {
        let ext = url.pathExtension.lowercased()
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        
        if ext == "pdf" {
            return await extractFromPDF(url)
        }
        if ["jpg", "jpeg", "png", "heic", "tif", "tiff"].contains(ext) {
            #if canImport(UIKit)
            guard let data = try? Data(contentsOf: url), let image = UIImage(data: data) else { return nil }
            guard let text = await ocrImage(image), !text.isEmpty else { return nil }
            return ExtractionResult(text: text, pageCount: 1, pagesWithNativeText: 0, pagesOCR: 1, usedOCR: true)
            #else
            return nil
            #endif
        }
        // Fallback: try PDF then image
        if let pdf = await extractFromPDF(url) { return pdf }
        #if canImport(UIKit)
        if let data = try? Data(contentsOf: url), let image = UIImage(data: data),
           let text = await ocrImage(image), !text.isEmpty {
            return ExtractionResult(text: text, pageCount: 1, pagesWithNativeText: 0, pagesOCR: 1, usedOCR: true)
        }
        #endif
        return nil
    }
    
    private static func extractFromPDF(_ url: URL) async -> ExtractionResult? {
        guard let pdf = PDFDocument(url: url) else { return nil }
        let pageCount = pdf.pageCount
        guard pageCount > 0 else { return nil }
        
        // 1) Native text layer — **every** page (cheap; digital decrees must not be truncated)
        var native = ""
        var pagesWithNative = 0
        for i in 0..<pageCount {
            if let page = pdf.page(at: i) {
                let s = page.string ?? ""
                if !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    pagesWithNative += 1
                }
                if i > 0 { native += "\n\n--- PAGE \(i + 1) ---\n\n" }
                native += s
                if !s.isEmpty && !s.hasSuffix("\n") { native += "\n" }
            }
        }
        let trimmedNative = cleaned(native)
        
        // Per-page density: if many pages have almost no text, document is likely scanned
        let avgCharsPerPage = pageCount > 0 ? Double(trimmedNative.count) / Double(pageCount) : 0
        let words = trimmedNative.split { $0.isWhitespace || $0.isNewline }.count
        let sparseOverall = trimmedNative.count < 400 || words < 60
        let sparseAverage = avgCharsPerPage < 80 && pageCount > 2
        // Hybrid: native has *some* text but missing most pages (common with mixed PDFs)
        let missingPages = pagesWithNative < max(1, pageCount * 2 / 3)
        let needsOCR = sparseOverall || sparseAverage || (missingPages && pageCount > 3)
        
        #if DEBUG
        print("📄 Decree extract: \(pageCount) pages, native chars=\(trimmedNative.count), pagesWithText=\(pagesWithNative), needsOCR=\(needsOCR)")
        #endif
        
        if !needsOCR {
            return ExtractionResult(
                text: trimmedNative,
                pageCount: pageCount,
                pagesWithNativeText: pagesWithNative,
                pagesOCR: 0,
                usedOCR: false
            )
        }
        
        // 2) OCR **all** pages for scanned / sparse PDFs (memory-aware scale)
        #if canImport(UIKit)
        var ocrChunks: [String] = []
        var pagesOCR = 0
        // Lower scale on very long docs to stay under memory pressure
        let scale: CGFloat = pageCount > 40 ? 1.5 : (pageCount > 20 ? 1.75 : 2.0)
        
        for i in 0..<pageCount {
            guard let page = pdf.page(at: i) else { continue }
            
            // Skip OCR when this page already has rich native text (hybrid PDFs)
            let nativePage = (page.string ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if nativePage.count >= 200 {
                ocrChunks.append(nativePage)
                continue
            }
            
            let pageRect = page.bounds(for: .mediaBox)
            let size = CGSize(width: pageRect.width * scale, height: pageRect.height * scale)
            // Guard absurd page sizes
            let maxDim: CGFloat = 3500
            let clampedSize = CGSize(
                width: min(size.width, maxDim),
                height: min(size.height, maxDim)
            )
            let renderScale = clampedSize.width / max(pageRect.width, 1)
            
            let renderer = UIGraphicsImageRenderer(size: clampedSize)
            let image = renderer.image { ctx in
                UIColor.white.set()
                ctx.fill(CGRect(origin: .zero, size: clampedSize))
                ctx.cgContext.translateBy(x: 0, y: clampedSize.height)
                ctx.cgContext.scaleBy(x: renderScale, y: -renderScale)
                page.draw(with: .mediaBox, to: ctx.cgContext)
            }
            
            if let pageText = await ocrImage(image), !pageText.isEmpty {
                ocrChunks.append(pageText)
                pagesOCR += 1
            } else if !nativePage.isEmpty {
                ocrChunks.append(nativePage)
            }
            
            // Yield so UI stays responsive on 80+ page decrees
            if i % 3 == 2 {
                await Task.yield()
            }
        }
        
        var ocrJoined = ""
        for (idx, chunk) in ocrChunks.enumerated() {
            if idx > 0 { ocrJoined += "\n\n--- PAGE \(idx + 1) ---\n\n" }
            ocrJoined += chunk
        }
        ocrJoined = cleaned(ocrJoined)
        
        // Prefer richer result; if OCR failed partially, merge: keep longer of the two
        let finalText: String
        let usedOCR: Bool
        if ocrJoined.count >= trimmedNative.count {
            finalText = ocrJoined
            usedOCR = pagesOCR > 0
        } else if !trimmedNative.isEmpty {
            finalText = trimmedNative
            usedOCR = false
        } else {
            finalText = ocrJoined
            usedOCR = pagesOCR > 0
        }
        
        guard !finalText.isEmpty else { return nil }
        
        #if DEBUG
        print("📄 Decree extract done: finalChars=\(finalText.count), OCR pages=\(pagesOCR)/\(pageCount)")
        #endif
        
        return ExtractionResult(
            text: finalText,
            pageCount: pageCount,
            pagesWithNativeText: pagesWithNative,
            pagesOCR: pagesOCR,
            usedOCR: usedOCR
        )
        #else
        guard !trimmedNative.isEmpty else { return nil }
        return ExtractionResult(
            text: trimmedNative,
            pageCount: pageCount,
            pagesWithNativeText: pagesWithNative,
            pagesOCR: 0,
            usedOCR: false
        )
        #endif
    }
    
    #if canImport(UIKit)
    static func ocrImage(_ image: UIImage) async -> String? {
        // Encode to Sendable `Data` so background work doesn't capture non-Sendable Vision/UIKit types.
        guard let imageData = image.jpegData(compressionQuality: 0.92) ?? image.pngData() else { return nil }
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                guard let uiImage = UIImage(data: imageData),
                      let cgImage = uiImage.cgImage else {
                    continuation.resume(returning: nil)
                    return
                }
                
                // Build request + handler entirely on this queue (no cross-isolation capture).
                let request = VNRecognizeTextRequest()
                request.recognitionLevel = .accurate
                request.usesLanguageCorrection = true
                request.recognitionLanguages = ["en-US"]
                if #available(iOS 16.0, *) {
                    request.automaticallyDetectsLanguage = true
                }
                
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                do {
                    try handler.perform([request])
                    let observations = request.results ?? []
                    let lines = observations.compactMap { $0.topCandidates(1).first?.string }
                    let text = lines.joined(separator: "\n")
                    continuation.resume(returning: text.isEmpty ? nil : cleaned(text))
                } catch {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    #endif
    
    private static func cleaned(_ text: String) -> String {
        var t = text
        t = t.replacingOccurrences(of: "\u{00a0}", with: " ")
        t = t.replacingOccurrences(of: #"\r\n"#, with: "\n", options: .regularExpression)
        t = t.replacingOccurrences(of: #"[ \t]+\n"#, with: "\n", options: .regularExpression)
        t = t.replacingOccurrences(of: #"\n{3,}"#, with: "\n\n", options: .regularExpression)
        return t.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

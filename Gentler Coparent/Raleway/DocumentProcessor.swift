import PDFKit

class DocumentProcessor {
    static func extractTextFromPDF(url: URL) -> String? {
        guard let pdfDocument = PDFDocument(url: url) else { return nil }
        return pdfDocument.string
    }
    
    @MainActor
    static func handleDocumentUpload(url: URL, chatManager: ChatManager, setMessage: (String) -> Void) {
        do {
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }

            let data = try Data(contentsOf: url)
            if let text = String(data: data, encoding: .utf8) {
                chatManager.addMessage(ChatMessage(sender: "You", text: "Uploaded text: \(text.prefix(100))..."))
                setMessage("Respond based on the uploaded text.")
            } else if let pdfText = extractTextFromPDF(url: url) {
                chatManager.addMessage(ChatMessage(sender: "You", text: "Uploaded PDF: \(pdfText.prefix(100))..."))
                setMessage("Respond based on the uploaded PDF.")
            } else {
                chatManager.addMessage(ChatMessage(sender: "You", text: "Uploaded file: \(url.lastPathComponent) (unreadable)"))
            }
        } catch {
            chatManager.addMessage(ChatMessage(sender: "You", text: "Error uploading: \(error.localizedDescription)"))
        }
    }
}

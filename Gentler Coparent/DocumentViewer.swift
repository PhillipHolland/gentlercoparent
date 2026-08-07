import SwiftUI
@preconcurrency import PDFKit

// MARK: - Document Viewer with Files App-like Interface
struct DocumentViewer: View {
    let documentURL: URL
    let documentTitle: String
    @State private var searchText = ""
    @State private var currentPage = 0
    @State private var totalPages = 0
    @State private var pdfDocument: PDFDocument?
    @State private var searchResults: [PDFSelection] = []
    @State private var currentSearchIndex = 0
    @State private var isSearching = false
    @State private var loadingError: String?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                searchBar
                
                // PDF Viewer
                if let pdfDocument = pdfDocument {
                    PDFViewRepresentable(
                        document: pdfDocument,
                        searchResults: searchResults,
                        currentSearchIndex: currentSearchIndex,
                        onPageChanged: { page in
                            currentPage = page
                        }
                    )
                } else if let error = loadingError {
                    // Error state
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.red)
                        Text("Failed to load document")
                            .font(.headline)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Button("Retry") {
                            loadingError = nil
                            loadDocument()
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Loading state
                    VStack {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading document...")
                            .foregroundColor(.secondary)
                            .padding(.top)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                // Bottom toolbar with navigation
                bottomToolbar
            }
            .navigationTitle(documentTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: shareDocument) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        Button(action: printDocument) {
                            Label("Print", systemImage: "printer")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .onAppear {
            loadDocument()
        }
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search document...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .onSubmit {
                        performSearch()
                    }
                
                if !searchText.isEmpty {
                    Button(action: clearSearch) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            if isSearching {
                ProgressView()
                    .scaleEffect(0.8)
            } else if !searchResults.isEmpty {
                // Search navigation buttons
                HStack(spacing: 8) {
                    Button(action: previousSearchResult) {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .disabled(currentSearchIndex <= 0)
                    
                    Text("\(currentSearchIndex + 1) of \(searchResults.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(minWidth: 60)
                    
                    Button(action: nextSearchResult) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .disabled(currentSearchIndex >= searchResults.count - 1)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.systemGray5))
                .cornerRadius(6)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.05), radius: 1, y: 1)
    }
    
    // MARK: - Bottom Toolbar
    private var bottomToolbar: some View {
        HStack {
            // Page info
            Text("Page \(currentPage + 1) of \(totalPages)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            // Page navigation
            HStack(spacing: 20) {
                Button(action: previousPage) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                }
                .disabled(currentPage <= 0)
                
                Button(action: nextPage) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 18, weight: .medium))
                }
                .disabled(currentPage >= totalPages - 1)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
    }
    
    // MARK: - Helper Methods
    private func loadDocument() {
        let documentURL = self.documentURL
        
        DispatchQueue.global(qos: .userInitiated).async {
            if let document = PDFDocument(url: documentURL) {
                Task { @MainActor in
                    self.pdfDocument = document
                    self.totalPages = document.pageCount
                    self.currentPage = 0
                }
                return
            }
            
            // Try with security scoped resource if direct loading fails
            guard documentURL.startAccessingSecurityScopedResource() else {
                Task { @MainActor in
                    self.tryDataLoading()
                }
                return
            }
            defer { documentURL.stopAccessingSecurityScopedResource() }
            
            if let document = PDFDocument(url: documentURL) {
                Task { @MainActor in
                    self.pdfDocument = document
                    self.totalPages = document.pageCount
                    self.currentPage = 0
                }
                return
            }
            
            Task { @MainActor in
                self.tryDataLoading()
            }
        }
    }
    
    private func tryDataLoading() {
        let documentURL = self.documentURL
        
        do {
            let data = try Data(contentsOf: documentURL)
            
            if let document = PDFDocument(data: data) {
                Task { @MainActor in
                    self.pdfDocument = document
                    self.totalPages = document.pageCount
                    self.currentPage = 0
                }
            } else {
                Task { @MainActor in
                    self.loadingError = "Invalid PDF format"
                }
            }
        } catch {
            Task { @MainActor in
                self.loadingError = "Cannot access document: \(error.localizedDescription)"
            }
        }
    }
    
    private func performSearch() {
        guard !searchText.isEmpty, let document = pdfDocument else { return }
        
        isSearching = true
        searchResults.removeAll()
        currentSearchIndex = 0
        
        let searchTerm = searchText
        // Run on MainActor: PDFSelection is not Sendable, so results cannot
        // safely hop from a background queue under Swift 6 concurrency.
        let selections = document.findString(searchTerm, withOptions: [.caseInsensitive])
        searchResults = selections
        isSearching = false
        if !selections.isEmpty {
            currentSearchIndex = 0
        }
    }
    
    private func clearSearch() {
        searchText = ""
        searchResults.removeAll()
        currentSearchIndex = 0
    }
    
    private func nextSearchResult() {
        if currentSearchIndex < searchResults.count - 1 {
            currentSearchIndex += 1
        }
    }
    
    private func previousSearchResult() {
        if currentSearchIndex > 0 {
            currentSearchIndex -= 1
        }
    }
    
    private func nextPage() {
        if currentPage < totalPages - 1 {
            currentPage += 1
        }
    }
    
    private func previousPage() {
        if currentPage > 0 {
            currentPage -= 1
        }
    }
    
    private func shareDocument() {
        let activityVC = UIActivityViewController(activityItems: [documentURL], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            
            // For iPad
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = window
                popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            rootVC.present(activityVC, animated: true)
        }
    }
    
    private func printDocument() {
        guard let document = pdfDocument else { return }
        
        let printController = UIPrintInteractionController.shared
        printController.printingItem = document.dataRepresentation()
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let _ = windowScene.windows.first {
            printController.present(animated: true)
        }
    }
}

// MARK: - PDFKit UIViewRepresentable
struct PDFViewRepresentable: UIViewRepresentable {
    let document: PDFDocument
    let searchResults: [PDFSelection]
    let currentSearchIndex: Int
    let onPageChanged: (Int) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onPageChanged: onPageChanged)
    }
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = UIColor.systemBackground
        
        context.coordinator.pdfView = pdfView
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.pageChanged(_:)),
            name: .PDFViewPageChanged,
            object: pdfView
        )
        
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
        context.coordinator.onPageChanged = onPageChanged
        
        // Update search highlighting
        if !searchResults.isEmpty && currentSearchIndex < searchResults.count {
            let selection = searchResults[currentSearchIndex]
            pdfView.setCurrentSelection(selection, animate: true)
            pdfView.scrollSelectionToVisible(nil)
        } else {
            pdfView.clearSelection()
        }
    }
    
    static func dismantleUIView(_ uiView: PDFView, coordinator: Coordinator) {
        NotificationCenter.default.removeObserver(coordinator, name: .PDFViewPageChanged, object: uiView)
    }
    
    @MainActor
    final class Coordinator: NSObject {
        var onPageChanged: (Int) -> Void
        weak var pdfView: PDFView?
        
        init(onPageChanged: @escaping (Int) -> Void) {
            self.onPageChanged = onPageChanged
        }
        
        /// Notification delivery is not MainActor-isolated; hop without capturing PDFKit objects.
        @objc nonisolated func pageChanged(_ notification: Notification) {
            Task { @MainActor [weak self] in
                self?.handlePageChange()
            }
        }
        
        private func handlePageChange() {
            guard let pdfView, let currentPage = pdfView.currentPage else { return }
            let pageIndex = pdfView.document?.index(for: currentPage) ?? 0
            onPageChanged(pageIndex)
        }
    }
}

// MARK: - Preview
#Preview {
    DocumentViewer(
        documentURL: URL(fileURLWithPath: "/path/to/sample.pdf"),
        documentTitle: "Final Decree of Divorce"
    )
}
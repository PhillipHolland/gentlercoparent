import SwiftUI

struct DocumentManagementView: View {
    @ObservedObject var documentStorageManager: DocumentStorageManager
    @Binding var isPresented: Bool
    @State private var showDeleteAlert = false
    @State private var documentToDelete: DocumentStorageManager.StoredDocument?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if documentStorageManager.storedDocuments.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Image(systemName: "doc.text")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Documents Stored")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text("Upload your divorce decree, custody orders, or other legal documents to get personalized guidance based on your specific situation.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Spacer()
                    }
                } else {
                    // Document list
                    List {
                        ForEach(documentStorageManager.storedDocuments, id: \.id) { document in
                            DocumentRowView(document: document) {
                                documentToDelete = document
                                showDeleteAlert = true
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
                
                // Bottom info
                VStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text("All documents are stored securely on your device")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if !documentStorageManager.storedDocuments.isEmpty {
                        Text("\(documentStorageManager.storedDocuments.count) document\(documentStorageManager.storedDocuments.count == 1 ? "" : "s") stored")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGroupedBackground))
            }
            .navigationTitle("Legal Documents")
            .navigationBarItems(
                leading: Button("Done") { isPresented = false },
                trailing: documentStorageManager.storedDocuments.isEmpty ? nil : 
                    Button("Clear All") {
                        showDeleteAlert = true
                        documentToDelete = nil
                    }
                    .foregroundColor(.red)
            )
            .alert(isPresented: $showDeleteAlert) {
                if let document = documentToDelete {
                    return Alert(
                        title: Text("Delete Document"),
                        message: Text("Are you sure you want to delete \"\(document.filename)\"? This action cannot be undone."),
                        primaryButton: .destructive(Text("Delete")) {
                            documentStorageManager.deleteDocument(id: document.id)
                        },
                        secondaryButton: .cancel()
                    )
                } else {
                    return Alert(
                        title: Text("Clear All Documents"),
                        message: Text("Are you sure you want to delete all stored documents? This action cannot be undone."),
                        primaryButton: .destructive(Text("Clear All")) {
                            documentStorageManager.clearAllDocuments()
                        },
                        secondaryButton: .cancel()
                    )
                }
            }
        }
    }
}

struct DocumentRowView: View {
    let document: DocumentStorageManager.StoredDocument
    let onDelete: () -> Void
    @State private var showDetails = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Document type icon
                Image(systemName: iconForDocumentType(document.type))
                    .foregroundColor(colorForDocumentType(document.type))
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(document.filename)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text(document.type.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatFileSize(document.fileSize))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(formatDate(document.uploadDate))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Parsed information if available
            if let parsed = document.parsedData, parsed.confidence > 0.3 {
                VStack(alignment: .leading, spacing: 4) {
                    if !parsed.partyNames.isEmpty {
                        HStack {
                            Text("Parties:")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            Text(parsed.partyNames.joined(separator: ", "))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if !parsed.children.isEmpty {
                        HStack {
                            Text("Children:")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            Text(parsed.children.joined(separator: ", "))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if let custody = parsed.custodyArrangement {
                        HStack {
                            Text("Custody:")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            Text(custody)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
        }
        .contextMenu {
            Button(action: { showDetails = true }) {
                Label("View Details", systemImage: "info.circle")
            }
            
            Button("Delete", role: .destructive) {
                onDelete()
            }
        }
        .sheet(isPresented: $showDetails) {
            DocumentDetailView(document: document)
        }
    }
    
    private func iconForDocumentType(_ type: DocumentStorageManager.StoredDocument.DocumentType) -> String {
        switch type {
        case .divorceDecree:
            return "doc.text.fill"
        }
    }
    
    private func colorForDocumentType(_ type: DocumentStorageManager.StoredDocument.DocumentType) -> Color {
        switch type {
        case .divorceDecree:
            return Color(hex: "388083") // Use app theme color
        }
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct DocumentDetailView: View {
    let document: DocumentStorageManager.StoredDocument
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Document info
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Document Information")
                            .font(.headline)
                        
                        InfoRow(label: "Filename", value: document.filename)
                        InfoRow(label: "Type", value: document.type.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                        InfoRow(label: "Upload Date", value: formatFullDate(document.uploadDate))
                        InfoRow(label: "File Size", value: formatFileSize(document.fileSize))
                    }
                    
                    // Parsed data if available
                    if let parsed = document.parsedData {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Extracted Information")
                                .font(.headline)
                            
                            InfoRow(label: "Parsing Confidence", value: "\(Int(parsed.confidence * 100))%")
                            
                            if !parsed.partyNames.isEmpty {
                                InfoRow(label: "Parties", value: parsed.partyNames.joined(separator: ", "))
                            }
                            
                            if !parsed.children.isEmpty {
                                InfoRow(label: "Children", value: parsed.children.joined(separator: ", "))
                            }
                            
                            if let custody = parsed.custodyArrangement {
                                InfoRow(label: "Custody Type", value: custody)
                            }
                            
                            if let support = parsed.supportAmount {
                                InfoRow(label: "Support Amount", value: support)
                            }
                            
                            if let schedule = parsed.schedule {
                                InfoRow(label: "Schedule", value: schedule)
                            }
                            
                            if !parsed.restrictions.isEmpty {
                                InfoRow(label: "Restrictions", value: parsed.restrictions.joined(separator: ", "))
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Document Details")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label + ":")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .font(.caption)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}
import SwiftUI

// MARK: - Modern composer (iOS 18+ shell, brand colors, custom type)
struct InputBarView: View {
    @Binding var message: String
    @Binding var lineCount: Int
    @Binding var selectedAttachmentURL: URL?
    @Binding var attachmentImage: UIImage?
    
    let isLoading: Bool
    let onSend: () -> Void
    let onAttachmentTap: () -> Void
    
    @FocusState private var isTextFieldFocused: Bool
    
    private var canSend: Bool {
        !isLoading && (!message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedAttachmentURL != nil)
    }
    
    private var fieldHeight: CGFloat {
        CGFloat(lineCount) * 22 + 20
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            Button {
                #if canImport(UIKit)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                #endif
                onAttachmentTap()
            } label: {
                Image(systemName: "paperclip")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(GCPTheme.primary)
                    .frame(width: 40, height: 40)
                    .contentShape(Rectangle())
            }
            .disabled(isLoading)
            .accessibilityLabel("Attach photo or document")
            
            HStack(alignment: .bottom, spacing: 8) {
                attachmentThumbnail
                
                ZStack(alignment: .topLeading) {
                    if message.isEmpty {
                        Text("Message Gentler Coparent…")
                            .font(GCPTheme.body(16))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 10)
                            .allowsHitTesting(false)
                    }
                    
                    TextEditor(text: $message)
                        .font(GCPTheme.body(16))
                        .scrollContentBackground(.hidden)
                        .disabled(isLoading)
                        .focused($isTextFieldFocused)
                        .frame(minHeight: 36, maxHeight: fieldHeight)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityLabel("Message input")
                        .accessibilityHint(isLoading ? "Wait for the response to finish" : "Type your co-parenting question")
                        .onChange(of: isLoading) { _, loading in
                            if loading {
                                isTextFieldFocused = false
                                #if canImport(UIKit)
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                #endif
                            }
                        }
                        .onChange(of: message) { _, newValue in
                            let lineBreaks = newValue.components(separatedBy: .newlines).count
                            let estimatedWrapped = max(1, (newValue.count / 36) + 1)
                            lineCount = max(1, min(5, max(lineBreaks, estimatedWrapped)))
                        }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Button {
                    #if canImport(UIKit)
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.prepare()
                    impact.impactOccurred()
                    #endif
                    isTextFieldFocused = false
                    onSend()
                    message = ""
                    lineCount = 1
                } label: {
                    Image(systemName: isLoading ? "stop.circle.fill" : "arrow.up.circle.fill")
                        .font(.system(size: 32, weight: .semibold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(canSend || isLoading ? GCPTheme.primary : GCPTheme.primary.opacity(0.35))
                        .contentTransition(.symbolEffect(.replace))
                }
                .buttonStyle(.plain)
                .disabled(!canSend && !isLoading)
                .accessibilityLabel(isLoading ? "Stop generating" : "Send message")
            }
            .padding(.leading, 12)
            .padding(.trailing, 6)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: GCPTheme.radiusField, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.06), radius: 10, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: GCPTheme.radiusField, style: .continuous)
                    .strokeBorder(GCPTheme.primary.opacity(0.14), lineWidth: 1)
            )
        }
        .padding(.horizontal, GCPTheme.spaceL)
        .padding(.vertical, GCPTheme.spaceS)
        .background(
            GCPTheme.sky
                .ignoresSafeArea(edges: .bottom)
        )
    }
    
    @ViewBuilder
    private var attachmentThumbnail: some View {
        if let image = attachmentImage {
            ZStack(alignment: .topTrailing) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                
                Button {
                    attachmentImage = nil
                    selectedAttachmentURL = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, Color.black.opacity(0.55))
                        .font(.system(size: 16))
                }
                .offset(x: 6, y: -6)
            }
            .padding(.vertical, 4)
        } else if selectedAttachmentURL != nil {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: "doc.fill")
                            .foregroundStyle(GCPTheme.primary)
                    }
                
                Button {
                    selectedAttachmentURL = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, Color.black.opacity(0.55))
                        .font(.system(size: 16))
                }
                .offset(x: 6, y: -6)
            }
            .padding(.vertical, 4)
        }
    }
}

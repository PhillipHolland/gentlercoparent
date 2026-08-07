import SwiftUI
import UIKit

// MARK: - Fixed Text View Component
struct FixedTextView: UIViewRepresentable {
    @Binding var text: String
    @Binding var lineCount: Int
    let isDisabled: Bool
    let font: UIFont
    let placeholder: String
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.font = font
        textView.textColor = .black
        textView.backgroundColor = .white
        textView.layer.cornerRadius = 8
        textView.textContainerInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        textView.delegate = context.coordinator
        
        // Ensure proper text wrapping and width constraints
        textView.textContainer.widthTracksTextView = true
        textView.textContainer.lineBreakMode = .byWordWrapping
        textView.isScrollEnabled = true
        
        let placeholderLabel = UILabel()
        placeholderLabel.text = placeholder
        placeholderLabel.font = font
        placeholderLabel.textColor = UIColor.gray.withAlphaComponent(0.5)
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        textView.addSubview(placeholderLabel)
        
        NSLayoutConstraint.activate([
            placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 5 + textView.textContainerInset.left),
            placeholderLabel.topAnchor.constraint(equalTo: textView.topAnchor, constant: textView.textContainerInset.top),
            placeholderLabel.trailingAnchor.constraint(equalTo: textView.trailingAnchor, constant: -5 - textView.textContainerInset.right)
        ])
        
        context.coordinator.placeholderLabel = placeholderLabel
        context.coordinator.textView = textView
        placeholderLabel.isHidden = !text.isEmpty
        
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        // Set a flag to indicate this is a programmatic change
        context.coordinator.isProgrammaticChange = true
        if uiView.text != text {
            let selectedRange = uiView.selectedTextRange
            uiView.text = text
            if let range = selectedRange {
                uiView.selectedTextRange = range
            }
        }
        uiView.isEditable = !isDisabled
        context.coordinator.placeholderLabel?.isHidden = !text.isEmpty
        
        // Enable scrolling when content exceeds max height
        let maxHeight: CGFloat = 100
        let contentHeight = uiView.contentSize.height
        uiView.isScrollEnabled = contentHeight > maxHeight
        
        // Ensure text container tracks the view width properly
        uiView.textContainer.widthTracksTextView = true
        
        if let selectedRange = uiView.selectedTextRange {
            let caretRect = uiView.caretRect(for: selectedRange.end)
            uiView.scrollRectToVisible(caretRect, animated: true)
        }
        // Reset the flag after the update
        context.coordinator.isProgrammaticChange = false
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self, font: font)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: FixedTextView
        var placeholderLabel: UILabel?
        weak var textView: UITextView?
        let font: UIFont
        var isUpdatingText = false
        var isProgrammaticChange = false // New flag to track programmatic changes
        
        init(_ parent: FixedTextView, font: UIFont) {
            self.parent = parent
            self.font = font
        }
        
        func textViewDidChange(_ textView: UITextView) {
            // Guard against programmatic changes to prevent feedback loop
            guard !isProgrammaticChange else { return }
            guard !isUpdatingText else { return }
            
            let currentText = textView.text ?? ""
            placeholderLabel?.isHidden = !currentText.isEmpty
            
            // Update lineCount based on text content
            if currentText.isEmpty {
                parent.lineCount = 1
            } else {
                guard textView.frame.width > 0 else { return }
                let size = textView.sizeThatFits(CGSize(width: textView.frame.width, height: .greatestFiniteMagnitude))
                let contentHeight = size.height - textView.textContainerInset.top - textView.textContainerInset.bottom
                let lineHeight = font.lineHeight
                
                // Guard against NaN and invalid values
                guard contentHeight.isFinite && contentHeight > 0,
                      lineHeight.isFinite && lineHeight > 0 else {
                    parent.lineCount = 1
                    return
                }
                
                let calculatedLineCount = max(1, Int(round(contentHeight / lineHeight)))
                parent.lineCount = min(calculatedLineCount, 3)
            }
            
            applyAutoNewline(textView: textView, currentText: currentText)
            parent.text = textView.text
        }
        
        private func applyAutoNewline(textView: UITextView, currentText: String) {
            // Disable auto-newline to prevent the alternating line break issue
            // The system UITextView handles text wrapping naturally
            return
        }
    }
}
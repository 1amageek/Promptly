import SwiftUI

/// A custom text editor that supports @mentions highlighting and custom submission handling
/// for both macOS and iOS platforms.
///
/// This view provides a platform-specific implementation of a text editor with the following features:
/// - Real-time @mentions highlighting
/// - Custom text submission handling
/// - Adjustable font size
/// - Rich text support
/// - Undo functionality
///
/// Example:
/// ```swift
/// @State private var text = ""
///
/// CustomTextEditor(text: $text) {
///     // Handle text submission
///     print("Text submitted: \(text)")
///     return true
/// }
/// .fontSize(16)
/// ```
#if os(macOS)
struct CustomTextEditor: NSViewRepresentable {
    /// The text content of the editor
    @Binding var text: String
    
    /// A closure that handles text submission
    /// - Returns: A boolean indicating whether the submission was handled
    var onSubmit: () -> Bool
    
    /// The font size used in the editor
    var fontSize: CGFloat = 14
    
    /// A coordinator class that manages the text view's delegate methods and text highlighting
    class Coordinator: NSObject, NSTextViewDelegate {
        /// The binding to the text content
        var text: Binding<String>
        
        /// The submission handler closure
        var onSubmit: () -> Bool
        
        /// The current font size
        var fontSize: CGFloat
        
        /// Creates a coordinator with the specified text binding, submission handler, and font size
        /// - Parameters:
        ///   - text: A binding to the text content
        ///   - onSubmit: A closure that handles text submission
        ///   - fontSize: The font size to be used
        init(text: Binding<String>, onSubmit: @escaping () -> Bool, fontSize: CGFloat) {
            self.text = text
            self.onSubmit = onSubmit
            self.fontSize = fontSize
        }
        
        /// Handles text changes in the text view
        /// - Parameter notification: The notification containing the text view
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            text.wrappedValue = textView.string
            highlightMentions(in: textView)
        }
        
        /// Handles special key commands in the text view
        /// - Parameters:
        ///   - textView: The text view
        ///   - commandSelector: The selector for the command
        /// - Returns: A boolean indicating whether the command was handled
        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSStandardKeyBindingResponding.insertNewline(_:)) {
                return onSubmit()
            }
            return false
        }
        
        /// Applies highlight styling to @mentions in the text
        /// - Parameter textView: The text view to highlight
        @MainActor
        private func highlightMentions(in textView: NSTextView) {
            let attributedString = NSMutableAttributedString(string: textView.string)
            let defaultAttributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: fontSize),
                .foregroundColor: NSColor.textColor
            ]
            attributedString.setAttributes(defaultAttributes, range: NSRange(location: 0, length: attributedString.length))
            
            let pattern = "@\\w+"
            guard let regex = try? NSRegularExpression(pattern: pattern) else { return }
            
            let matches = regex.matches(
                in: textView.string,
                range: NSRange(location: 0, length: textView.string.count)
            )
            
            for match in matches {
                attributedString.addAttribute(
                    .foregroundColor,
                    value: NSColor.controlAccentColor,
                    range: match.range
                )
            }
            
            let selectedRanges = textView.selectedRanges
            textView.textStorage?.setAttributedString(attributedString)
            textView.selectedRanges = selectedRanges
        }
    }
    
    /// Creates the coordinator for managing the text view
    /// - Returns: A new coordinator instance
    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, onSubmit: onSubmit, fontSize: fontSize)
    }
    
    /// Creates the NSScrollView containing the text view
    /// - Parameter context: The context for the view
    /// - Returns: A configured NSScrollView
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        guard let textView = scrollView.documentView as? NSTextView else { return scrollView }
        
        context.coordinator.textDidChange(Notification(name: Notification.Name(""), object: textView))
        textView.font = .systemFont(ofSize: fontSize)
        textView.delegate = context.coordinator
        textView.string = text
        textView.isRichText = true
        textView.isEditable = true
        textView.allowsUndo = true
        textView.textContainer?.lineFragmentPadding = 5.0
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.minSize = NSSize(width: 0, height: 17)
        textView.backgroundColor = .clear
        scrollView.backgroundColor = .clear
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.scrollerStyle = .overlay
        scrollView.autohidesScrollers = true
        scrollView.wantsLayer = true
        return scrollView
    }
    
    /// Updates the NSScrollView when the view's state changes
    /// - Parameters:
    ///   - scrollView: The scroll view to update
    ///   - context: The context for the view
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        
        if textView.string != text {
            textView.string = text
            context.coordinator.textDidChange(Notification(name: Notification.Name(""), object: textView))
        }
        
        if context.coordinator.fontSize != fontSize {
            context.coordinator.fontSize = fontSize
            textView.font = .systemFont(ofSize: fontSize)
            context.coordinator.textDidChange(Notification(name: Notification.Name(""), object: textView))
        }
    }
    
    /// Calculates the size that fits the proposed size
    /// - Parameters:
    ///   - proposal: The proposed size
    ///   - nsView: The NSScrollView
    ///   - context: The context for the view
    /// - Returns: The calculated size that fits
    func sizeThatFits(_ proposal: ProposedViewSize, nsView: NSScrollView, context: Context) -> CGSize? {
        guard let textView = nsView.documentView as? NSTextView else {
            return proposal.replacingUnspecifiedDimensions()
        }
        guard
            let layoutManager = textView.layoutManager,
            let container = textView.textContainer else {
            return proposal.replacingUnspecifiedDimensions()
        }
        let size = layoutManager.usedRect(for: container).size
        return proposal
            .replacingUnspecifiedDimensions(by: size)
    }
}

#else
struct CustomTextEditor: UIViewRepresentable {
    /// The text content of the editor
    @Binding var text: String
    
    /// A closure that handles text submission
    /// - Returns: A boolean indicating whether the submission was handled
    var onSubmit: () -> Bool
    
    /// The font size used in the editor
    var fontSize: CGFloat = 14
    
    /// A coordinator class that manages the text view's delegate methods and text highlighting
    class Coordinator: NSObject, UITextViewDelegate {
        /// The binding to the text content
        var text: Binding<String>
        
        /// The submission handler closure
        var onSubmit: () -> Bool
        
        /// The current font size
        var fontSize: CGFloat
        
        /// Creates a coordinator with the specified text binding, submission handler, and font size
        /// - Parameters:
        ///   - text: A binding to the text content
        ///   - onSubmit: A closure that handles text submission
        ///   - fontSize: The font size to be used
        init(text: Binding<String>, onSubmit: @escaping () -> Bool, fontSize: CGFloat) {
            self.text = text
            self.onSubmit = onSubmit
            self.fontSize = fontSize
        }
        
        /// Handles text changes in the text view
        /// - Parameter textView: The text view that changed
        @MainActor
        func textViewDidChange(_ textView: UITextView) {
            text.wrappedValue = textView.text
            highlightMentions(in: textView)
        }
        
        /// Handles text changes and special characters in the text view
        /// - Parameters:
        ///   - textView: The text view
        ///   - range: The range of text to change
        ///   - text: The replacement text
        /// - Returns: A boolean indicating whether the change should be allowed
        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            if text == "\n" {
                return !onSubmit()
            }
            return true
        }
        
        /// Applies highlight styling to @mentions in the text
        /// - Parameter textView: The text view to highlight
        @MainActor
        private func highlightMentions(in textView: UITextView) {
            let attributedString = NSMutableAttributedString(string: textView.text)
            let defaultAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: fontSize),
                .foregroundColor: UIColor.label
            ]
            attributedString.setAttributes(defaultAttributes, range: NSRange(location: 0, length: attributedString.length))
            
            let pattern = "@\\w+"
            guard let regex = try? NSRegularExpression(pattern: pattern) else { return }
            
            let matches = regex.matches(
                in: textView.text,
                range: NSRange(location: 0, length: textView.text.count)
            )
            
            for match in matches {
                attributedString.addAttribute(
                    .foregroundColor,
                    value: UIColor.tintColor,
                    range: match.range
                )
            }
            
            let selectedRange = textView.selectedRange
            textView.attributedText = attributedString
            textView.selectedRange = selectedRange
        }
    }
    
    /// Creates the coordinator for managing the text view
    /// - Returns: A new coordinator instance
    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, onSubmit: onSubmit, fontSize: fontSize)
    }
    
    /// Creates the UITextView
    /// - Parameter context: The context for the view
    /// - Returns: A configured UITextView
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.text = text
        textView.font = .systemFont(ofSize: fontSize)
        textView.isEditable = true
        textView.backgroundColor = .clear
        textView.textContainer.lineFragmentPadding = 5.0
        textView.textContainerInset = .zero
        textView.isScrollEnabled = true
        textView.allowsEditingTextAttributes = true
        textView.undoManager?.levelsOfUndo = 10
        
        context.coordinator.textViewDidChange(textView)
        return textView
    }
    
    /// Updates the UITextView when the view's state changes
    /// - Parameters:
    ///   - textView: The text view to update
    ///   - context: The context for the view
    func updateUIView(_ textView: UITextView, context: Context) {
        if textView.text != text {
            textView.text = text
            context.coordinator.textViewDidChange(textView)
        }
        
        if context.coordinator.fontSize != fontSize {
            context.coordinator.fontSize = fontSize
            textView.font = .systemFont(ofSize: fontSize)
            context.coordinator.textViewDidChange(textView)
        }
    }
    
    /// Calculates the size that fits the proposed size
    /// - Parameters:
    ///   - proposal: The proposed size
    ///   - uiView: The UITextView
    ///   - context: The context for the view
    /// - Returns: The calculated size that fits
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        guard let superview = uiView.superview else {
            return proposal.replacingUnspecifiedDimensions()
        }
        let sizeThatFits = uiView.sizeThatFits(CGSize(width: superview.bounds.width, height: .greatestFiniteMagnitude))
        return proposal
            .replacingUnspecifiedDimensions(by: sizeThatFits)
    }
}
#endif

extension CustomTextEditor {
    /// Sets the font size for the text editor
    /// - Parameter size: The desired font size
    /// - Returns: A modified instance of CustomTextEditor with the new font size
    func fontSize(_ size: CGFloat) -> CustomTextEditor {
        var view = self
        view.fontSize = size
        return view
    }
}

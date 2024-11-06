//import SwiftUI
//
//#if os(macOS)
//struct CustomTextEditor: NSViewRepresentable {
//    @Binding var text: String
//    var onSubmit: () -> Bool
//    
//    class Coordinator: NSObject, NSTextViewDelegate {
//        var text: Binding<String>
//        var onSubmit: () -> Bool
//        
//        init(text: Binding<String>, onSubmit: @escaping () -> Bool) {
//            self.text = text
//            self.onSubmit = onSubmit
//        }
//        
//        func textDidChange(_ notification: Notification) {
//            guard let textView = notification.object as? NSTextView else { return }
//            text.wrappedValue = textView.string
//            highlightMentions(in: textView)
//        }
//        
//        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
//            if commandSelector == #selector(NSStandardKeyBindingResponding.insertNewline(_:)) {
//                return onSubmit()
//            }
//            return false
//        }
//        
//        @MainActor
//        private func highlightMentions(in textView: NSTextView) {
//            let attributedString = NSMutableAttributedString(string: textView.string)
//            // デフォルトの属性を設定
//            let defaultAttributes: [NSAttributedString.Key: Any] = [
//                .font: NSFont.systemFont(ofSize: NSFont.systemFontSize),
//                .foregroundColor: NSColor.textColor
//            ]
//            attributedString.setAttributes(defaultAttributes, range: NSRange(location: 0, length: attributedString.length))
//            
//            // メンションのパターンを検索して色を付ける
//            let pattern = "@\\w+"
//            guard let regex = try? NSRegularExpression(pattern: pattern) else { return }
//            
//            let matches = regex.matches(
//                in: textView.string,
//                range: NSRange(location: 0, length: textView.string.count)
//            )
//            
//            for match in matches {
//                attributedString.addAttribute(
//                    .foregroundColor,
//                    value: NSColor.controlAccentColor,
//                    range: match.range
//                )
//            }
//            
//            // 選択範囲を保持
//            let selectedRanges = textView.selectedRanges
//            
//            // 属性付きテキストを設定
//            textView.textStorage?.setAttributedString(attributedString)
//            
//            // 選択範囲を復元
//            textView.selectedRanges = selectedRanges
//        }
//    }
//    
//    func makeCoordinator() -> Coordinator {
//        Coordinator(text: $text, onSubmit: onSubmit)
//    }
//    
//    func makeNSView(context: Context) -> NSScrollView {
//        let scrollView = NSTextView.scrollableTextView()
//        guard let textView = scrollView.documentView as? NSTextView else { return scrollView }
//        
//        textView.delegate = context.coordinator
//        textView.string = text
//        textView.isRichText = true // リッチテキストを有効化
//        textView.isEditable = true
//        textView.allowsUndo = true
//        textView.font = .systemFont(ofSize: NSFont.systemFontSize)
//        
//        // 初期テキストのハイライトを適用
//        context.coordinator.textDidChange(Notification(name: Notification.Name(""), object: textView))
//        
//        return scrollView
//    }
//    
//    func updateNSView(_ scrollView: NSScrollView, context: Context) {
//        guard let textView = scrollView.documentView as? NSTextView else { return }
//        if textView.string != text {
//            textView.string = text
//            context.coordinator.textDidChange(Notification(name: Notification.Name(""), object: textView))
//        }
//    }
//}
//#else
//struct CustomTextEditor: UIViewRepresentable {
//    @Binding var text: String
//    var onSubmit: () -> Bool
//    
//    class Coordinator: NSObject, UITextViewDelegate {
//        var text: Binding<String>
//        var onSubmit: () -> Bool
//        
//        init(text: Binding<String>, onSubmit: @escaping () -> Bool) {
//            self.text = text
//            self.onSubmit = onSubmit
//        }
//        
//        func textViewDidChange(_ textView: UITextView) {
//            text.wrappedValue = textView.text
//            highlightMentions(in: textView)
//        }
//        
//        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
//            if text == "\n" {
//                return !onSubmit()
//            }
//            return true
//        }
//        
//        private func highlightMentions(in textView: UITextView) {
//            let attributedString = NSMutableAttributedString(string: textView.text)
//            // デフォルトの属性を設定
//            let defaultAttributes: [NSAttributedString.Key: Any] = [
//                .font: UIFont.systemFont(ofSize: UIFont.systemFontSize),
//                .foregroundColor: UIColor.label
//            ]
//            attributedString.setAttributes(defaultAttributes, range: NSRange(location: 0, length: attributedString.length))
//            
//            // メンションのパターンを検索して色を付ける
//            let pattern = "@\\w+"
//            guard let regex = try? NSRegularExpression(pattern: pattern) else { return }
//            
//            let matches = regex.matches(
//                in: textView.text,
//                range: NSRange(location: 0, length: textView.text.count)
//            )
//            
//            for match in matches {
//                attributedString.addAttribute(
//                    .foregroundColor,
//                    value: UIColor.tintColor,
//                    range: match.range
//                )
//            }
//            
//            // 選択範囲を保持
//            let selectedRange = textView.selectedRange
//            
//            // 属性付きテキストを設定
//            textView.attributedText = attributedString
//            
//            // 選択範囲を復元
//            textView.selectedRange = selectedRange
//        }
//    }
//    
//    func makeCoordinator() -> Coordinator {
//        Coordinator(text: $text, onSubmit: onSubmit)
//    }
//    
//    func makeUIView(context: Context) -> UITextView {
//        let textView = UITextView()
//        textView.delegate = context.coordinator
//        textView.text = text
//        textView.font = .systemFont(ofSize: UIFont.systemFontSize)
//        textView.isEditable = true
//        textView.backgroundColor = .clear
//        
//        // 初期テキストのハイライトを適用
//        context.coordinator.textViewDidChange(textView)
//        
//        return textView
//    }
//    
//    func updateUIView(_ textView: UITextView, context: Context) {
//        if textView.text != text {
//            textView.text = text
//            context.coordinator.textViewDidChange(textView)
//        }
//    }
//}
//#endif

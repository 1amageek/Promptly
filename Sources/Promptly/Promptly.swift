import SwiftUI

#if os(macOS)
struct CustomTextEditor: NSViewRepresentable {
    @Binding var text: String
    var onSubmit: () -> Bool
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var text: Binding<String>
        var onSubmit: () -> Bool
        
        init(text: Binding<String>, onSubmit: @escaping () -> Bool) {
            self.text = text
            self.onSubmit = onSubmit
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            text.wrappedValue = textView.string
            highlightMentions(in: textView)
        }
        
        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSStandardKeyBindingResponding.insertNewline(_:)) {
                return onSubmit()
            }
            return false
        }
        
        @MainActor
        private func highlightMentions(in textView: NSTextView) {
            let attributedString = NSMutableAttributedString(string: textView.string)
            // デフォルトの属性を設定
            let defaultAttributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: NSFont.systemFontSize),
                .foregroundColor: NSColor.textColor
            ]
            attributedString.setAttributes(defaultAttributes, range: NSRange(location: 0, length: attributedString.length))
            
            // メンションのパターンを検索して色を付ける
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
            
            // 選択範囲を保持
            let selectedRanges = textView.selectedRanges
            
            // 属性付きテキストを設定
            textView.textStorage?.setAttributedString(attributedString)
            
            // 選択範囲を復元
            textView.selectedRanges = selectedRanges
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, onSubmit: onSubmit)
    }
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        guard let textView = scrollView.documentView as? NSTextView else { return scrollView }
        
        textView.delegate = context.coordinator
        textView.string = text
        textView.isRichText = true // リッチテキストを有効化
        textView.isEditable = true
        textView.allowsUndo = true
        textView.font = .systemFont(ofSize: NSFont.systemFontSize)
        
        // 初期テキストのハイライトを適用
        context.coordinator.textDidChange(Notification(name: Notification.Name(""), object: textView))
        
        return scrollView
    }
    
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        if textView.string != text {
            textView.string = text
            context.coordinator.textDidChange(Notification(name: Notification.Name(""), object: textView))
        }
    }
}
#else
struct CustomTextEditor: UIViewRepresentable {
    @Binding var text: String
    var onSubmit: () -> Bool
    
    class Coordinator: NSObject, UITextViewDelegate {
        var text: Binding<String>
        var onSubmit: () -> Bool
        
        init(text: Binding<String>, onSubmit: @escaping () -> Bool) {
            self.text = text
            self.onSubmit = onSubmit
        }
        
        func textViewDidChange(_ textView: UITextView) {
            text.wrappedValue = textView.text
            highlightMentions(in: textView)
        }
        
        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            if text == "\n" {
                return !onSubmit()
            }
            return true
        }
        
        private func highlightMentions(in textView: UITextView) {
            let attributedString = NSMutableAttributedString(string: textView.text)
            // デフォルトの属性を設定
            let defaultAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: UIFont.systemFontSize),
                .foregroundColor: UIColor.label
            ]
            attributedString.setAttributes(defaultAttributes, range: NSRange(location: 0, length: attributedString.length))
            
            // メンションのパターンを検索して色を付ける
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
            
            // 選択範囲を保持
            let selectedRange = textView.selectedRange
            
            // 属性付きテキストを設定
            textView.attributedText = attributedString
            
            // 選択範囲を復元
            textView.selectedRange = selectedRange
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, onSubmit: onSubmit)
    }
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.text = text
        textView.font = .systemFont(ofSize: UIFont.systemFontSize)
        textView.isEditable = true
        textView.backgroundColor = .clear
        
        // 初期テキストのハイライトを適用
        context.coordinator.textViewDidChange(textView)
        
        return textView
    }
    
    func updateUIView(_ textView: UITextView, context: Context) {
        if textView.text != text {
            textView.text = text
            context.coordinator.textViewDidChange(textView)
        }
    }
}
#endif

public struct Promptly<T: Sendable & Identifiable, Content: View>: View {
    @Binding var text: String
    @State private var suggestions: [T] = []
    @State private var showSuggestions: Bool = false
    @State private var currentWordRange: Range<String.Index>?
    @State private var hoveredSuggestion: T.ID?
    @State private var lastCompletedMentionEnd: String.Index?
    @State private var selectedIndex: Int = 0
    
    var source: (String) -> [T]
    var displayString: (T) -> String
    var content: (T) -> Content
    
    public init<V: CustomStringConvertible>(
        text: Binding<String>,
        source: @escaping (String) -> [T],
        display keyPath: KeyPath<T, V>,
        @ViewBuilder content: @escaping (T) -> Content
    ) {
        self._text = text
        self.source = source
        self.displayString = { item in String(describing: item[keyPath: keyPath]) }
        self.content = content
    }
    
    public init(
        text: Binding<String>,
        source: @escaping (String) -> [T],
        display: @escaping (T) -> String,
        @ViewBuilder content: @escaping (T) -> Content
    ) {
        self._text = text
        self.source = source
        self.displayString = display
        self.content = content
    }
    
    private func findMentionRange() -> (searchText: String, range: Range<String.Index>)? {
        guard let atIndex = text.lastIndex(of: "@") else { return nil }
        
        if let lastEnd = lastCompletedMentionEnd, atIndex <= lastEnd {
            return nil
        }
        
        let searchStartIndex = text.index(after: atIndex)
        guard searchStartIndex <= text.endIndex else {
            return ("", atIndex..<text.endIndex)
        }
        
        let remainingText = text[searchStartIndex...]
        
        if remainingText.contains(" ") || remainingText.contains("　") {
            return nil
        }
        
        let searchText = String(remainingText)
        return (searchText, atIndex..<text.endIndex)
    }
    
    private func updateSuggestions() {
        if text.contains("@") {
            if let (searchText, range) = findMentionRange() {
                suggestions = source(searchText)
                currentWordRange = range
                showSuggestions = true
                selectedIndex = 0
                return
            }
        }
        showSuggestions = false
    }
    
    private func selectSuggestion(_ item: T) {
        guard let range = currentWordRange else { return }
        
        let replacement = "@" + displayString(item)
        text.replaceSubrange(range, with: replacement + " ")
        lastCompletedMentionEnd = nil
        showSuggestions = false
    }
    
    public var body: some View {
        ZStack(alignment: .topLeading) {
            CustomTextEditor(text: $text) {
                if showSuggestions && !suggestions.isEmpty {
                    selectSuggestion(suggestions[selectedIndex])
                    return true
                }
                return false
            }
            
            if showSuggestions && !suggestions.isEmpty {
                suggestionsList
                    .offset(y: 30)
            }
        }
        .onChange(of: text) { oldValue, newValue in
            if newValue.count < oldValue.count {
                lastCompletedMentionEnd = nil
            }
            updateSuggestions()
        }
#if os(macOS)
        .onExitCommand {
            showSuggestions = false
        }
        .onKeyPress(.upArrow) {
            if showSuggestions && !suggestions.isEmpty {
                selectedIndex = (selectedIndex - 1 + suggestions.count) % suggestions.count
                return .handled
            }
            return .ignored
        }
        .onKeyPress(.downArrow) {
            if showSuggestions && !suggestions.isEmpty {
                selectedIndex = (selectedIndex + 1) % suggestions.count
                return .handled
            }
            return .ignored
        }
        .onKeyPress { event in
            if event.key == KeyEquivalent("n") && event.modifiers.contains(.control) {
                if showSuggestions && !suggestions.isEmpty {
                    selectedIndex = (selectedIndex + 1) % suggestions.count
                    return .handled
                }
            }
            if event.key == KeyEquivalent("p") && event.modifiers.contains(.control) {
                if showSuggestions && !suggestions.isEmpty {
                    selectedIndex = (selectedIndex - 1 + suggestions.count) % suggestions.count
                    return .handled
                }
            }
            return .ignored
        }
#endif
    }
    
    func selectedColor(index: Int, id: T.ID?) -> Bool {
#if os(macOS)
        return selectedIndex == index || hoveredSuggestion == id
#else
        return selectedIndex == index
#endif
    }
    
    private var suggestionsList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 4) {
                ForEach(Array(suggestions.enumerated()), id: \.element.id) { index, suggestion in
                    Button(action: { selectSuggestion(suggestion) }) {
                        content(suggestion)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        selectedColor(index: index, id: suggestion.id)
                                        ? Color.white.opacity(0.1)
                                        : Color.clear
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .padding(.horizontal, 4)
#if os(macOS)
                    .onHover { isHovered in
                        hoveredSuggestion = isHovered ? suggestion.id : nil
                        if isHovered {
                            selectedIndex = index
                        }
                    }
#endif
                }
            }
        }
        .frame(maxWidth: 200, maxHeight: 200)
        .background(.regularMaterial)
        .cornerRadius(8)
        .shadow(radius: 4)
    }
}

struct User: Identifiable, Sendable {
    var id: String
    var name: String
}

#Preview {
    @Previewable @State var text: String = ""
    
    let users: [User] = [
        .init(id: "0", name: "johny"),
        .init(id: "1", name: "jobs"),
        .init(id: "2", name: "steave"),
        .init(id: "3", name: "wozniak")
    ]
    
    Promptly(
        text: $text,
        source: { searchText in
            users.filter { user in
                searchText.isEmpty ||
                user.name.localizedCaseInsensitiveContains(searchText)
            }
        },
        display: { user in "\(user.name)" }
    ) { user in
        Text(user.name)
    }
    .frame(width: 300, height: 170)
}

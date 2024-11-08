import SwiftUI

/// A view that provides mention suggestions while typing.
/// Use this view when you want to implement a mention system in your text input.
///
/// ```swift
/// struct ContentView: View {
///     @State private var text = ""
///     let users: [User] = [
///         .init(id: "1", name: "john"),
///         .init(id: "2", name: "steve")
///     ]
///
///     var body: some View {
///         Promptly(
///             text: $text,
///             edge: .bottom,
///             source: { searchText in
///                 let filtered = users.filter { user in
///                     searchText.isEmpty ||
///                     user.name.localizedCaseInsensitiveContains(searchText)
///                 }
///                 return filtered
///             },
///             display: { user in user.name }
///         ) { user in
///             Text(user.name)
///         }
///     }
/// }
/// ```
public struct Promptly<T: Sendable & Identifiable, Content: View>: View {
    @Binding var text: String
    @State private var suggestions: [T] = []
    @State private var showSuggestions: Bool = false
    @State private var currentWordRange: Range<String.Index>?
    @State private var hoveredSuggestion: T.ID?
    @State private var lastCompletedMentionEnd: String.Index?
    @State private var selectedIndex: Int = 0
    @State private var isLoading: Bool = false
    @State private var searchTask: Task<Void, Never>?
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    var source: (String) async throws -> [T]
    var displayString: (T) -> String
    var content: (T) -> Content
    var edge: Edge
    
    /// Creates a mention suggestion view with a key path for display text.
    /// - Parameters:
    ///   - text: The binding to the text being edited
    ///   - edge: The edge where suggestions appear (.top or .bottom)
    ///   - source: An async closure that returns filtered suggestions based on search text
    ///   - keyPath: A key path to the property used for display text
    ///   - content: A closure that creates the view for each suggestion
    public init<V: CustomStringConvertible>(
        text: Binding<String>,
        edge: Edge = .top,
        source: @escaping (String) async throws -> [T],
        display keyPath: KeyPath<T, V>,
        @ViewBuilder content: @escaping (T) -> Content
    ) {
        self._text = text
        self.edge = edge
        self.source = source
        self.displayString = { item in String(describing: item[keyPath: keyPath]) }
        self.content = content
    }
    
    /// Creates a mention suggestion view with a custom display string closure.
    /// - Parameters:
    ///   - text: The binding to the text being edited
    ///   - edge: The edge where suggestions appear (.top or .bottom)
    ///   - source: An async closure that returns filtered suggestions based on search text
    ///   - display: A closure that returns the display string for an item
    ///   - content: A closure that creates the view for each suggestion
    public init(
        text: Binding<String>,
        edge: Edge = .top,
        source: @escaping (String) async throws -> [T],
        display: @escaping (T) -> String,
        @ViewBuilder content: @escaping (T) -> Content
    ) {
        self._text = text
        self.edge = edge
        self.source = source
        self.displayString = display
        self.content = content
    }
    
    /// Finds the range of the current mention being typed.
    /// - Returns: A tuple containing the search text and its range in the text.
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
    
    /// Updates the suggestions list based on the current text input.
    private func updateSuggestions() {
        // Cancel the previous task if it exists
        searchTask?.cancel()
        
        if text.contains("@") {
            if let (searchText, range) = findMentionRange() {
                isLoading = true
                currentWordRange = range
                selectedIndex = 0
                
                searchTask = Task {
                    defer { isLoading = false }
                    
                    do {
                        let results = try await source(searchText)
                        guard !Task.isCancelled else { return }
                        suggestions = results
                        showSuggestions = true
                    } catch {
                        suggestions = []
                        print("Error fetching suggestions: \(error)")
                    }
                }
                return
            }
        }
        showSuggestions = false
        suggestions = []
    }
    
    /// Selects a suggestion and replaces the current mention text.
    /// - Parameter item: The selected suggestion item
    private func selectSuggestion(_ item: T) {
        guard let range = currentWordRange else { return }
        
        let replacement = "@" + displayString(item)
        text.replaceSubrange(range, with: replacement + " ")
        lastCompletedMentionEnd = nil
        showSuggestions = false
    }
    
    /// Calculates the vertical offset for the suggestions list.
    /// - Returns: The offset value based on the specified edge.
    private func suggestionOffset() -> CGFloat {
        switch edge {
        case .top:
            return -40 // Height of suggestions list + padding
        case .bottom:
            return 40
        default:
            return 40
        }
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
            .scrollContentBackground(.hidden)
            .overlay(alignment: self.edge == .bottom ? .top : .bottom) {
                if showSuggestions {
                    suggestionsList
                        .offset(y: suggestionOffset())
                        .zIndex(1)
                }
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
    
    /// Determines if a suggestion item should be highlighted.
    /// - Parameters:
    ///   - index: The index of the suggestion item
    ///   - id: The ID of the suggestion item
    /// - Returns: A Boolean indicating whether the item should be highlighted
    func selectedColor(index: Int, id: T.ID?) -> Bool {
#if os(macOS)
        return selectedIndex == index || hoveredSuggestion == id
#else
        return selectedIndex == index
#endif
    }
    
    var hoverColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.1)
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
                                        ? hoverColor
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
        .safeAreaPadding(.vertical, 4)
        .frame(minHeight: 148)
        .background(.thickMaterial)
        .background(.windowBackground.opacity(0.2))
        .clipShape(.rect(cornerRadius: 8))
    }
}



/// A model representing a user for mention suggestions.
struct User: Identifiable, Sendable {
    /// The unique identifier for the user.
    var id: String
    /// The display name of the user.
    var name: String
}

#Preview {
    @Previewable @State var text: String = ""
    
    let users: [User] = [
        .init(id: "0", name: "johny"),
        .init(id: "1", name: "jobs"),
        .init(id: "2", name: "steave"),
        .init(id: "3", name: "wozniak"),
        .init(id: "4", name: "james"),
        .init(id: "5", name: "robert"),
        .init(id: "6", name: "harry"),
    ]
    
    HStack(alignment: .bottom) {
        Promptly(
            text: $text,
            edge: .top,
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
            .font(.system(size: 14))
            .frame(minHeight: 30)
            .frame(maxHeight: 90)
            .fixedSize(horizontal: false, vertical: true)
            .padding(EdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(lineWidth: 1)
                    .fill(Color(.separatorColor))
            }
        
        Promptly(
            text: $text,
            edge: .bottom,
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
        .font(.system(size: 14))
        .frame(minHeight: 30)
        .frame(maxHeight: 90)
        .fixedSize(horizontal: false, vertical: true)
        .padding(EdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(lineWidth: 1)
                .fill(Color(.separatorColor))
        }
        .frame(height: 200, alignment: .top)
    }

    .frame(width: 600, height: 200, alignment: .bottom)
    .padding(40)
}




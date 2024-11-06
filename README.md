# Promptly

A lightweight and customizable mention suggestion view for SwiftUI. Promptly provides an elegant way to add mention functionality to your text input with async support.

## Features

- 🔄 Async/await support for suggestion sources
- ⌨️ Full keyboard navigation
- 🎨 Customizable suggestion views
- 🌈 Syntax highlighting for mentions
- 💻 Cross-platform (iOS & macOS)
- 🪶 Lightweight and easy to use

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/Promptly.git", from: "1.0.0")
]
```

## Usage

### Basic Example

```swift
struct ContentView: View {
    @State private var text = ""
    
    var body: some View {
        Promptly(
            text: $text,
            source: { searchText in
                // Fetch your data asynchronously
                try await fetchUsers(matching: searchText)
            },
            display: { user in user.name }
        ) { user in
            Text(user.name)
        }
    }
}
```

### Async Data Source

The source closure is async and can throw errors, making it perfect for network requests:

```swift
Promptly(
    text: $text,
    source: { searchText in
        // Example with URLSession
        let users = try await APIClient.searchUsers(matching: searchText)
        return users
    },
    display: { user in user.name }
) { user in
    Text(user.name)
}
```

### Custom Suggestion View

Customize how suggestions appear:

```swift
Promptly(
    text: $text,
    source: { searchText in
        try await fetchUsers(matching: searchText)
    },
    display: { user in user.name }
) { user in
    HStack {
        AsyncImage(url: user.avatarURL) { image in
            image.resizable()
        } placeholder: {
            Color.gray
        }
        .frame(width: 24, height: 24)
        .clipShape(Circle())
        
        VStack(alignment: .leading) {
            Text(user.name)
                .font(.headline)
            Text("@\(user.username)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
```

### Suggestion Position

Choose where suggestions appear:

```swift
Promptly(
    text: $text,
    edge: .top, // or .bottom (default)
    source: { searchText in
        try await fetchUsers(matching: searchText)
    },
    display: { user in user.name }
) { user in
    Text(user.name)
}
```

### Keyboard Navigation

**macOS**
- `↑` / `↓`: Navigate through suggestions
- `Enter`: Select current suggestion
- `Esc`: Close suggestions
- `Ctrl + N` / `Ctrl + P`: Alternative navigation

**iOS**
- Return key selects the current suggestion

## Best Practices

1. **Debouncing**: Consider implementing debouncing in your source closure for network requests:
```swift
private func fetchUsers(matching text: String) async throws -> [User] {
    try await Task.sleep(nanoseconds: 300_000_000) // 300ms debounce
    return try await apiClient.searchUsers(matching: text)
}
```

2. **Error Handling**: Handle potential errors in your source closure:
```swift
source: { searchText in
    do {
        return try await fetchUsers(matching: searchText)
    } catch {
        logger.error("Failed to fetch users: \(error)")
        return []
    }
}
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

Promptly is available under the MIT license. See the LICENSE file for more info.

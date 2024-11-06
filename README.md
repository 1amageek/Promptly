# Promptly

A lightweight and customizable mention suggestion view for SwiftUI. It provides real-time mention suggestions with a modern UI and keyboard navigation support.

![Promptly Demo](demo.gif)

## Features

- 🎯 Real-time mention suggestions
- 🎨 Customizable suggestion view
- ⌨️ Full keyboard navigation support
- 🖥️ macOS and iOS support
- 🌈 Syntax highlighting for mentions
- 🔄 Seamless integration with SwiftUI

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/1amageek/Promptly.git", from: "1.0.0")
]
```

Or add it directly through Xcode:
1. Go to File > Add Packages
2. Paste the repository URL: `https://github.com/1amageek/Promptly.git`
3. Click "Add Package"

## Usage

### Basic Example

```swift
struct ContentView: View {
    @State private var text = ""
    let users: [User] = [
        .init(id: "1", name: "john"),
        .init(id: "2", name: "steve")
    ]
    
    var body: some View {
        Promptly(
            text: $text,
            source: { searchText in
                users.filter { user in
                    searchText.isEmpty ||
                    user.name.localizedCaseInsensitiveContains(searchText)
                }
            },
            display: { user in user.name }
        ) { user in
            Text(user.name)
        }
    }
}
```

### Customizing Suggestion Position

You can choose where the suggestions appear by specifying the `edge` parameter:

```swift
Promptly(
    text: $text,
    edge: .top, // or .bottom (default)
    source: { searchText in
        // Your filtering logic
    },
    display: { user in user.name }
) { user in
    Text(user.name)
}
```

### Custom Suggestion View

Customize the appearance of each suggestion by providing your own view:

```swift
Promptly(
    text: $text,
    source: { searchText in
        users.filter { user in
            user.name.localizedCaseInsensitiveContains(searchText)
        }
    },
    display: { user in user.name }
) { user in
    HStack {
        Circle()
            .fill(Color.blue)
            .frame(width: 24, height: 24)
        
        VStack(alignment: .leading) {
            Text(user.name)
                .font(.headline)
            Text("@\(user.username)")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}
```

## Keyboard Navigation

### macOS
- `↑` / `↓`: Navigate through suggestions
- `Enter`: Select current suggestion
- `Esc`: Dismiss suggestions
- `Ctrl + N` / `Ctrl + P`: Alternative navigation

### iOS
- Return key selects the current suggestion


## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

Promptly is available under the MIT license. See the LICENSE file for more info.

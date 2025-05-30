# HalfSheet

[![CI](https://github.com/velos/HalfSheet/actions/workflows/ci.yml/badge.svg)](https://github.com/velos/HalfSheet/actions/workflows/ci.yml)
[![Release](https://github.com/velos/HalfSheet/actions/workflows/release.yml/badge.svg)](https://github.com/velos/HalfSheet/actions/workflows/release.yml)

A SwiftUI view modifier and helper to present a half-screen modal sheet in your iOS apps.

## Features

- Interactive drag-to-dismiss gestures
- Configurable close control (drag bar or close button)
- Prevent interactive dismiss when needed
- Dismiss action available via environment

## Installation

Add the following dependency to your `Package.swift`:

```swift
.package(url: "https://github.com/velos/HalfSheet.git", from: "0.1.0"),
```

Then add `"HalfSheet"` to your target's dependencies:

```swift
targets: [
    .target(
        name: "YourApp",
        dependencies: ["HalfSheet"]
    )
]
```

## Usage

Import the package:

```swift
import HalfSheet
```

Use the `.halfSheet` view modifier to present content:

```swift
struct ContentView: View {
    @State private var isPresented = false

    var body: some View {
        Button("Show Half Sheet") {
            isPresented = true
        }
        .halfSheet(isPresented: $isPresented) {
            Text("Hello from half sheet!")
                .padding()
        }
    }
}
```

To use item-based presentation:

```swift
struct Item: Identifiable, Equatable {
    let id = UUID()
    let title: String
}

struct ContentView: View {
    @State private var selectedItem: Item?

    var body: some View {
        List(items) { item in
            Button(item.title) {
                selectedItem = item
            }
        }
        .halfSheet(item: $selectedItem) { item in
            Text(item.title)
                .padding()
        }
    }
}
```

## API

```swift
public extension View {
    func halfSheet(isPresented: Binding<Bool>,
                   closeType: CloseType = .dragBar,
                   onDismiss: (() -> Void)? = nil,
                   @ViewBuilder content: @escaping () -> Content) -> some View

    func halfSheet<Item>(item: Binding<Item?>,
                         closeType: CloseType = .dragBar,
                         onDismiss: (() -> Void)? = nil,
                         @ViewBuilder content: @escaping (Item) -> Content) -> some View
}
```

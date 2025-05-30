import SwiftUI

enum HalfSheetLayoutConstants {
    static let maxWidth: CGFloat = 800
    static let edgePadding: CGFloat = 10
    static let cornerRadius: CGFloat = 46
}

enum DragState {
    case inactive
    case dragging(offset: CGFloat)

    var offset: CGFloat {
        switch self {
        case .inactive:
            return 0
        case .dragging(let offset):
            return offset
        }
    }
}

struct HalfSheetInteractiveDismissDisabledKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: Bool = false

    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = nextValue()
    }
}

extension View {
    func halfSheetInteractiveDismissDisabled(_ disabled: Bool) -> some View {
        self.preference(key: HalfSheetInteractiveDismissDisabledKey.self, value: disabled)
    }
}

public struct HalfSheetDismissAction {
    fileprivate var dismiss: () -> Void
    public func callAsFunction() {
        dismiss()
    }
}

public struct HalfSheetPresentationMode {
    public fileprivate(set) var isPresented: Bool
    fileprivate var isDismissing: Bool

    fileprivate mutating func reset() {
        self.isDismissing = false
        self.isPresented = true
    }

    public mutating func dismiss() {
        self.isDismissing = true
        self.isPresented = false
    }
}

public extension EnvironmentValues {
    @Entry var halfSheetPresentationMode: Binding<HalfSheetPresentationMode> = .constant(.init(isPresented: false, isDismissing: false))
    @Entry var halfSheetDismiss: HalfSheetDismissAction = HalfSheetDismissAction(dismiss: { })
}

public enum CloseType {
    case none
    case dragBar
    case closeButton
}

struct HalfSheet<Content: View, Parent: View, Item: Identifiable & Equatable>: View {

    var parent: Parent
    var content: (Item) -> Content

    @State private var presentationMode = HalfSheetPresentationMode(isPresented: true, isDismissing: false)
    private var dismiss: HalfSheetDismissAction
    private var closeType: CloseType

    var onDismiss: (() -> Void)?

    @State private var interactiveDismissDisabled: Bool = false
    @Binding var item: Item?

    @GestureState private var dragState: DragState = .inactive

    public init(_ parent: Parent,
                item: Binding<Item?>,
                closeType: CloseType = .dragBar,
                onDismiss: (() -> Void)? = nil,
                @ViewBuilder content: @escaping (Item) -> Content) {
        self._item = item
        self.closeType = closeType
        self.onDismiss = onDismiss
        self.parent = parent
        self.content = content

        self.dismiss = HalfSheetDismissAction(dismiss: {
            item.wrappedValue = nil
        })
    }

    private func close() {
        guard !self.interactiveDismissDisabled else { return }
        self.item = nil
        self.presentationMode.dismiss()
    }

    var body: some View {
        let hasItem = self.item != nil
        return ZStack {
            parent
            GeometryReader { proxy in
                ZStack(alignment: .bottom) {
                    if hasItem {
                        Color.black.opacity(0.25)
                            .transition(.opacity)
                            .onTapGesture(perform: close)
                        VStack(spacing: -1) {
                            ZStack(alignment: .top) {
                                RoundedRectangle(cornerRadius: HalfSheetLayoutConstants.cornerRadius)
                                    .foregroundStyle(.background)

                                VStack(spacing: 0) {
                                    Group {
                                        switch closeType {
                                        case .closeButton:
                                            HStack {
                                                Spacer()
                                                Button {
                                                    close()
                                                } label: {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .resizable()
                                                        .frame(width: 25, height: 25)
                                                }
                                                .foregroundStyle(.tertiary)
                                                .disabled(interactiveDismissDisabled)
                                            }
                                            .padding(.horizontal, 22)
                                            .padding(.top, 22)
                                            .padding(.bottom, 0)
                                            .opacity(interactiveDismissDisabled ? 0.5 : 1)
                                        case .dragBar:
                                            Capsule(style: .circular)
                                                .frame(width: 50, height: 6)
                                                .foregroundColor(Color.gray.opacity(0.5))
                                                .padding(.top, 10)
                                                .opacity(interactiveDismissDisabled ? 0.5 : 1)
                                        case .none:
                                            EmptyView()
                                        }
                                    }
                                    .id(closeType)

                                    self.item.flatMap { self.content($0) }
                                }
                            }
                            .frame(maxHeight: proxy.size.height - proxy.safeAreaInsets.top, alignment: .bottom)
                            .padding(.bottom, max(proxy.safeAreaInsets.bottom, 18) + HalfSheetLayoutConstants.edgePadding)
                            .clipShape(RoundedRectangle(cornerRadius: HalfSheetLayoutConstants.cornerRadius))
                            .offset(y: dragState.offset)
                        }
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(width: min(proxy.size.width - 2 * HalfSheetLayoutConstants.edgePadding, HalfSheetLayoutConstants.maxWidth))
                        .gesture(DragGesture(coordinateSpace: .global).updating(self.$dragState) { value, state, _ in
                            if value.translation.height < 0 {
                                state = .dragging(offset: value.translation.height / 3.0)
                            } else if self.interactiveDismissDisabled {
                                state = .dragging(offset: value.translation.height / 5.0)
                            } else {
                                state = .dragging(offset: value.translation.height)
                            }
                        }.onEnded({ value in
                            guard !self.interactiveDismissDisabled else { return }

                            let threshold = proxy.size.height / 6
                            if value.translation.height > threshold || value.predictedEndTranslation.height > threshold {
                                self.item = nil
                                self.presentationMode.dismiss()
                            }
                        }))
                        .zIndex(100)
                        .transition(.move(edge: .bottom))
                        .onDisappear {
                            if !self.presentationMode.isPresented {
                                self.item = nil
                            }

                            self.onDismiss?()
                            self.presentationMode.reset()
                        }
                    }
                }
            }
            .animation(.snappy, value: hasItem)
            .animation(.interactiveSpring, value: dragState.offset)
            .edgesIgnoringSafeArea(.all)
        }.onPreferenceChange(HalfSheetInteractiveDismissDisabledKey.self) { disabled in
            self.interactiveDismissDisabled = disabled
        }
        .environment(\.halfSheetPresentationMode, $presentationMode)
        .environment(\.halfSheetDismiss, dismiss)
    }
}

private final class IdentifiableObject: Identifiable, Equatable, Sendable {
    static func == (lhs: IdentifiableObject, rhs: IdentifiableObject) -> Bool {
        lhs.id == rhs.id
    }
}

extension View {
    public func halfSheet<Content>(isPresented: Binding<Bool>,
                                   closeType: CloseType = .dragBar,
                                   onDismiss: (() -> Void)? = nil,
                                   @ViewBuilder content: @escaping () -> Content) -> some View where Content: View {
        let identifiable = IdentifiableObject()
        let item = Binding<IdentifiableObject?>(get: { () -> IdentifiableObject? in
            return isPresented.wrappedValue ? identifiable : nil
        }, set: { newValue in
            isPresented.wrappedValue = newValue != nil
        })

        return HalfSheet(self, item: item, closeType: closeType, onDismiss: onDismiss, content: { _ in content() })
    }

    public func halfSheet<Content, Item>(item: Binding<Item?>,
                                        closeType: CloseType = .dragBar,
                                        onDismiss: (() -> Void)? = nil,
                                        @ViewBuilder content: @escaping (Item) -> Content) -> some View where Content: View, Item: Identifiable & Equatable {
        return HalfSheet(self, item: item, closeType: closeType, onDismiss: onDismiss, content: content)
    }
}

#if DEBUG

struct AppleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity)
            .fontWeight(.semibold)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .foregroundStyle(Color(.secondarySystemBackground))
                    .opacity(configuration.isPressed ? 0.5 : 1)
            }
    }
}

extension ButtonStyle where Self == AppleButtonStyle {
    static var appleButtonStyle: AppleButtonStyle {
        return AppleButtonStyle()
    }
}

@available(iOS 17, *)
#Preview {
    @Previewable @State var isPresented: Bool = true
    Color.blue
        .ignoresSafeArea()
        .halfSheet(isPresented: $isPresented, closeType: .closeButton) {
            VStack(spacing: 35) {
                VStack(spacing: 10) {
                    Text("Hold Near Phone")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Please hold your phone near the reader to finish setup.")
                }
                .multilineTextAlignment(.center)

                Image(systemName: "iphone.gen3.crop.circle")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120)
                    .fontWeight(.light)
                    .foregroundStyle(.blue)

                Button {

                } label: {
                    Text("Cancel")
                }
                .buttonStyle(.appleButtonStyle)
            }
            .padding(.top, 15)
            .padding(.bottom, 30)
            .padding(.horizontal, 26)
        }
}

#endif

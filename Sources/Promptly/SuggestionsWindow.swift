//#if os(macOS)
//
//import SwiftUI
//
//class SuggestionsWindow: NSWindow {
//    init(contentRect: NSRect) {
//        super.init(
//            contentRect: contentRect,
//            styleMask: [.borderless],
//            backing: .buffered,
//            defer: false
//        )
//        
//        self.backgroundColor = .clear
//        self.isOpaque = false
//        self.hasShadow = true
//        self.level = .floating
//    }
//}
//
//struct SuggestionsPopover<Content: View>: NSViewRepresentable {
//    let content: Content
//    let isPresented: Bool
//    let anchorPoint: CGPoint
//    
//    init(isPresented: Bool, anchorPoint: CGPoint, @ViewBuilder content: () -> Content) {
//        self.content = content()
//        self.isPresented = isPresented
//        self.anchorPoint = anchorPoint
//    }
//    
//    func makeNSView(context: Context) -> NSView {
//        let view = NSView()
//        return view
//    }
//    
//    func updateNSView(_ nsView: NSView, context: Context) {
//        if isPresented {
//            if context.coordinator.window == nil {
//                // ウィンドウの作成
//                let window = SuggestionsWindow(
//                    contentRect: .init(
//                        origin: anchorPoint,
//                        size: .init(width: 200, height: 200)
//                    )
//                )
//                
//                // コンテンツの設定
//                let hostingView = NSHostingView(rootView: content)
//                window.contentView = hostingView
//                
//                // ウィンドウの表示
//                window.orderFront(nil)
//                context.coordinator.window = window
//            } else {
//                // 位置の更新
//                context.coordinator.window?.setFrameOrigin(anchorPoint)
//            }
//        } else {
//            // ウィンドウを閉じる
//            context.coordinator.window?.close()
//            context.coordinator.window = nil
//        }
//    }
//    
//    func makeCoordinator() -> Coordinator {
//        Coordinator()
//    }
//    
//    class Coordinator {
//        var window: NSWindow?
//    }
//}
//
//extension View {
//    func suggestionsPopover<Content: View>(
//        isPresented: Bool,
//        anchorPoint: CGPoint,
//        @ViewBuilder content: @escaping () -> Content
//    ) -> some View {
//        self.background(
//            SuggestionsPopover(
//                isPresented: isPresented,
//                anchorPoint: anchorPoint,
//                content: content
//            )
//        )
//    }
//}
//#endif

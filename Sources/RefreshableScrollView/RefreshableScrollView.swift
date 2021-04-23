import SwiftUI

public struct RefreshableScrollView<Content: View>: View {
    @State private var previousScrollOffset: CGFloat = 0
    @State private var scrollOffset: CGFloat = 0
    @State private var frozen: Bool = false
    @State private var rotation: Angle = .degrees(0)
    
    var threshold: CGFloat = 80
    @Binding var refreshing: Bool
    let content: Content
    public typealias Action = ()->Void
    let action: Action?
    @State var fixedMinY: CGFloat = 0

    public init(refreshing: Binding<Bool>, action: Action? = nil, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.action = action
        self._refreshing = refreshing
    }
    
    public var body: some View {
        VStack {
            ScrollView {
                ZStack(alignment: .top) {
                    MovingView()
                    
                    VStack { self.content }
                        .alignmentGuide(.top, computeValue: { d in (self.refreshing && self.frozen) ? -self.threshold : 0.0 })
                        // add an animation when a view is going up only
                        .animation(self.refreshing ? .none : .default)
                    
                    SymbolView(height: self.threshold,
                               loading: self.refreshing,
                               frozen: self.frozen,
                               rotation: self.rotation,
                               offset: self.threshold)
                    
                }
            }
            .background(FixedView())
            .onPreferenceChange(RefreshableKeyTypes.PrefKey.self) { values in
                self.refreshLogic(values: values)
            }
        }
    }
   
    

    func refreshLogic(values: [RefreshableKeyTypes.PrefData]) {
        DispatchQueue.main.async {
            // Calculate scroll offset
            let movingBounds = values.first { $0.vType == .movingView }?.bounds ?? .zero
            let fixedBounds = values.first { $0.vType == .fixedView }?.bounds ?? .zero
            self.fixedMinY = fixedBounds.minY
            
            self.scrollOffset  = movingBounds.minY - fixedBounds.minY
            
            self.rotation = self.symbolRotation(self.scrollOffset)
            
            // Crossing the threshold on the way down, we start the refresh process
            if !self.refreshing && (self.scrollOffset > self.threshold && self.previousScrollOffset <= self.threshold) {
                self.refreshing = true
                self.action?()
            }
            
            if self.refreshing {
                // Crossing the threshold on the way up, we add a space at the top of the scrollview
                if self.previousScrollOffset > self.threshold && self.scrollOffset <= self.threshold {
                    self.frozen = true

                }
            } else {
                // remove the sapce at the top of the scroll view
                self.frozen = false
            }
            
            // Update last scroll offset
            self.previousScrollOffset = self.scrollOffset
        }
    }
    
    func symbolRotation(_ scrollOffset: CGFloat) -> Angle {
        
        // We will begin rotation, only after we have passed
        // 60% of the way of reaching the threshold.
        if scrollOffset < self.threshold * 0.60 {
            return .degrees(0)
        } else {
            // Calculate rotation, based on the amount of scroll offset
            let h = Double(self.threshold)
            let d = Double(scrollOffset)
            let v = max(min(d - (h * 0.6), h * 0.4), 0)
            return .degrees(180 * v / (h * 0.4))
        }
    }
    
    struct SymbolView: View {
        var height: CGFloat
        var loading: Bool
        var frozen: Bool
        var rotation: Angle
        var offset: CGFloat
        
        private func pullView() -> some View {
            return VStack {
                Spacer()
                HStack {
                    Text("Pull-down-to-refresh") // localization
                    Image(systemName: "arrow.down") // If not loading, show the arrow
                        .resizable()
                        .foregroundColor(.secondary)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: height * 0.25, height: height * 0.25).fixedSize()
                        .padding(height * 0.375)
                        .rotationEffect(rotation)
                }
                Spacer()
            }
            .frame(height: height)
            .fixedSize()
            .animation(.easeInOut(duration: 2))
            .offset(y: -self.offset + (loading && frozen ? +self.offset : 0.0))
        }
        
        var body: some View {
            Group {
                if self.loading { // If loading, show the activity control
                    VStack {
                        Spacer()
                        ActivityRep()
                        Spacer()
                    }
                    .frame(height: height).fixedSize()
                    .offset(y: -height + (self.loading && self.frozen ? height : 0.0))
                    
                } else {
                    pullView()
                }
            }
        }
    }
    
    struct MovingView: View {
        var body: some View {
            GeometryReader { proxy in
                Color.clear.preference(key: RefreshableKeyTypes.PrefKey.self, value: [RefreshableKeyTypes.PrefData(vType: .movingView, bounds: proxy.frame(in: .global))])
            }.frame(height: 0)
        }
    }
    
    struct FixedView: View {
        var body: some View {
            GeometryReader { proxy in
                Color
                    .clear
                    .preference(key: RefreshableKeyTypes.PrefKey.self, value: [RefreshableKeyTypes.PrefData(vType: .fixedView, bounds: proxy.frame(in: .global))])
            }
        }
    }
    
    public struct ActivityRep: UIViewRepresentable {
        public init() {}
        public func makeUIView(context: UIViewRepresentableContext<ActivityRep>) -> UIActivityIndicatorView {
            return UIActivityIndicatorView()
        }
        
        public func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<ActivityRep>) {
            uiView.startAnimating()
        }
    }
    
    public enum ScrollType {
        case scrollView
        case list
    }
    
    struct WrapperView <Content>: View where Content: View {
        let scrollType: ScrollType
        let content: Content
        
        init(_ scrollType: ScrollType, @ViewBuilder content: ()-> Content) {
            self.scrollType = scrollType
            self.content = content()
        }
        
        var body: some View {
            Group {
                if self.scrollType == .scrollView {
                    ScrollView { self.content }
                } else {
                    List { self.content }
                }
            }
        }
    }
   
}

struct RefreshableKeyTypes {
    enum ViewType: Int {
        case movingView
        case fixedView
    }
    
    struct PrefData: Equatable {
        let vType: ViewType
        let bounds: CGRect
    }
    
    struct PrefKey: PreferenceKey {
        static var defaultValue: [PrefData] = []
        
        static func reduce(value: inout [PrefData], nextValue: () -> [PrefData]) {
            value.append(contentsOf: nextValue())
        }
        
        typealias Value = [PrefData]
    }
}

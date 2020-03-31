# RefreshableScrollView

A refershable scroll view that supports List and ScrollView

The original code from this article https://swiftui-lab.com/scrollview-pull-to-refresh/. It helped me a lot. Thank you.

## Platform
iOS
macOS

## Installation
In your project, go to File -> Swift Packages -> Add Package Dependency. Copy and paste the url below into the search box
https://github.com/phuhuynh2411/RefreshableScrollView.git

## Basic Usage
It uses the ScrollView as a wrapper for the content
```swift
RefreshableScrollView(refreshing: $refresh, action: {
    // add your code here
    // remmber to set the refresh to false
    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
        self.refresh = false
    }
}) {
    ForEach(0..<20){ index in
        Text("Item \(index)")
    }
}
```
## Use with List
In some cases, you would like to use List view instead of Scrollview. You could change the scrollType to .list. There are two kinds of scroll type.
* .list
* .scrollView: this is a default value

```swift
RefreshableScrollView(refreshing: $refresh, scrollType: .list
    action: { self.load() }
) {
    ForEach(0..<20){ index in
        Text("Item \(index)")
    }
}
```

## Customize Activity View
```swift
RefreshableScrollView(refreshing: $refresh,
                      activityView: AnyView(InfiniteProgressView().frame(width: 20, height: 20, alignment: .center)),
                      action: { self.load() }) {
    ForEach(0..<20){ index in
        Text("Item \(index)")
    }
}
```
## Customize Pull View
```swift
RefreshableScrollView(refreshing: $refresh,
                      activityView: AnyView(InfiniteProgressView().frame(width: 20, height: 20, alignment: .center)),
                      pullView: { height, rotation, loading, frozen in
                        let image = Image(systemName: "shift") // If not loading, show the arrow
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: height * 0.25, height: height * 0.25).fixedSize()
                            .padding(height * 0.375)
                            .rotationEffect(rotation)
                            .offset(y: -height + (loading && frozen ? +height : 0.0))
                        return AnyView(image) },
                      action: { self.load() }
) {
    ForEach(0..<20){ index in
        Text("Item \(index)")
    }
}
```

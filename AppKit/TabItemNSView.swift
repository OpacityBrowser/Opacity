//
//  TabItemView.swift
//  Opacity
//
//  Created by Falsy on 2/6/24.
//

import SwiftUI

struct TabItemNSView: NSViewRepresentable {
  @ObservedObject var service: Service
  @Binding var tabs: [Tab]
  @ObservedObject var tab: Tab
  @Binding var activeTabId: UUID?
  var index: Int
  @Binding var tabWidth: CGFloat
  @Binding var showProgress: Bool
  @Binding var isTabHover: Bool
  @Binding var loadingAnimation: Bool
  
  func moveTab(_ idx: Int) {
    if let targetIndex = tabs.firstIndex(where: { $0.id == service.dragTabId }) {
      let removedItem = tabs.remove(at: targetIndex)
      tabs.insert(removedItem, at: idx)
      activeTabId = removedItem.id
    } else {
      service.isMoveTab = true
      for (_, browser) in service.browsers {
        if let targetTab = browser.tabs.first(where: { $0.id == service.dragTabId }) {
          tabs.insert(targetTab, at: idx + 1)
          activeTabId = targetTab.id
          break
        }
      }
    }
  }
  
  func makeNSView(context: Context) -> NSView {
    let containerView = TabDragSource()
    containerView.dragDelegate = context.coordinator
    containerView.moveTab = moveTab
    containerView.index = index
    
    let hostingView = NSHostingView(rootView: TabItem(tab: tab, activeTabId: $activeTabId, tabWidth: $tabWidth, showProgress: $showProgress, isTabHover: $isTabHover, loadingAnimation: $loadingAnimation))
    hostingView.translatesAutoresizingMaskIntoConstraints = false
    
    containerView.addSubview(hostingView)
    
    NSLayoutConstraint.activate([
      hostingView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
      hostingView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
      hostingView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: -20),
      hostingView.heightAnchor.constraint(equalTo: containerView.heightAnchor)
    ])
    
    context.coordinator.tabItemNSView = containerView
    return containerView
  }
  
  func updateNSView(_ nsView: NSView, context: Context) {
    context.coordinator.thisIndex = index
    context.coordinator.tabId = tab.id
    
    for subview in nsView.subviews {
      if let hostingView = subview as? NSHostingView<TabItem> {
        hostingView.rootView = TabItem(tab: tab, activeTabId: $activeTabId, tabWidth: $tabWidth, showProgress: $showProgress, isTabHover: $isTabHover, loadingAnimation: $loadingAnimation)
        hostingView.layout()
      }
    }
    
    if let customView = nsView as? TabDragSource {
      if customView.index != index {
        customView.index = index
      }
    }
  }
  
  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }
  
  class Coordinator: NSObject, NSDraggingSource {
    var parent: TabItemNSView
    var thisIndex: Int?
    var tabId: UUID?
    weak var tabItemNSView: TabDragSource?
    
    init(_ parent: TabItemNSView) {
      self.parent = parent
    }
    
    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
      return .move
    }

    func draggingSession(_ session: NSDraggingSession, willBeginAt screenPoint: NSPoint) {
      parent.activeTabId = tabId!
      parent.service.dragTabId = tabId!
    }
    
    func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
      guard let window = tabItemNSView?.window else { return }
      
      let windowFrame = window.frame
      let windowPoint = window.convertPoint(fromScreen: screenPoint)
      let titleBarHeight: CGFloat = 80
      let titleBarRect = NSRect(x: 0, y: windowFrame.height - titleBarHeight, width: windowFrame.width, height: titleBarHeight)
      
      if !titleBarRect.contains(windowPoint) {
        print("Exit outside of window")
        if let dragId = parent.service.dragTabId {
          if let targetIndex = parent.tabs.firstIndex(where: { $0.id == dragId }) {
            if(parent.tabs.count == 1) {
              if parent.service.isMoveTab {
                AppDelegate.shared.closeTab()
              }
            } else {
              if parent.service.isMoveTab {
                parent.tabs.remove(at: targetIndex)
                let newActiveTabIndex = targetIndex == 0 ? 0 : targetIndex - 1
                parent.activeTabId = parent.tabs[newActiveTabIndex].id
              } else {
                let newWindowframe = NSRect(x: screenPoint.x - (windowFrame.width / 2), y: screenPoint.y - windowFrame.height, width: windowFrame.width, height: windowFrame.height)
                AppDelegate.shared.createNewWindow(tabId: dragId, frame: newWindowframe)
              }
            }
          }
        }
      }
      
      parent.service.dragTabId = nil
      parent.service.isMoveTab = false
    }
  }
}


class TabDragSource: NSView {
  var appDelegate: AppDelegate?
  var dragDelegate: NSDraggingSource?
  var index: Int?
  var moveTab: ((Int) -> Void)?
  
  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    self.registerForDraggedTypes([.string]) // 드래그 대상으로 등록
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func mouseDown(with event: NSEvent) {
    guard let dragDelegate = dragDelegate else { return }
    
    let draggedImage = self.snapshot()
    
    let draggingItem = NSDraggingItem(pasteboardWriter: NSString(string: "Drag Content"))
    draggingItem.setDraggingFrame(self.bounds, contents: draggedImage) // Content
    
    let session = self.beginDraggingSession(with: [draggingItem], event: event, source: dragDelegate)
    session.animatesToStartingPositionsOnCancelOrFail = true
  }
  
  override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
    print("dragenterd")
    return .move
  }
  
  override func draggingExited(_ sender: NSDraggingInfo?) {
    print("drag exited")
  }
  
  override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
    if let thisIndex = self.index, let moveFunc = self.moveTab {
      moveFunc(thisIndex)
    }
//    Dragged data processing logic
//    guard let draggedData = sender.draggingPasteboard.string(forType: .string) else { return false }
//    print("Dragged Data: \(draggedData)")
//
//    appDelegate!.someMethodToCall()
    return true
  }
  
  override func concludeDragOperation(_ sender: NSDraggingInfo?) {
      print("conclude drag operation")
  }
  
  func snapshot() -> NSImage {
      let image = NSImage(size: self.bounds.size)
      image.lockFocus()
      defer { image.unlockFocus() }
      if let context = NSGraphicsContext.current?.cgContext {
          self.layer?.render(in: context)
      }
      return image
  }
}

//
//  WindowTitleBar.swift
//  Opacity
//
//  Created by Falsy on 3/5/24.
//

import SwiftUI

struct WindowTitleBarView: View {
  @Binding var windowWidth: CGFloat?
  @ObservedObject var service: Service
  @ObservedObject var browser: Browser
  
  @Binding var tabs: [Tab]
  @Binding var activeTabId: UUID?
  var isFullScreen: Bool
  
  @State private var isMoreTabDialog = false
  @State private var isMoreHover: Bool = false
  
  var body: some View {
    if let width = windowWidth {
      ZStack {
        if isFullScreen {
          Rectangle()
            .frame(width: width, height: 38)
            .foregroundColor(Color("WindowTitleBG"))
        }
        HStack(spacing: 0) {
          WindowTitlebar(width: $windowWidth, service: service, browser: browser, tabs: $browser.tabs, activeTabId: $browser.activeTabId)
          Spacer()
          
          if isFullScreen {
            VStack(spacing: 0) {
              VStack(spacing: 0) {
                Image(systemName: "rectangle.stack")
                  .foregroundColor(Color("Icon"))
                  .font(.system(size: 14))
                  .fontWeight(.regular)
                  .opacity(0.6)
              }
              .frame(maxWidth: 25, maxHeight: 25)
              .background(isMoreHover ? .gray.opacity(0.2) : .gray.opacity(0))
              .clipShape(RoundedRectangle(cornerRadius: 6))
              .onHover { hovering in
                withAnimation {
                  isMoreHover = hovering
                }
              }
              .onTapGesture {
                self.isMoreTabDialog.toggle()
              }
              .popover(isPresented: $isMoreTabDialog, arrowEdge: .bottom) {
                TabDialog(service: service, browser: browser, tabs: $browser.tabs, activeTabId: $browser.activeTabId)
              }
              .padding(.trailing, 10)
            }
          } else {
            Button(action: {
              self.isMoreTabDialog.toggle()
            }) {
              Image(systemName: "rectangle.stack")
                .popover(isPresented: $isMoreTabDialog, arrowEdge: .bottom) {
                  TabDialog(service: service, browser: browser, tabs: $browser.tabs, activeTabId: $browser.activeTabId)
                }
            }
          }
        }
        .frame(width: width - (isFullScreen ? 0 : 90), height: 38)
      }
    }
  }
}

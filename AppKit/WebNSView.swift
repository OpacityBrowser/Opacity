//
//  Webview.swift
//  Opacity
//
//  Created by Falsy on 1/10/24.
//

import SwiftUI
import WebKit
import ASN1Decoder
import Security

struct WebNSView: NSViewRepresentable {
  @ObservedObject var service: Service
  @ObservedObject var browser: Browser
  @ObservedObject var tab: Tab
  
  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }
  
  class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKDownloadDelegate, URLSessionDelegate {
    var parent: WebNSView
//    var errorPages: [WKBackForwardListItem: URL] = [:]
//    var errorOriginURL: URL?
    var currentURL: URL?
    var isProgress: Bool = false
    var certificateInfo: [String: String] = [:]
    var isUsingBackOrForward: Bool = false
    
    init(_ parent: WebNSView) {
      self.parent = parent
    }
    
    // Find Text
    func searchWebView(_ webView: WKWebView, findText: String, isPrev: Bool) {
      let script = "window.find('\(findText)', false, \(isPrev), true);"
      webView.evaluateJavaScript(script, completionHandler: nil)
    }
    
    // Download Delegate Methods
    func download(_ download: WKDownload, decideDestinationUsing response: URLResponse, suggestedFilename: String, completionHandler: @escaping (URL?) -> Void) {
      let savePanel = NSSavePanel()
      savePanel.directoryURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
      savePanel.nameFieldStringValue = suggestedFilename
      
      savePanel.begin { result in
        if result == .OK {
          completionHandler(savePanel.url)
        } else {
          completionHandler(nil)
        }
      }
    }
    
    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
      download.delegate = self
    }
    
    func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
      download.delegate = self
    }
    
    func webView(_ webView: WKWebView, download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
      print("Download failed: \(error.localizedDescription)")
    }
    
    func webView(_ webView: WKWebView, downloadDidFinish download: WKDownload) {
      print("Download finished successfully.")
    }
    
    func getCurrentItem(of webView: WKWebView) -> WKBackForwardListItem? {
      guard let currentItem = webView.backForwardList.currentItem else {
        return nil
      }
      return currentItem
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
      print("didStartProvisionalNavigation")
      DispatchQueue.main.async {
        withAnimation {
          self.parent.tab.pageProgress = webView.estimatedProgress
        }
      }
      
//      if let webviewURL = webView.url, webviewURL != parent.tab.originURL {
//        DispatchQueue.main.async {
////          self.parent.tab.updateURLByBrowser(url: webviewURL, isClearCertificate: true)
//          self.checkedSSLCertificate(url: webviewURL)
//          self.parent.tab.redirectURLByBrowser(url: webviewURL)
//        }
//      }
//      if let webviewURL = webView.url, let host = webviewURL.host,
//          parent.tab.webviewIsError == false,
//          webviewURL != parent.tab.originURL {
//        
//        DispatchQueue.main.async {
//          print("navWebviewURL: \(webviewURL)")
//          print("navTabURL: \(self.parent.tab.originURL)")
//          
//          withAnimation {
//            self.parent.tab.pageProgress = webView.estimatedProgress
//          }
//          
//          if host != self.parent.tab.originURL.host && self.isUsingBackOrForward == false {
//            self.parent.tab.updateURLByBrowser(url: webviewURL, isClearCertificate: true)
//          } else {
//            if self.isUsingBackOrForward == true {
//              if let summary = self.certificateInfo[host] {
//                self.parent.tab.isValidCertificate = true
//                self.parent.tab.certificateSummary = summary
//              } else {
//                self.parent.tab.isValidCertificate = false
//                self.parent.tab.certificateSummary = ""
//              }
//              self.isUsingBackOrForward = false
//              print("clear Back or Forward")
//            }
//            self.parent.tab.redirectURLByBrowser(url: webviewURL)
//          }
//        }
//      }
    }
    
//    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
//      parent.tab.webviewIsError = false
//      if parent.tab.webviewCheckError {
//        parent.tab.webviewCheckError = false
//        parent.tab.webviewIsError = true
//        
//        if let errorURL = errorOriginURL, let currentItem = getCurrentItem(of: webView) {
//          errorPages[currentItem] = errorURL
//          errorOriginURL = nil
//        }
//      } else {
//        if let currentItem = getCurrentItem(of: webView), let originalURL = errorPages[currentItem] {
//          load(url: originalURL, in: webView)
//          errorPages.removeValue(forKey: currentItem)
//        }
//      }
//    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
//      print("decidePolicyFor")
//      if navigationAction.navigationType == .backForward {
//        print("is Back or Forward")
//        isUsingBackOrForward = true
//      }
      
      guard let _ = navigationAction.request.url else {
        decisionHandler(.cancel)
        return
      }
      
      if navigationAction.shouldPerformDownload {
        decisionHandler(.download)
        return
      }
      
      decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
      print("didReceiveServerRedirectForProvisionalNavigation")
      if let webviewURL = webView.url, webviewURL != parent.tab.originURL {
        DispatchQueue.main.async {
          self.parent.tab.redirectURLByBrowser(url: webviewURL)
        }
      }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
      print("didFinish")
      let group = DispatchGroup()
      
      DispatchQueue.main.async {
        withAnimation {
          self.parent.tab.pageProgress = 1.0
        }
        self.parent.tab.isBack = webView.canGoBack
        self.parent.tab.isForward = webView.canGoForward
        self.parent.tab.historyBackList = webView.backForwardList.backList
        self.parent.tab.historyForwardList = webView.backForwardList.forwardList
        
        if let webviewURL = webView.url {
          print("webviewURL: \(webviewURL)")
          print("self.parent.tab.originURL: \(self.parent.tab.originURL)")
          self.checkedSSLCertificate(url: webviewURL)
          if webviewURL != self.parent.tab.originURL {
            if webviewURL.scheme == "opacity" {
              self.parent.tab.redirectURLByBrowser(url: self.parent.tab.originURL)
            } else {
              self.parent.tab.redirectURLByBrowser(url: webviewURL)
            }
          }
        }
      }
      
      let historyList = webView.backForwardList.backList + webView.backForwardList.forwardList
      let historyUrlList = historyList.compactMap { $0.url }
      
      self.parent.tab.historySiteDataList = self.parent.tab.historySiteDataList.filter { item in
        historyUrlList.contains(item.url)
      }
      
      if parent.tab.webviewIsError {
        print("error page init script")
        let lang = Locale.current.language.languageCode?.identifier ?? "en"
        let headTitle = parent.tab.printURL
        let href = parent.tab.originURL
        var refreshBtn = NSLocalizedString("Refresh", comment: "")
        var title = ""
        var message = ""
        
        switch parent.tab.webviewErrorType {
          case .notFindHost:
            title = NSLocalizedString("Page not found", comment: "")
            message = String(format: NSLocalizedString("The server IP address for \\'%@\\' could not be found.", comment: ""), parent.tab.printURL)
            break
          case .notConnectHost:
            title = NSLocalizedString("Unable to connect to site", comment: "")
            message = NSLocalizedString("Connection has been reset.", comment: "")
            break
          case .notConnectInternet:
            title = NSLocalizedString("No internet connection", comment: "")
            message = NSLocalizedString("There is no internet connection.", comment: "")
            break
          case .occurredSSLError:
            title = NSLocalizedString("SSL/TLS certificate error", comment: "")
            message = NSLocalizedString("A secure connection cannot be made because the certificate is not valid.", comment: "")
            break
          case .blockedContent:
            title = NSLocalizedString("Blocked content", comment: "")
            message = NSLocalizedString("This content is blocked. To use the service, you must lower or turn off tracker blocking.", comment: "")
            refreshBtn = NSLocalizedString("Go back", comment: "")
            break
          case .unknown:
            title = NSLocalizedString("Unknown error", comment: "")
            message = NSLocalizedString("An unknown error occurred.", comment: "")
            break
          case .noError:
            break
        }
        
        if parent.tab.webviewErrorType != .noError {
          webView.evaluateJavaScript("""
          window.opacityPage.initPageData({
            lang: '\(lang)',
            href: '\(href)',
            headTitle: '\(headTitle)',
            title: '\(title)',
            refreshBtn: '\(refreshBtn)',
            message: '\(message)'})
         """)
        }
        
        parent.tab.webviewIsError = false
      }
      
      webView.evaluateJavaScript("""
      window.addEventListener('hashchange', function() {
        window.webkit.messageHandlers.opacityBrowser.postMessage({
          name: "hashChange",
          value: window.location.href
        });
      });
     """)
      
      var cacheTitle: String?
      group.enter()
      webView.evaluateJavaScript("document.title") { (response, error) in
        if let title = response as? String {
          
          DispatchQueue.main.async {
            cacheTitle = title
            self.parent.tab.title = title
            if let webviewURL = webView.url, let scheme = webviewURL.scheme, let host = webviewURL.host() {
              if scheme == "opacity" {
                if host == "settings" {
                  self.parent.tab.title = NSLocalizedString("Settings", comment: "")
                }
                if host == "new-tab" {
                  self.parent.tab.title = NSLocalizedString("New Tab", comment: "")
                }
              }
            }
            group.leave()
          }
        } else {
          group.leave()
        }
      }
      
      var cacheFaviconURL: URL?
      group.enter()
      webView.evaluateJavaScript("document.querySelector(\"link[rel*='icon']\").getAttribute(\"href\")") { (response, error) in
        let unwantedCharacters = CharacterSet(charactersIn: "\n\r\t")
        guard let href = response as? String, let currentURL = webView.url, href.components(separatedBy: unwantedCharacters).joined() != "" else {
          if let webviewURL = webView.url, let scheme = webviewURL.scheme, let host = webviewURL.host  {
            if webviewURL.scheme != "opacity" {
              let faviconURL = scheme + "://" + host + "/favicon.ico"
              DispatchQueue.main.async {
                cacheFaviconURL = URL(string: faviconURL)!
                self.parent.tab.loadFavicon(url: URL(string: faviconURL)!)
              }
            }
          }
          group.leave()
          return
        }
      
        let cleanedHref = href.components(separatedBy: unwantedCharacters).joined()
        
        let faviconURL: URL
        if cleanedHref.hasPrefix("http") {
          faviconURL = URL(string: cleanedHref)!
        } else if cleanedHref.hasPrefix("//") {
          faviconURL = URL(string: "https:\(cleanedHref)")!
        } else if cleanedHref.hasPrefix("/") {
          var components = URLComponents(url: currentURL, resolvingAgainstBaseURL: true)!
          
          let splitHref = cleanedHref.split(separator: "?", maxSplits: 1, omittingEmptySubsequences: true)
          let pathPart = String(splitHref[0])
          let queryPart = splitHref.count > 1 ? String(splitHref[1]) : nil
          
          components.path = pathPart
          components.query = queryPart
          
          faviconURL = components.url!
        } else {
          faviconURL = URL(string: cleanedHref, relativeTo: currentURL)!
        }
        
        DispatchQueue.main.async {
          cacheFaviconURL = faviconURL
          self.parent.tab.loadFavicon(url: faviconURL)
          group.leave()
        }
      }
      
      group.notify(queue: .main) {
        if let title = cacheTitle, let currentURL = webView.url {
          let historySite = HistorySite(title: title, url: self.parent.tab.originURL)
          if let faviconURL = cacheFaviconURL {
            historySite.loadFavicon(url: faviconURL)
            Task {
              let faviconData = await VisitHistoryGroup.getFaviconData(url: faviconURL)
              await VisitManager.addVisitHistory(url: currentURL.absoluteString, title: title, faviconData: faviconData)
            }
          }
          self.parent.tab.historySiteDataList.append(historySite)
        }
      }
    }
    
    private func downloadImage(from url: URL, completion: @escaping (Data?, Error?) -> Void) {
      let task = URLSession.shared.dataTask(with: url) { data, response, error in
        completion(data, error)
      }
      task.resume()
    }
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
      if let customAction = (webView as? OpacityWebView)?.contextualMenuAction, let requestURL = navigationAction.request.url {
        if customAction == .downloadImage {
          downloadImage(from: requestURL) { data, error in
            guard let data = data, error == nil else { return }
            
            DispatchQueue.main.async {
              let savePanel = NSSavePanel()
              savePanel.allowedContentTypes = [.png, .jpeg, .bmp, .gif]
              savePanel.canCreateDirectories = true
              savePanel.isExtensionHidden = false
              savePanel.title = "Save As"
              savePanel.nameFieldLabel = NSLocalizedString("Save As:", comment: "")
              if requestURL.lastPathComponent != "" {
                savePanel.nameFieldStringValue = requestURL.lastPathComponent
              }
              
              if savePanel.runModal() == .OK, let url = savePanel.url {
                do {
                  try data.write(to: url)
                  print("Image saved to \(url)")
                } catch {
                  print("Failed to save image: \(error)")
                }
              }
            }
          }
          
          return nil
        }
      }
      
      if navigationAction.targetFrame == nil {
        if let requestURL = navigationAction.request.url {
          self.parent.browser.newTab(requestURL)
        }
      }
      return nil
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
      print("Load failed with error: \(error.localizedDescription)")
      parent.tab.pageProgress = webView.estimatedProgress
      if (error as NSError).code == NSURLErrorCancelled {
        return
      }
//      if let urlError = error as? URLError {
//        if let failingURL = urlError.userInfo[NSURLErrorFailingURLErrorKey] as? URL {
//          errorOriginURL = failingURL
//        }
//      }
      handleWebViewError(webView: webView, error: error)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
      print("didFail")
      parent.tab.pageProgress = webView.estimatedProgress
      if (error as NSError).code == NSURLErrorCancelled {
        return
      }
      
      handleWebViewError(webView: webView, error: error)
    }
    
    private func handleWebViewError(webView: WKWebView, error: Error) {
      let nsError = error as NSError
//      parent.tab.webviewCheckError = true
      parent.tab.webviewIsError = true
      print("handleWebViewError")
      print(nsError)
      switch nsError.code {
        //          case NSFileNoSuchFileError:
        //            // 파일을 찾을 수 없음
        //          case NSFileReadNoPermissionError:
        //            // 파일 읽기 권한 없음
        //          case NSFileReadCorruptFileError:
        //            // 손상된 파일
        case 104:
          parent.tab.webviewErrorType = .blockedContent
          if let schemeURL = URL(string:"opacity://blocked-content") {
            webView.load(URLRequest(url: schemeURL))
          }
          break
        case WebKitErrorFrameLoadInterruptedByPolicyChange:
          print("Frame load interrupted by policy change: \(error.localizedDescription)")
          break
        case NSURLErrorCannotFindHost:
          parent.tab.webviewErrorType = .notFindHost
          if let schemeURL = URL(string:"opacity://not-find-host") {
            webView.load(URLRequest(url: schemeURL))
          }
          break
        case NSURLErrorCannotConnectToHost:
          parent.tab.webviewErrorType = .notConnectHost
          if let schemeURL = URL(string:"opacity://not-connect-host") {
            webView.load(URLRequest(url: schemeURL))
          }
          break
        case NSURLErrorSecureConnectionFailed:
          parent.tab.webviewErrorType = .occurredSSLError
          if let schemeURL = URL(string:"opacity://occurred-ssl-error") {
            webView.load(URLRequest(url: schemeURL))
          }
          break
        case NSURLErrorServerCertificateHasBadDate:
          parent.tab.webviewErrorType = .occurredSSLError
          if let schemeURL = URL(string:"opacity://occurred-ssl-error") {
            webView.load(URLRequest(url: schemeURL))
          }
          break
        case NSURLErrorNotConnectedToInternet:
          parent.tab.webviewErrorType = .notConnectInternet
          if let schemeURL = URL(string:"opacity://not-connect-internet") {
            webView.load(URLRequest(url: schemeURL))
          }
          break
        default:
          parent.tab.webviewErrorType = .unknown
          if let schemeURL = URL(string:"opacity://unknown") {
            webView.load(URLRequest(url: schemeURL))
          }
      }
    }
    
    // alert
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
      let alert = NSAlert()
      alert.messageText = message
      alert.addButton(withTitle: "OK")
      alert.alertStyle = .warning
      alert.beginSheetModal(for: webView.window!) { _ in
        completionHandler()
      }
    }
    
    // confirm
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
      let alert = NSAlert()
      alert.messageText = message
      alert.addButton(withTitle: "OK")
      alert.addButton(withTitle: "Cancel")
      alert.alertStyle = .warning
      alert.beginSheetModal(for: webView.window!) { response in
        completionHandler(response == .alertFirstButtonReturn)
      }
    }
    
    // prompt
    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
      let alert = NSAlert()
      alert.messageText = prompt
      alert.addButton(withTitle: "OK")
      alert.addButton(withTitle: "Cancel")
      alert.alertStyle = .informational
      
      let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
      textField.stringValue = defaultText ?? ""
      alert.accessoryView = textField
      
      alert.beginSheetModal(for: webView.window!) { response in
        if response == .alertFirstButtonReturn {
          completionHandler(textField.stringValue)
        } else {
          completionHandler(nil)
        }
      }
    }
    
    // file upload
    func webView(_ webView: WKWebView, runOpenPanelWith parameters: WKOpenPanelParameters, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping ([URL]?) -> Void) {
      let openPanel = NSOpenPanel()
      openPanel.canChooseFiles = true
      openPanel.canChooseDirectories = false
      openPanel.allowsMultipleSelection = parameters.allowsMultipleSelection
      
      openPanel.beginSheetModal(for: webView.window!) { response in
        if response == .OK {
          completionHandler(openPanel.urls)
        } else {
          completionHandler(nil)
        }
      }
    }
    
    private func matchesDomain(pattern: String, host: String) -> Bool {
      if pattern == host {
        return true
      }
      if pattern.hasPrefix("*.") {
        let basePattern = pattern.dropFirst(2)
        let hostParts = host.split(separator: ".")
        let patternParts = basePattern.split(separator: ".")
        if hostParts.count == patternParts.count + 1 {
          return Array(hostParts.suffix(patternParts.count)) == patternParts
        }
      }
      return false
    }
    
    private func matchesHostCertificate(certificate: SecCertificate, host: String) throws -> String? {
      let data = SecCertificateCopyData(certificate) as Data
      let x509 = try X509Certificate(data: data)
      if let cn = x509.subjectDistinguishedName {
        print("host: \(host)")
        print("cn: \(cn)")
        print("list: \(x509.subjectAlternativeNames)")
        for pattern in x509.subjectAlternativeNames {
          if self.matchesDomain(pattern: pattern, host: host) {
            return cn
          }
        }
      }
      return nil
    }
    
    func checkedSSLCertificate(url: URL) {
      if url.scheme == "opacity" {
        return
      }
      
      currentURL = url
      
      DispatchQueue.main.async {
        self.parent.tab.certificateSummary = ""
        self.parent.tab.isValidCertificate = false
      }
      
      let config = URLSessionConfiguration.default
      config.requestCachePolicy = .reloadIgnoringLocalCacheData
      config.urlCache = nil
      let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
      let request = URLRequest(url: url)
      let task = session.dataTask(with: request) { data, response, error in
        guard error == nil else {
          print("Error: \(error!.localizedDescription)")
          return
        }
      }
      task.resume()
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
      if let serverTrust = challenge.protectionSpace.serverTrust, let host = currentURL?.host {
        var error: CFError?
        let isValid = SecTrustEvaluateWithError(serverTrust, &error)
        if isValid, let certificateChain = SecTrustCopyCertificateChain(serverTrust) as? [SecCertificate] {
          for certificate in certificateChain {
            if let _ = try? matchesHostCertificate(certificate: certificate, host: host) {
              let summary = SecCertificateCopySubjectSummary(certificate) as String? ?? "Unknown"
              certificateInfo[host] = summary
              DispatchQueue.main.async {
                self.parent.tab.certificateSummary = summary
                self.parent.tab.isValidCertificate = true
              }
            }
          }
          completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
          completionHandler(.cancelAuthenticationChallenge, nil)
        }
      }
    }
    
//    func load(url: URL, in webView: WKWebView) {
////      print("urlSession load start")
////      print("currentURL: \(currentURL)")
////      print("url: \(url)")
//      if let currentURL = currentURL, currentURL == url, isProgress {
//        print("동일한 URL로 진행중으로 load 실행하지 않음")
//        return
//      }
//      
//      if let currentURL = currentURL {
//        print("load - currentURL: \(currentURL)")
//        print("load - url: \(url)")
//        print("load - isProgress: \(isProgress)")
//        print("load - tabURL: \(self.parent.tab.originURL)")
//      }
//      
//      currentURL = url
//      isProgress = true
//      print("load - 1")
//      if url.scheme == "opacity" {
//        webView.load(URLRequest(url: url))
//        isProgress = false
//        return
//      }
//      
////      DispatchQueue.main.async {
////        self.parent.tab.originURL = url
////        self.parent.tab.updateURLByBrowser(url: url, isClearCertificate: false)
////      }
////      let config = URLSessionConfiguration.default
////      config.requestCachePolicy = .reloadIgnoringLocalCacheData
////      config.urlCache = nil
//      let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
//      let request = URLRequest(url: url)
//      let task = session.dataTask(with: request) { data, response, error in
//        guard error == nil, let response = response as? HTTPURLResponse, response.statusCode == 200 else {
//          print("url session error")
//          DispatchQueue.main.async {
//            self.parent.tab.webviewIsError = true
//            self.parent.tab.webviewErrorType = .occurredSSLError
//            if let schemeURL = URL(string:"opacity://occurred-ssl-error") {
//              webView.load(URLRequest(url: schemeURL))
//            }
//          }
//          self.isProgress = false
//          return
//        }
//        
//        DispatchQueue.main.async {
//          print("load - 2")
//          webView.load(request)
//          self.isProgress = false
//        }
//      }
//      task.resume()
//    }
//    
//    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
//      print("url sesison start")
//      
//      if let serverTrust = challenge.protectionSpace.serverTrust, let host = currentURL?.host {
//        var error: CFError?
//        let isValid = SecTrustEvaluateWithError(serverTrust, &error)
//        if isValid, let certificateChain = SecTrustCopyCertificateChain(serverTrust) as? [SecCertificate] {
//          for certificate in certificateChain {
//            if let _ = try? matchesHostCertificate(certificate: certificate, host: host) {
//              let summary = SecCertificateCopySubjectSummary(certificate) as String? ?? "Unknown"
//              certificateInfo[host] = summary
//              print("certificate - true - 1")
//              DispatchQueue.main.async {
//                print("certificate - true - 2")
//                self.parent.tab.certificateSummary = summary
//                self.parent.tab.isValidCertificate = true
//              }
//            } else {
//              print("certificate - true - 3")
//            }
//          }
//          
//          completionHandler(.useCredential, URLCredential(trust: serverTrust))
//        } else {
//          print("certificate - false - 1")
//          DispatchQueue.main.async {
//            print("certificate - false - 2")
//            self.parent.tab.certificateSummary = ""
//            self.parent.tab.isValidCertificate = false
//          }
//          completionHandler(.cancelAuthenticationChallenge, nil)
//        }
//      } else {
//        print("certificate - false - 11")
//        DispatchQueue.main.async {
//          print("certificate - false - 22")
//          self.parent.tab.certificateSummary = ""
//          self.parent.tab.isValidCertificate = false
//        }
//        completionHandler(.cancelAuthenticationChallenge, nil)
//      }
//    }
    
//    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
//    }
    
    
  // end coordinator
  }
    
  
  private func addContentBlockingRules(_ webView: WKWebView) {
    var blockingRules: String = "blockingLevel2Rules"
    if service.blockingLevel == BlockingTrakerList.blockingLight.rawValue {
      blockingRules = "blockingLevel1Rules"
    }
    if service.blockingLevel == BlockingTrakerList.blockingModerate.rawValue {
      blockingRules = "blockingLevel2Rules"
    }
    if service.blockingLevel == BlockingTrakerList.blockingStrong.rawValue {
      blockingRules = "blockingLevel3Rules"
    }
    
    if let rulePath = Bundle.main.path(forResource: blockingRules, ofType: "json"),
       let ruleString = try? String(contentsOfFile: rulePath) {
      WKContentRuleListStore.default().compileContentRuleList(forIdentifier: "ContentBlockingRules", encodedContentRuleList: ruleString) { ruleList, error in
        if let ruleList = ruleList {
          webView.configuration.userContentController.add(ruleList)
        } else if let error = error {
          print("Error compiling content rule list: \(error)")
        }
      }
    }
  }
  
  private func clearContentBlockingRules() {
    WKContentRuleListStore.default().getAvailableContentRuleListIdentifiers { identifiers in
      if ((identifiers?.contains("ContentBlockingRules")) != nil) {
        WKContentRuleListStore.default().removeContentRuleList(forIdentifier: "ContentBlockingRules") { error in
          if let error = error {
            print("Error removing content rule list: \(error)")
          } else {
            print("Remove blocking tracker")
          }
        }
      }
    }
  }
  
  private func updateBlockingRules(_ webView: WKWebView) {
    clearContentBlockingRules()
    if service.blockingLevel != BlockingTrakerList.blockingNone.rawValue {
      addContentBlockingRules(webView)
    }
  }
      
  func makeNSView(context: Context) -> WKWebView {
    tab.webview.navigationDelegate = context.coordinator
    tab.webview.uiDelegate = context.coordinator
    tab.webview.allowsBackForwardNavigationGestures = true
    tab.webview.isInspectable = true
    tab.webview.setValue(false, forKey: "drawsBackground")
    updateBlockingRules(tab.webview)
    
    return tab.webview
  }
  
  func updateNSView(_ webView: WKWebView, context: Context) {
    print("웹뷰 업데이트 시작")
    print("self.parent.tab.isValidCertificate: \(tab.isValidCertificate)")
    print("self.parent.tab.pageProgress: \(tab.pageProgress)")
    if !tab.findKeyword.isEmpty && tab.isFindAction {
      DispatchQueue.main.async {
        tab.isFindAction = false
        context.coordinator.searchWebView(webView, findText: tab.findKeyword, isPrev: tab.isFindPrev)
        return
      }
    }
    
    if !tab.isUpdateBySearch && tab.webviewIsError {
      print("업데이트가 아니며, 오류로 인한 업데이트 - 종료")
      return
    }
    
    guard let webviewURL = webView.url else {
      print("웹뷰의 url 없음 - 요청된 URL 로드")
      webView.load(URLRequest(url: tab.originURL))
      return
    }
    
    if !tab.isUpdateBySearch && webviewURL == tab.originURL {
      print("업데이트가 아니며 탭의 url과 웹뷰의 url이 같음 - 종료")
      return
    }
    
    if tab.isUpdateBySearch {
      print("새로운 검색으로 요청된 URL 로드")
      tab.isUpdateBySearch = false
      tab.webviewIsError = false
      webView.load(URLRequest(url: tab.originURL))
      return
    }
  }
}


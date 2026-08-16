import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let urlString: String
    let username: String
    let password: String

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        load(webView)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if uiView.url == nil {
            load(uiView)
        }
    }

    private func load(_ webView: WKWebView) {
        guard let url = URL(string: urlString) else { return }
        var request = URLRequest(url: url)
        let login = "\(username):\(password)"
        if let data = login.data(using: .utf8) {
            request.setValue("Basic \(data.base64EncodedString())", forHTTPHeaderField: "Authorization")
        }
        webView.load(request)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        let parent: WebView

        init(_ parent: WebView) {
            self.parent = parent
        }

        func webView(
            _ webView: WKWebView,
            didReceive challenge: URLAuthenticationChallenge,
            completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
        ) {
            let credential = URLCredential(
                user: parent.username,
                password: parent.password,
                persistence: .forSession
            )
            completionHandler(.useCredential, credential)
        }
    }
}

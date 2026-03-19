import SwiftUI
import WebKit

struct ContentView: View {
    var body: some View {
        CommandCenterWebView()
            .frame(minWidth: 1320, minHeight: 860)
            .preferredColorScheme(.dark)
    }
}

private struct CommandCenterWebView: NSViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.websiteDataStore = .default()

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.setValue(false, forKey: "drawsBackground")
        context.coordinator.webView = webView
        context.coordinator.loadIfNeeded()
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        context.coordinator.webView = webView
        context.coordinator.loadIfNeeded()
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        weak var webView: WKWebView?
        private var hasLoaded = false
        private let remoteURL = URL(string: "https://siribangeorge-cmd.github.io/bar-exam-2026-command-center/")
        private var localURL: URL? {
            let bundleRoot = Bundle.main.resourceURL
            let localIndex = bundleRoot?.appendingPathComponent("WebApp/index.html")
            guard let localIndex, FileManager.default.fileExists(atPath: localIndex.path) else {
                return nil
            }
            return localIndex
        }

        func loadIfNeeded() {
            guard !hasLoaded, let webView else { return }
            hasLoaded = true

            if let remoteURL {
                webView.load(URLRequest(url: remoteURL))
                return
            }

            loadLocalFallback()
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            loadLocalFallback()
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            loadLocalFallback()
        }

        private func loadLocalFallback() {
            guard let webView, let localURL else { return }
            webView.loadFileURL(localURL, allowingReadAccessTo: localURL.deletingLastPathComponent())
        }
    }
}

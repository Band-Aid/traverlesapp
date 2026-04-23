import SwiftUI
import WebKit

/// Presents jal.co.jp inside a WKWebView so the user can sign into JMB with
/// their own credentials. Nothing touches our servers — on "Pull my data" we
/// evaluate `document.body.innerText` locally and run the same parser the
/// OCR path uses. If JAL's DOM changes, the parser degrades gracefully.
struct JMBLoginSheet: View {
    let onResult: (JMBDraft) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var extractCount: Int = 0
    @State private var isExtracting: Bool = false
    @State private var errorText: String?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                JMBWebView(
                    url: Self.jmbLoginURL,
                    extractCount: extractCount,
                    onExtractedText: handleExtracted
                )
                .ignoresSafeArea(edges: .bottom)

                footer
            }
            .navigationTitle("Sign in to JAL")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        isExtracting = true
                        errorText = nil
                        extractCount += 1
                    } label: {
                        if isExtracting {
                            ProgressView().tint(JALTheme.crane)
                        } else {
                            Text("Pull my data").bold()
                        }
                    }
                    .disabled(isExtracting)
                }
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 6) {
            if let errorText {
                Text(errorText)
                    .font(.jal(12, .semibold))
                    .foregroundStyle(JALTheme.warning)
                    .multilineTextAlignment(.center)
            } else {
                Text("Log in, navigate to your JMB dashboard, then tap **Pull my data**.")
                    .font(.jal(11))
                    .foregroundStyle(JALTheme.inkSoft)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
    }

    private func handleExtracted(_ text: String) {
        isExtracting = false
        let lines = text.split(whereSeparator: \.isNewline).map(String.init)
        let draft = JMBTextParser.parse(lines)
        guard draft.miles != nil || draft.memberNumber != nil || draft.tier != nil else {
            errorText = "Couldn't read your details from this page. Navigate to the JMB dashboard and try again."
            return
        }
        onResult(draft)
        dismiss()
    }

    /// JAL's Japanese JMB portal entry. The user will be redirected to the
    /// login form if they're signed out. If you're testing outside Japan,
    /// JAL geo-redirects to the English portal automatically.
    private static let jmbLoginURL = URL(string: "https://www.jal.co.jp/jp/ja/jmb/")!
}

// MARK: - Web view

private struct JMBWebView: UIViewRepresentable {
    let url: URL
    let extractCount: Int
    let onExtractedText: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onExtractedText: onExtractedText)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()  // keep cookies across app launches
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.allowsBackForwardNavigationGestures = true
        webView.load(URLRequest(url: url))
        context.coordinator.webView = webView
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if extractCount > context.coordinator.lastExtractCount {
            context.coordinator.lastExtractCount = extractCount
            webView.evaluateJavaScript("document.body.innerText") { value, _ in
                let text = (value as? String) ?? ""
                DispatchQueue.main.async {
                    context.coordinator.onExtractedText(text)
                }
            }
        }
    }

    final class Coordinator {
        weak var webView: WKWebView?
        var lastExtractCount: Int = 0
        let onExtractedText: (String) -> Void
        init(onExtractedText: @escaping (String) -> Void) {
            self.onExtractedText = onExtractedText
        }
    }
}

#Preview {
    JMBLoginSheet { _ in }
}

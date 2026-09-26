import UIKit
import UniformTypeIdentifiers

/// Share extension, visible in the iOS share sheet as "保存到听书".
///
/// Extracts a BV id from the shared URL or text and stashes it in the shared
/// App Group container (`SharedStore.pendingShareBvId`). The main app picks it
/// up the next time it becomes active and offers to add it — no manual typing
/// of the BV id needed.
final class ShareViewController: UIViewController {
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .preferredFont(forTextStyle: .body)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private var didFinish = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        view.addSubview(statusLabel)
        NSLayoutConstraint.activate([
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            statusLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        extractAndSave()
    }

    // MARK: - Extraction

    private func extractAndSave() {
        guard let item = extensionContext?.inputItems.first as? NSExtensionItem,
              let attachments = item.attachments, !attachments.isEmpty else {
            return finish(message: "没有找到可分享的内容")
        }
        // Prefer URLs over plain text.
        let ordered = attachments.sorted { lhs, _ in
            lhs.hasItemConformingToTypeIdentifier(UTType.url.identifier)
        }
        tryNext(ordered)
    }

    private func tryNext(_ providers: [NSItemProvider]) {
        var remaining = providers
        guard !remaining.isEmpty else {
            return finish(message: "没有找到 BV 号")
        }
        let provider = remaining.removeFirst()
        if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] item, _ in
                let text = (item as? URL)?.absoluteString ?? (item as? String)
                self?.handle(text: text, remaining: remaining)
            }
        } else if provider.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { [weak self] item, _ in
                self?.handle(text: item as? String, remaining: remaining)
            }
        } else {
            tryNext(remaining)
        }
    }

    private func handle(text: String?, remaining: [NSItemProvider]) {
        if let bvId = text.flatMap(Self.extractBvId) {
            SharedStore.pendingShareBvId = bvId
            finish(message: "已保存 \(bvId)\n回到 App 即可添加")
        } else {
            tryNext(remaining)
        }
    }

    /// First "BV" + alphanumerics match, e.g. inside
    /// `https://www.bilibili.com/video/BV1xx411c7mD`.
    static func extractBvId(from text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: "BV[0-9A-Za-z]+"),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range, in: text) else { return nil }
        return String(text[range])
    }

    // MARK: - Completion

    private func finish(message: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self, !self.didFinish else { return }
            self.didFinish = true
            self.statusLabel.text = message
            // Brief confirmation, then dismiss back to the host app.
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
            }
        }
    }
}

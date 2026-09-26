import SwiftUI
import UIKit

/// Main screen: the saved-audiobook list with a prominent Play button per row.
///
/// Also hosts the three semi-automation flows, all triggered when the app
/// becomes active:
/// 1. Picks up BV ids saved by the Share extension (via the App Group container).
/// 2. Detects Bilibili URLs on the clipboard (pattern detection only — the iOS
///    paste-permission prompt appears solely when a URL is actually present).
/// 3. Offers to advance progress based on time spent in the Bilibili app.
struct ContentView: View {
    @EnvironmentObject private var store: ProgressStore
    @Environment(\.scenePhase) private var scenePhase

    @State private var showingAddForm = false
    @State private var prefillBvId: String?
    @State private var editingBook: BookProgress?
    @State private var clipboardBvId: String?
    @State private var returnPrompt: ReturnPrompt?
    @State private var lastPromptedClipboardBvId: String?

    /// Data for the "you were away, update progress?" alert.
    struct ReturnPrompt: Identifiable {
        let id = UUID()
        let book: BookProgress
        let elapsed: TimeInterval

        var newSeconds: Int { book.seconds + Int(elapsed) }

        var newFormattedTime: String {
            var copy = book
            copy.seconds = newSeconds
            return copy.formattedTime
        }

        var elapsedText: String {
            let minutes = Int(elapsed) / 60
            if minutes < 60 {
                return "\(minutes) 分钟"
            }
            return "\(minutes / 60) 小时 \(minutes % 60) 分钟"
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.books.isEmpty {
                    ContentUnavailableView(
                        "No Audiobooks Yet",
                        systemImage: "book.closed",
                        description: Text("Tap + to add your first Bilibili audiobook.")
                    )
                } else {
                    List {
                        ForEach(store.books) { book in
                            BookRowView(book: book) {
                                editingBook = book
                            }
                        }
                        .onDelete { store.delete(at: $0) }
                    }
                }
            }
            .navigationTitle("Bilibili Audiobooks")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingAddForm = true } label: {
                        Label("Add Audiobook", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddForm) {
                BookFormView(prefillBvId: prefillBvId) { draft in
                    store.add(draft)
                }
                .onDisappear { prefillBvId = nil }
            }
            .sheet(item: $editingBook) { book in
                BookFormView(bookToEdit: book) { draft in
                    store.update(draft)
                }
            }
            .alert("检测到剪贴板中的 B 站链接", isPresented: clipboardAlertBinding) {
                Button("添加") {
                    if let bvId = clipboardBvId {
                        prefillBvId = bvId
                        showingAddForm = true
                    }
                    clipboardBvId = nil
                }
                Button("忽略", role: .cancel) { clipboardBvId = nil }
            } message: {
                if let bvId = clipboardBvId {
                    Text("是否添加 \(bvId)？")
                }
            }
            .alert("更新播放进度？", isPresented: returnAlertBinding) {
                Button("更新") {
                    if let prompt = returnPrompt {
                        var updated = prompt.book
                        updated.seconds = prompt.newSeconds
                        store.update(updated)
                    }
                    returnPrompt = nil
                }
                Button("忽略", role: .cancel) { returnPrompt = nil }
            } message: {
                if let prompt = returnPrompt {
                    Text("你离开了 \(prompt.elapsedText)，是否把《\(prompt.book.title)》的进度从 \(prompt.book.formattedTime) 更新为 \(prompt.newFormattedTime)？")
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                guard newPhase == .active else { return }
                checkPendingShare()
                checkReturnSession()
                checkClipboard()
            }
        }
    }

    // MARK: - Alert bindings

    private var clipboardAlertBinding: Binding<Bool> {
        Binding(get: { clipboardBvId != nil }, set: { if !$0 { clipboardBvId = nil } })
    }

    private var returnAlertBinding: Binding<Bool> {
        Binding(get: { returnPrompt != nil }, set: { if !$0 { returnPrompt = nil } })
    }

    // MARK: - Semi-automation 1: Share extension handoff

    /// Picks up a BV id saved by the Share extension. If it is already in the
    /// library, opens it for editing; otherwise pre-fills the add form.
    private func checkPendingShare() {
        guard let bvId = SharedStore.pendingShareBvId, !bvId.isEmpty else { return }
        SharedStore.pendingShareBvId = nil // consume exactly once
        if let existing = store.books.first(where: { $0.normalizedBvId == bvId }) {
            editingBook = existing
        } else {
            prefillBvId = bvId
            showingAddForm = true
        }
    }

    // MARK: - Semi-automation 2: Clipboard detection

    /// Looks for a Bilibili URL on the clipboard. Pattern detection does not
    /// trigger the iOS paste-permission prompt; the prompt only appears when a
    /// URL pattern is actually found and the string is read.
    private func checkClipboard() {
        UIPasteboard.general.detectPatterns(for: [.probableWebURL]) { result in
            guard case .success(let patterns) = result,
                  patterns.contains(.probableWebURL),
                  let string = UIPasteboard.general.string,
                  let bvId = Self.extractBvId(from: string) else { return }
            DispatchQueue.main.async {
                let alreadySaved = self.store.books.contains {
                    $0.normalizedBvId.caseInsensitiveCompare(bvId) == .orderedSame
                }
                guard !alreadySaved, self.lastPromptedClipboardBvId != bvId else { return }
                self.lastPromptedClipboardBvId = bvId
                self.clipboardBvId = bvId
            }
        }
    }

    /// Extracts the first BV id ("BV" + alphanumerics) from arbitrary text.
    static func extractBvId(from text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: "BV[0-9A-Za-z]+"),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range, in: text) else { return nil }
        return String(text[range])
    }

    // MARK: - Semi-automation 3: Return-time progress estimation

    /// If the user opened the Bilibili app from a Play button and has been away
    /// for at least a minute, offers to advance that book's saved progress by
    /// the elapsed time.
    private func checkReturnSession() {
        guard let session = PlaySession.current else { return }
        PlaySession.clear() // consume exactly once
        let elapsed = Date().timeIntervalSince(session.date)
        guard elapsed >= 60,
              let book = store.books.first(where: { $0.id == session.bookId }) else { return }
        returnPrompt = ReturnPrompt(book: book, elapsed: elapsed)
    }
}

/// One row in the audiobook list: title, BV ID, page, progress, and Play button.
struct BookRowView: View {
    let book: BookProgress
    let onEdit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.headline)
                    .lineLimit(2)

                Text("\(book.normalizedBvId) · P\(book.page)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Progress: \(book.formattedTime)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                BilibiliLauncher.open(book: book)
            } label: {
                Label("Play", systemImage: "play.fill")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .accessibilityLabel("Play \(book.title)")
        }
        .swipeActions(edge: .trailing) {
            Button("Edit", systemImage: "pencil", action: onEdit)
                .tint(.blue)
        }
        .contextMenu {
            Button("Edit", systemImage: "pencil", action: onEdit)
        }
    }
}

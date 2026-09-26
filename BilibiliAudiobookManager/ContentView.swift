import SwiftUI

/// Main screen: the saved-audiobook list with a prominent Play button per row.
struct ContentView: View {
    @EnvironmentObject private var store: ProgressStore
    @State private var showingAddForm = false
    @State private var editingBook: BookProgress?

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
                BookFormView { draft in
                    store.add(draft)
                }
            }
            .sheet(item: $editingBook) { book in
                BookFormView(bookToEdit: book) { draft in
                    store.update(draft)
                }
            }
        }
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
                BilibiliLauncher.open(bvId: book.bvId, page: book.page, seconds: book.seconds)
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

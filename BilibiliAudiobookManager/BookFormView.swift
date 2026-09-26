import SwiftUI

/// Add / edit form for a `BookProgress` record.
///
/// Validates all fields before calling `onSave`:
/// - title and BV ID must be non-empty, BV ID must start with "BV"
/// - page must be an integer ≥ 1, seconds an integer ≥ 0
struct BookFormView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var bvId: String
    @State private var pageText: String
    @State private var secondsText: String
    @State private var errorMessage: String?

    private let bookToEdit: BookProgress?
    private let onSave: (BookProgress) -> Void

    init(bookToEdit: BookProgress? = nil, onSave: @escaping (BookProgress) -> Void) {
        self.bookToEdit = bookToEdit
        self.onSave = onSave
        // Pre-fill when editing; sensible defaults when adding.
        _title = State(initialValue: bookToEdit?.title ?? "")
        _bvId = State(initialValue: bookToEdit?.bvId ?? "")
        _pageText = State(initialValue: bookToEdit.map { String($0.page) } ?? "1")
        _secondsText = State(initialValue: bookToEdit.map { String($0.seconds) } ?? "0")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Audiobook") {
                    TextField("Title", text: $title)
                    TextField("BV ID (e.g. BV1xx411c7mD)", text: $bvId)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section("Progress") {
                    TextField("Page", text: $pageText)
                        .keyboardType(.numberPad)
                    TextField("Seconds", text: $secondsText)
                        .keyboardType(.numberPad)
                    Text("Tip: 90 seconds = 1:30. Page defaults to 1.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.callout)
                    }
                }
            }
            .navigationTitle(bookToEdit == nil ? "Add Audiobook" : "Edit Audiobook")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
        }
    }

    // MARK: - Validation & Save

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBvId = bvId.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty else {
            errorMessage = "Please enter a title."
            return
        }
        guard !trimmedBvId.isEmpty else {
            errorMessage = "Please enter a BV ID."
            return
        }
        guard trimmedBvId.uppercased().hasPrefix("BV") else {
            errorMessage = "BV ID should start with “BV” (e.g. BV1xx411c7mD)."
            return
        }
        guard let page = Int(pageText.trimmingCharacters(in: .whitespaces)), page >= 1 else {
            errorMessage = "Page must be a whole number of 1 or more."
            return
        }
        guard let seconds = Int(secondsText.trimmingCharacters(in: .whitespaces)), seconds >= 0 else {
            errorMessage = "Seconds must be a whole number of 0 or more."
            return
        }

        // Reuse the existing record's id when editing so the list updates in place.
        var draft = bookToEdit ?? BookProgress(title: "", bvId: "", seconds: 0)
        draft.title = trimmedTitle
        draft.bvId = trimmedBvId
        draft.page = page
        draft.seconds = seconds

        onSave(draft)
        dismiss()
    }
}

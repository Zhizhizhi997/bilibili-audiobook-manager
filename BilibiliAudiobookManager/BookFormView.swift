import SwiftUI

/// Add / edit form for a `BookProgress` entry.
///
/// Shows inline validation errors (empty title, BV id not starting with "BV",
/// page < 1, negative seconds). On save, passes the new or edited
/// `BookProgress` to `onSave` and dismisses.
struct BookFormView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var bvId: String
    @State private var pageText: String
    @State private var secondsText: String

    private let bookToEdit: BookProgress?
    private let onSave: (BookProgress) -> Void

    init(bookToEdit: BookProgress? = nil, prefillBvId: String? = nil, onSave: @escaping (BookProgress) -> Void) {
        self.bookToEdit = bookToEdit
        self.onSave = onSave
        // Pre-fill when editing; when adding, use the shared/clipboard BV id if provided.
        _title = State(initialValue: bookToEdit?.title ?? "")
        _bvId = State(initialValue: bookToEdit?.bvId ?? prefillBvId ?? "")
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

                Section("Position") {
                    TextField("Page (default 1)", text: $pageText)
                        .keyboardType(.numberPad)
                    TextField("Seconds", text: $secondsText)
                        .keyboardType(.numberPad)
                }

                if let error = validationError {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle(bookToEdit == nil ? "Add Audiobook" : "Edit Audiobook")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(validationError != nil)
                }
            }
        }
    }

    // MARK: - Validation

    /// Human-readable error, or `nil` when the form is valid.
    private var validationError: String? {
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Please enter a title."
        }
        let id = bvId.trimmingCharacters(in: .whitespacesAndNewlines)
        if id.isEmpty {
            return "Please enter a BV ID."
        }
        if !id.hasPrefix("BV") {
            return "BV ID must start with \"BV\"."
        }
        if let page = Int(pageText), page >= 1 {
            // valid
        } else {
            return "Page must be a number ≥ 1."
        }
        if let seconds = Int(secondsText), seconds >= 0 {
            // valid
        } else {
            return "Seconds must be a number ≥ 0."
        }
        return nil
    }

    // MARK: - Save

    private func save() {
        guard validationError == nil else { return }
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBvId = bvId.trimmingCharacters(in: .whitespacesAndNewlines)
        let page = Int(pageText) ?? 1
        let seconds = Int(secondsText) ?? 0

        if let existing = bookToEdit {
            var updated = existing
            updated.title = trimmedTitle
            updated.bvId = trimmedBvId
            updated.page = max(page, 1)
            updated.seconds = max(seconds, 0)
            onSave(updated)
        } else {
            onSave(BookProgress(
                title: trimmedTitle,
                bvId: trimmedBvId,
                page: max(page, 1),
                seconds: max(seconds, 0)
            ))
        }
        dismiss()
    }
}

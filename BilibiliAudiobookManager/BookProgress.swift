import Foundation

/// A single saved playback-progress record for a Bilibili audiobook / video.
///
/// Persisted as JSON in `UserDefaults` by `ProgressStore`.
struct BookProgress: Identifiable, Codable, Equatable {
    /// Stable identity used for list diffing and edit matching.
    var id: UUID = UUID()
    /// Display title, e.g. "三体 第二章".
    var title: String
    /// Bilibili video ID, e.g. "BV1xx411c7mD".
    var bvId: String
    /// Part number for multi-part videos. Defaults to 1.
    var page: Int = 1
    /// Playback position in seconds.
    var seconds: Int
    /// Last time this record was created or edited. Used for sorting.
    var lastUpdated: Date = Date()

    /// Human-readable playback position: "H:MM:SS" or "M:SS".
    var formattedTime: String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }

    /// BV ID with surrounding whitespace removed.
    var normalizedBvId: String {
        bvId.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

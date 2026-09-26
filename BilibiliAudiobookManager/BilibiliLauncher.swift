import UIKit

/// Builds Bilibili deep links and opens them, falling back to the web player
/// when the official Bilibili app is not installed.
///
/// - Important: `bilibili` must be listed under `LSApplicationQueriesSchemes`
///   in `Info.plist`, otherwise `canOpenURL` always returns `false` on iOS 9+
///   and every tap would fall through to the web player.
enum BilibiliLauncher {
    /// `bilibili://video/{bvId}?p={page}&t={seconds}` — opens the Bilibili app
    /// directly at the saved page and timestamp.
    static func appURL(bvId: String, page: Int, seconds: Int) -> URL? {
        var components = URLComponents()
        components.scheme = "bilibili"
        components.host = "video"
        components.path = "/\(bvId)"
        components.queryItems = [
            URLQueryItem(name: "p", value: String(max(page, 1))),
            URLQueryItem(name: "t", value: String(max(seconds, 0)))
        ]
        return components.url
    }

    /// `https://www.bilibili.com/video/{bvId}?p={page}&t={seconds}` — web fallback.
    static func webURL(bvId: String, page: Int, seconds: Int) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "www.bilibili.com"
        components.path = "/video/\(bvId)"
        components.queryItems = [
            URLQueryItem(name: "p", value: String(max(page, 1))),
            URLQueryItem(name: "t", value: String(max(seconds, 0)))
        ]
        return components.url
    }

    /// Opens the Bilibili app at the saved position if installed,
    /// otherwise opens the same position in the web player.
    static func open(bvId: String, page: Int, seconds: Int) {
        let id = bvId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !id.isEmpty else { return } // nothing to open

        if let appURL = appURL(bvId: id, page: page, seconds: seconds),
           UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL, options: [:], completionHandler: nil)
        } else if let webURL = webURL(bvId: id, page: page, seconds: seconds) {
            UIApplication.shared.open(webURL, options: [:], completionHandler: nil)
        }
    }
}

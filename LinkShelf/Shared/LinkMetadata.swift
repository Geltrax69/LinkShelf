import AppKit
import Foundation

/// Title and preview image for a URL. Shared by the app and the widget so a
/// link added from either side looks the same.
enum LinkMetadata {
    struct Result {
        var title: String?
        var image: Data?
    }

    static func fetch(for url: URL) async -> Result {
        var result = Result()

        // YouTube serves scripted HTML with no useful <title>, but it does
        // publish oEmbed, and its stills are at a predictable address.
        if let still = Thumbnails.youTubeImageURL(for: url) {
            result.image = await downloadImage(still)
            if let encoded = url.absoluteString.addingPercentEncoding(withAllowedCharacters: .alphanumerics),
               let oembed = URL(string: "https://www.youtube.com/oembed?format=json&url=\(encoded)"),
               let (data, _) = try? await URLSession.shared.data(from: oembed),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let title = json["title"] as? String {
                result.title = String(title.prefix(120))
                return result
            }
        }

        var request = URLRequest(url: url, timeoutInterval: 10)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15",
                         forHTTPHeaderField: "User-Agent")
        guard let (data, _) = try? await URLSession.shared.data(for: request),
              // A byte-count prefix can split a UTF-8 sequence; latin1 never fails.
              let html = String(data: data.prefix(262_144), encoding: .utf8)
                ?? String(data: data.prefix(262_144), encoding: .isoLatin1) else { return result }

        if let title = firstMatch(in: html, pattern: "<title[^>]*>(.*?)</title>")
            ?? firstMatch(in: html, pattern: "<meta[^>]+property=[\"']og:title[\"'][^>]+content=[\"']([^\"']+)") {
            result.title = String(decodeEntities(title).prefix(120))
        }
        guard result.image == nil,
              let image = firstMatch(in: html, pattern: "<meta[^>]+(?:property|name)=[\"']og:image[\"'][^>]+content=[\"']([^\"']+)")
                ?? firstMatch(in: html, pattern: "<meta[^>]+content=[\"']([^\"']+)[\"'][^>]+(?:property|name)=[\"']og:image[\"']"),
              let imageURL = URL(string: decodeEntities(image), relativeTo: url) else { return result }
        result.image = await downloadImage(imageURL)
        return result
    }

    private static func downloadImage(_ source: URL) async -> Data? {
        guard let (data, response) = try? await URLSession.shared.data(from: source),
              (response as? HTTPURLResponse)?.statusCode == 200, data.count > 1_000 else { return nil }
        return downsampled(data)
    }

    /// WidgetKit archives its views, and a full-size photo comes back blank in
    /// the widget. Store a small JPEG instead — it is all either surface shows.
    static func downsampled(_ data: Data, maxWidth: CGFloat = 480) -> Data? {
        guard let source = NSBitmapImageRep(data: data) else { return nil }
        let width = CGFloat(source.pixelsWide), height = CGFloat(source.pixelsHigh)
        guard width > 0, height > 0 else { return nil }
        let scale = min(1, maxWidth / width)
        let size = NSSize(width: (width * scale).rounded(), height: (height * scale).rounded())
        let target = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size.width), pixelsHigh: Int(size.height),
                                      bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                      colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)
        guard let target else { return nil }
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: target)
        source.draw(in: NSRect(origin: .zero, size: size))
        NSGraphicsContext.restoreGraphicsState()
        return target.representation(using: .jpeg, properties: [.compressionFactor: 0.8])
    }

    private static func firstMatch(in text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text) else { return nil }
        let value = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    private static func decodeEntities(_ text: String) -> String {
        text.replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
    }
}

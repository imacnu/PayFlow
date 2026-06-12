import Foundation
import SubscriptionGuardianCore

/// Plantilla de un servicio conocido para alta rápida de suscripciones.
/// Al no disponer de iconos oficiales de marca, cada servicio combina un
/// símbolo SF, un color de marca y un monograma de respaldo.
/// El precio lo introduce siempre el usuario manualmente: los importes de
/// los servicios cambian con frecuencia y precargarlos induce a error.
struct ServiceTemplate: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let category: ServiceCategory
    let symbol: String?
    let monogram: String
    let colorHex: String
}

enum ServiceCatalog {
    static let all: [ServiceTemplate] = [
        ServiceTemplate(id: "netflix", name: "Netflix", category: .streaming,
                        symbol: "play.tv.fill", monogram: "N", colorHex: "E50914"),
        ServiceTemplate(id: "spotify", name: "Spotify", category: .music,
                        symbol: "music.note", monogram: "S", colorHex: "1DB954"),
        ServiceTemplate(id: "youtube-premium", name: "YouTube Premium", category: .streaming,
                        symbol: "play.rectangle.fill", monogram: "YT", colorHex: "FF0000"),
        ServiceTemplate(id: "disney-plus", name: "Disney+", category: .streaming,
                        symbol: "sparkles.tv.fill", monogram: "D+", colorHex: "0E47BA"),
        ServiceTemplate(id: "max", name: "Max", category: .streaming,
                        symbol: "tv.fill", monogram: "M", colorHex: "2A2BD3"),
        ServiceTemplate(id: "prime-video", name: "Prime Video", category: .streaming,
                        symbol: "play.circle.fill", monogram: "PV", colorHex: "00A8E1"),
        ServiceTemplate(id: "chatgpt", name: "ChatGPT", category: .ai,
                        symbol: "bubble.left.and.text.bubble.right.fill", monogram: "GPT", colorHex: "10A37F"),
        ServiceTemplate(id: "claude", name: "Claude", category: .ai,
                        symbol: "sparkle", monogram: "C", colorHex: "D97757"),
        ServiceTemplate(id: "cursor", name: "Cursor", category: .ai,
                        symbol: "cursorarrow.rays", monogram: "Cu", colorHex: "1C1F26"),
        ServiceTemplate(id: "github-copilot", name: "GitHub Copilot", category: .ai,
                        symbol: "chevron.left.forwardslash.chevron.right", monogram: "GH", colorHex: "24292F"),
        ServiceTemplate(id: "dropbox", name: "Dropbox", category: .productivity,
                        symbol: "shippingbox.fill", monogram: "Db", colorHex: "0061FF"),
        ServiceTemplate(id: "notion", name: "Notion", category: .productivity,
                        symbol: "doc.text.fill", monogram: "N", colorHex: "1C1F26"),
        ServiceTemplate(id: "figma", name: "Figma", category: .productivity,
                        symbol: "paintpalette.fill", monogram: "F", colorHex: "A259FF"),
        ServiceTemplate(id: "apple-one", name: "Apple One", category: .productivity,
                        symbol: "apple.logo", monogram: "", colorHex: "1C1F26")
    ]

    static func template(id: String) -> ServiceTemplate? {
        all.first { $0.id == id }
    }
}

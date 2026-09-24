import SwiftUI

/// Stellt die leichtgewichtige Auszeichnung aus content.json dar:
/// Absätze (Leerzeile), Aufzählungen („• “), nummerierte Listen („1. “) und **fett**.
struct RichText: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(zeilen.enumerated()), id: \.offset) { _, zeile in
                zeileView(zeile)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var zeilen: [String] {
        text.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    @ViewBuilder
    private func zeileView(_ zeile: String) -> some View {
        if zeile.hasPrefix("• ") {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("•").foregroundStyle(.tint)
                Text(Self.markdown(String(zeile.dropFirst(2))))
            }
        } else if let nummer = Self.listenNummer(zeile) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(nummer).monospacedDigit().foregroundStyle(.tint).bold()
                Text(Self.markdown(String(zeile.dropFirst(nummer.count + 1))))
            }
        } else {
            Text(Self.markdown(zeile))
        }
    }

    private static func listenNummer(_ zeile: String) -> String? {
        let ziffern = zeile.prefix { $0.isNumber }
        guard !ziffern.isEmpty, zeile.dropFirst(ziffern.count).hasPrefix(". ") else { return nil }
        return String(ziffern) + "."
    }

    static func markdown(_ s: String) -> AttributedString {
        (try? AttributedString(markdown: s, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)))
            ?? AttributedString(s)
    }
}

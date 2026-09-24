import SwiftUI
import UIKit

// MARK: - Farben & Verläufe

enum Stil {
    static let tiefgruen = Color(red: 0.00, green: 0.24, blue: 0.21)
    static let gruen = Color(red: 0.00, green: 0.42, blue: 0.36)
    static let mint = Color(red: 0.38, green: 0.78, blue: 0.69)
    static let bernstein = Color(red: 1.00, green: 0.74, blue: 0.28)
    static let koralle = Color(red: 1.00, green: 0.36, blue: 0.37)

    /// Kachelfarben – ruhig, aber klar unterscheidbar.
    static let palette: [Color] = [
        Color(red: 0.00, green: 0.55, blue: 0.47),
        Color(red: 0.35, green: 0.34, blue: 0.84),
        Color(red: 1.00, green: 0.45, blue: 0.35),
        Color(red: 0.96, green: 0.62, blue: 0.10),
        Color(red: 0.16, green: 0.50, blue: 0.93),
        Color(red: 0.62, green: 0.32, blue: 0.86),
        Color(red: 0.90, green: 0.30, blue: 0.55),
        Color(red: 0.20, green: 0.66, blue: 0.80),
    ]

    static func farbe(_ index: Int) -> Color { palette[abs(index) % palette.count] }

    static let akzentVerlauf = LinearGradient(colors: [gruen, tiefgruen], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let heroVerlauf = LinearGradient(
        colors: [Color(red: 0.02, green: 0.36, blue: 0.31), tiefgruen, Color(red: 0.03, green: 0.14, blue: 0.16)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}

enum Haptik {
    static func tippen() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func erfolg() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func warnung() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
}

// MARK: - Hintergrund

/// Ruhiger, leicht farbiger Hintergrund, auf dem die Glasflächen wirken.
struct AppHintergrund: View {
    @Environment(\.colorScheme) private var schema

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
            Circle()
                .fill(Stil.mint.opacity(schema == .dark ? 0.22 : 0.30))
                .frame(width: 420, height: 420)
                .blur(radius: 110)
                .offset(x: -150, y: -300)
            Circle()
                .fill(Stil.bernstein.opacity(schema == .dark ? 0.10 : 0.18))
                .frame(width: 360, height: 360)
                .blur(radius: 120)
                .offset(x: 170, y: 160)
            Circle()
                .fill(Stil.palette[1].opacity(schema == .dark ? 0.14 : 0.12))
                .frame(width: 300, height: 300)
                .blur(radius: 120)
                .offset(x: -120, y: 460)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Glas

struct Glas: ViewModifier {
    var radius: CGFloat
    var interaktiv: Bool

    func body(content: Content) -> some View {
        let form = RoundedRectangle(cornerRadius: radius, style: .continuous)
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            content.glassEffect(interaktiv ? .regular.interactive() : .regular, in: form)
        } else {
            ersatz(content, form)
        }
        #else
        ersatz(content, form)
        #endif
    }

    private func ersatz(_ content: Content, _ form: RoundedRectangle) -> some View {
        content
            .background(.ultraThinMaterial, in: form)
            .overlay(form.strokeBorder(Color.white.opacity(0.35), lineWidth: 0.8).blendMode(.overlay))
            .overlay(form.strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5))
            .shadow(color: Color.black.opacity(0.08), radius: 18, x: 0, y: 10)
    }
}

extension View {
    /// Liquid-Glass-Fläche (iOS 26) bzw. Material mit feinem Rand darunter.
    func glas(_ radius: CGFloat = 24, interaktiv: Bool = false) -> some View {
        modifier(Glas(radius: radius, interaktiv: interaktiv))
    }

    /// Sanftes Ein- und Ausblenden beim Scrollen (ab iOS 17).
    @ViewBuilder func scrollEinblenden() -> some View {
        if #available(iOS 17.0, *) {
            scrollTransition(.interactive, axis: .vertical) { inhalt, phase in
                inhalt
                    .opacity(phase.isIdentity ? 1 : 0.55)
                    .scaleEffect(phase.isIdentity ? 1 : 0.94)
            }
        } else {
            self
        }
    }

    /// Quelle für den Zoom-Übergang (ab iOS 18).
    @ViewBuilder func zoomQuelle(_ id: String, in namespace: Namespace.ID) -> some View {
        if #available(iOS 18.0, *) {
            matchedTransitionSource(id: id, in: namespace)
        } else {
            self
        }
    }

    /// Ziel des Zoom-Übergangs (ab iOS 18).
    @ViewBuilder func zoomZiel(_ id: String, in namespace: Namespace.ID) -> some View {
        if #available(iOS 18.0, *) {
            navigationTransition(.zoom(sourceID: id, in: namespace))
        } else {
            self
        }
    }

    /// Standard-Seitenlayout: farbiger Hintergrund hinter scrollbaren Inhalten.
    func seitenHintergrund() -> some View {
        background(AppHintergrund())
    }
}

// MARK: - Knöpfe

/// Weiches Eindrücken mit Feder-Animation.
struct DrueckStil: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.965 : 1)
            .brightness(configuration.isPressed ? -0.03 : 0)
            .animation(.spring(response: 0.28, dampingFraction: 0.62), value: configuration.isPressed)
    }
}

/// Großer Hauptknopf mit Verlauf (Airbnb-artig).
struct PrimaerStil: ButtonStyle {
    var farbe: Color = Stil.gruen

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(LinearGradient(colors: [farbe, farbe.opacity(0.78)], startPoint: .topLeading, endPoint: .bottomTrailing))
            )
            .shadow(color: farbe.opacity(0.35), radius: configuration.isPressed ? 4 : 14, y: configuration.isPressed ? 2 : 8)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.62), value: configuration.isPressed)
    }
}

/// Zweitrangiger Knopf auf Glas.
struct GlasKnopfStil: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .glas(18, interaktiv: true)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.62), value: configuration.isPressed)
    }
}

// MARK: - Logo

struct SchildForm: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY + r.height * 0.15))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY + r.height * 0.48))
        p.addQuadCurve(to: CGPoint(x: r.midX, y: r.maxY), control: CGPoint(x: r.maxX, y: r.minY + r.height * 0.86))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.minY + r.height * 0.48), control: CGPoint(x: r.minX, y: r.minY + r.height * 0.86))
        p.addLine(to: CGPoint(x: r.minX, y: r.minY + r.height * 0.15))
        p.closeSubpath()
        return p
    }
}

/// Wortbildmarke: Schild mit Sternenkreis und Paragraph – ohne Glanz-/KI-Symbolik.
struct Emblem: View {
    var groesse: CGFloat = 72
    var sternFarbe: Color = Stil.bernstein

    var body: some View {
        ZStack {
            SchildForm()
                .fill(LinearGradient(colors: [Color.white.opacity(0.28), Color.white.opacity(0.08)], startPoint: .top, endPoint: .bottom))
            SchildForm()
                .stroke(Color.white, style: StrokeStyle(lineWidth: groesse * 0.045, lineJoin: .round))
            ForEach(0..<12, id: \.self) { i in
                Circle()
                    .fill(sternFarbe)
                    .frame(width: groesse * 0.065, height: groesse * 0.065)
                    .offset(y: -groesse * 0.235)
                    .rotationEffect(.degrees(Double(i) * 30))
            }
            .offset(y: -groesse * 0.02)
            Text("§")
                .font(.system(size: groesse * 0.27, weight: .semibold, design: .serif))
                .foregroundStyle(.white)
                .offset(y: -groesse * 0.02)
        }
        .frame(width: groesse, height: groesse * 1.12)
        .accessibilityHidden(true)
    }
}

// MARK: - Parallax-Kopfbereich

/// Kopfbereich, der beim Herunterziehen wächst und beim Scrollen langsamer mitläuft.
/// Voraussetzung: umgebender ScrollView mit `.coordinateSpace(name: "scroll")`.
struct ParallaxHero<Inhalt: View>: View {
    var hoehe: CGFloat = 300
    var verlauf: LinearGradient = Stil.heroVerlauf
    @ViewBuilder var inhalt: () -> Inhalt

    var body: some View {
        GeometryReader { geo in
            let y: CGFloat = geo.frame(in: .named("scroll")).minY
            ZStack(alignment: .bottomLeading) {
                verlauf
                // Dekorative Kreise, bewegen sich gegenläufig
                Circle()
                    .stroke(Color.white.opacity(0.10), lineWidth: 40)
                    .frame(width: 320, height: 320)
                    .offset(x: geo.size.width * 0.55, y: -150 + y * 0.25)
                Circle()
                    .fill(Stil.mint.opacity(0.18))
                    .frame(width: 220, height: 220)
                    .blur(radius: 50)
                    .offset(x: -60, y: -40 - y * 0.15)
                inhalt()
                    .padding(.horizontal, 24)
                    .padding(.bottom, 44)
                    .offset(y: y < 0 ? y * 0.25 : 0)
                    .opacity(y < 0 ? Double(max(0, 1 + y / (hoehe * 0.7))) : 1)
            }
            .frame(width: geo.size.width, height: hoehe + max(0, y))
            .clipped()
            .offset(y: y > 0 ? -y : -y * 0.45)
        }
        .frame(height: hoehe)
    }
}

// MARK: - Kacheln

struct IconPlakette: View {
    let icon: String
    let farbe: Color
    var groesse: CGFloat = 44

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: groesse * 0.44, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: groesse, height: groesse)
            .background(
                RoundedRectangle(cornerRadius: groesse * 0.3, style: .continuous)
                    .fill(LinearGradient(colors: [farbe, farbe.opacity(0.72)], startPoint: .topLeading, endPoint: .bottomTrailing))
            )
            .shadow(color: farbe.opacity(0.35), radius: 6, y: 3)
    }
}

struct Kachel: View {
    let titel: String
    var untertitel: String?
    let icon: String
    let farbe: Color
    var plakette: String?
    var hoehe: CGFloat = 132

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                IconPlakette(icon: icon, farbe: farbe)
                Spacer(minLength: 4)
                if let plakette {
                    Text(plakette)
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(farbe.opacity(0.16)))
                        .foregroundStyle(farbe)
                }
            }
            Spacer(minLength: 0)
            Text(titel)
                .font(.headline)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            if let untertitel {
                Text(untertitel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: hoehe, alignment: .topLeading)
        .glas(24, interaktiv: true)
        .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

/// Breite Zeilen-Kachel (Icon links, Text, Chevron).
struct ZeilenKachel: View {
    let titel: String
    var untertitel: String?
    let icon: String
    let farbe: Color
    var rechts: String?

    var body: some View {
        HStack(spacing: 14) {
            IconPlakette(icon: icon, farbe: farbe, groesse: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(titel).font(.headline).foregroundStyle(.primary).multilineTextAlignment(.leading)
                if let untertitel {
                    Text(untertitel).font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.leading).lineLimit(2)
                }
            }
            Spacer(minLength: 4)
            if let rechts {
                Text(rechts).font(.caption.monospacedDigit().weight(.semibold)).foregroundStyle(.secondary)
            }
            Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(.tertiary)
        }
        .padding(14)
        .glas(20, interaktiv: true)
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

struct Abschnittstitel: View {
    let text: String
    var zusatz: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(text).font(.title2.bold())
            Spacer()
            if let zusatz {
                Text(zusatz).font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .padding(.top, 8)
    }
}

// MARK: - Fortschritt

struct Fortschrittsbalken: View {
    let wert: Double
    var farbe: Color = Stil.gruen

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.primary.opacity(0.08))
                Capsule()
                    .fill(LinearGradient(colors: [Stil.mint, farbe], startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(8, geo.size.width * min(max(wert, 0), 1)))
            }
        }
        .frame(height: 8)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: wert)
        .accessibilityElement()
        .accessibilityLabel("Fortschritt \(Int(wert * 100)) Prozent")
    }
}

// MARK: - Eingabe

/// Textfeld mit schwebender Beschriftung und animiertem Fokusrand.
/// Mehrzeilige Felder zeigen die (oft lange) Beschriftung fest oberhalb, damit nichts überlappt.
struct SchwebeFeld: View {
    let label: String
    @Binding var text: String
    var platzhalter: String?
    var mehrzeilig = false
    var pflicht = false
    var hinweis: String?

    @FocusState private var fokus: Bool

    private var oben: Bool { mehrzeilig || fokus || !text.isEmpty }

    private var beschriftung: some View {
        HStack(spacing: 6) {
            Text(label)
                .lineLimit(mehrzeilig ? 3 : 1)
                .minimumScaleFactor(0.75)
                .fixedSize(horizontal: false, vertical: mehrzeilig)
            if pflicht {
                Text("Pflicht")
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill((text.isEmpty ? Stil.koralle : Stil.gruen).opacity(0.15)))
                    .foregroundStyle(text.isEmpty ? Stil.koralle : Stil.gruen)
                    .fixedSize()
            }
        }
        .font(oben ? .caption.weight(.semibold) : .body)
        .foregroundStyle(fokus ? Color.accentColor : Color.secondary)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Group {
                if mehrzeilig {
                    VStack(alignment: .leading, spacing: 8) {
                        beschriftung
                        TextField("", text: $text, prompt: Text(platzhalter ?? ""), axis: .vertical)
                            .lineLimit(2...8)
                            .focused($fokus)
                            .accessibilityLabel(label)
                    }
                } else {
                    ZStack(alignment: .topLeading) {
                        beschriftung
                            .offset(y: oben ? 0 : 13)
                            .allowsHitTesting(false)
                        TextField("", text: $text, prompt: oben ? Text(platzhalter ?? "") : nil)
                            .focused($fokus)
                            .padding(.top, 21)
                            .accessibilityLabel(label)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 66, alignment: .topLeading)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.ultraThinMaterial))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(fokus ? Color.accentColor : Color.primary.opacity(0.12), lineWidth: fokus ? 2 : 1)
            )
            .shadow(color: fokus ? Color.accentColor.opacity(0.18) : .clear, radius: 10, y: 4)
            .contentShape(Rectangle())
            .onTapGesture { fokus = true }

            if let hinweis {
                Label(hinweis, systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.82), value: oben)
        .animation(.easeOut(duration: 0.2), value: fokus)
    }
}

/// Auswahl-Chip mit Feder-Animation.
struct Chip: View {
    let text: String
    let gewaehlt: Bool
    let aktion: () -> Void

    var body: some View {
        Button {
            Haptik.tippen()
            withAnimation(.spring(response: 0.32, dampingFraction: 0.7)) { aktion() }
        } label: {
            HStack(spacing: 6) {
                if gewaehlt {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .transition(.scale.combined(with: .opacity))
                }
                Text(text)
                    .font(.subheadline.weight(.medium))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .foregroundStyle(gewaehlt ? Color.white : Color.primary)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(gewaehlt ? AnyShapeStyle(Stil.akzentVerlauf) : AnyShapeStyle(.ultraThinMaterial))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(gewaehlt ? Color.clear : Color.primary.opacity(0.14))
            )
            .shadow(color: gewaehlt ? Stil.gruen.opacity(0.3) : .clear, radius: 8, y: 4)
        }
        .buttonStyle(DrueckStil())
        .accessibilityAddTraits(gewaehlt ? .isSelected : [])
    }
}

/// Einfaches Fließlayout für Chips (Zeilenumbruch bei Platzmangel).
struct FlussLayout: Layout {
    var abstand: CGFloat = 8

    private func groesse(_ v: LayoutSubview, maxBreite: CGFloat) -> CGSize {
        let ideal = v.sizeThatFits(.unspecified)
        return ideal.width > maxBreite ? v.sizeThatFits(ProposedViewSize(width: maxBreite, height: nil)) : ideal
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let breite = proposal.width ?? 360
        var x: CGFloat = 0, y: CGFloat = 0, zeile: CGFloat = 0
        for v in subviews {
            let s = groesse(v, maxBreite: breite)
            if x > 0, x + s.width > breite { x = 0; y += zeile + abstand; zeile = 0 }
            x += s.width + abstand
            zeile = max(zeile, s.height)
        }
        return CGSize(width: breite, height: y + zeile)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, zeile: CGFloat = 0
        for v in subviews {
            let s = groesse(v, maxBreite: bounds.width)
            if x > bounds.minX, x + s.width > bounds.maxX { x = bounds.minX; y += zeile + abstand; zeile = 0 }
            v.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(s))
            x += s.width + abstand
            zeile = max(zeile, s.height)
        }
    }
}

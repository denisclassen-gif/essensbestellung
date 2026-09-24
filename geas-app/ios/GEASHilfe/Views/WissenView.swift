import SwiftUI

struct WissenView: View {
    @Environment(\.appContent) private var content
    @EnvironmentObject private var progress: ProgressStore
    @Namespace private var zoom

    private let spalten = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    ParallaxHero(hoehe: 260, verlauf: LinearGradient(
                        colors: [Stil.farbe(1), Color(red: 0.14, green: 0.12, blue: 0.40)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )) {
                        VStack(alignment: .leading, spacing: 8) {
                            Image(systemName: "books.vertical.fill")
                                .font(.system(size: 36, weight: .semibold))
                                .foregroundStyle(.white)
                            Text("Wissen")
                                .font(.system(size: 38, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            Text("\(progress.anzahlGelesen) von \(content.kapitel.count) Kapiteln gelesen")
                                .foregroundStyle(.white.opacity(0.85))
                        }
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        NavigationLink {
                            SucheView()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "magnifyingglass").font(.headline)
                                Text("Begriff, Paragraph, Thema suchen …").foregroundStyle(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 16)
                            .glas(22, interaktiv: true)
                        }
                        .buttonStyle(DrueckStil())

                        Abschnittstitel(text: "Kapitel")
                        LazyVGrid(columns: spalten, spacing: 14) {
                            ForEach(Array(content.kapitel.enumerated()), id: \.element.id) { index, kapitel in
                                NavigationLink(value: kapitel) {
                                    Kachel(
                                        titel: kapitel.titel,
                                        untertitel: kapitel.kurz,
                                        icon: kapitel.icon,
                                        farbe: Stil.farbe(index),
                                        plakette: progress.istGelesen(kapitel) ? "✓" : nil,
                                        hoehe: 170
                                    )
                                }
                                .buttonStyle(DrueckStil())
                                .zoomQuelle(kapitel.id, in: zoom)
                                .scrollEinblenden()
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, -28)
                    .padding(.bottom, 30)
                }
            }
            .coordinateSpace(name: "scroll")
            .ignoresSafeArea(edges: .top)
            .seitenHintergrund()
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Kapitel.self) { kapitel in
                KapitelDetailView(kapitel: kapitel)
                    .zoomZiel(kapitel.id, in: zoom)
            }
        }
    }
}

struct KapitelZeile: View {
    let kapitel: Kapitel
    let gelesen: Bool

    var body: some View {
        HStack(spacing: 14) {
            IconPlakette(icon: kapitel.icon, farbe: Stil.gruen, groesse: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(kapitel.titel).font(.headline)
                Text(kapitel.kurz).font(.caption).foregroundStyle(.secondary).lineLimit(2)
            }
            Spacer(minLength: 0)
            if gelesen {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(Stil.gruen)
                    .accessibilityLabel("gelesen")
            }
        }
        .padding(.vertical, 4)
    }
}

struct KapitelDetailView: View {
    let kapitel: Kapitel
    @Environment(\.appContent) private var content
    @EnvironmentObject private var progress: ProgressStore

    private var fragen: [QuizFrage] { content.quiz.filter { $0.kapitel == kapitel.id } }
    private var farbe: Color { Stil.farbe(content.kapitel.firstIndex(of: kapitel) ?? 0) }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ParallaxHero(hoehe: 250, verlauf: LinearGradient(
                    colors: [farbe, farbe.opacity(0.65), Stil.tiefgruen],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )) {
                    VStack(alignment: .leading, spacing: 10) {
                        Image(systemName: kapitel.icon)
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundStyle(.white)
                        Text(kapitel.titel)
                            .font(.system(.largeTitle, design: .rounded).weight(.bold))
                            .foregroundStyle(.white)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(kapitel.kurz)
                            .foregroundStyle(.white.opacity(0.88))
                    }
                }

                VStack(alignment: .leading, spacing: 16) {
                    ForEach(kapitel.abschnitte, id: \.self) { abschnitt in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(abschnitt.titel).font(.title3.bold())
                            RichText(text: abschnitt.text)
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .glas(24)
                        .scrollEinblenden()
                    }

                    if !kapitel.merke.isEmpty {
                        MerkeBox(punkte: kapitel.merke)
                    }

                    if !fragen.isEmpty {
                        NavigationLink {
                            QuizView(fragen: fragen, titel: kapitel.titel)
                        } label: {
                            Label("\(fragen.count) Quizfragen zu diesem Kapitel", systemImage: "questionmark.circle.fill")
                        }
                        .buttonStyle(PrimaerStil(farbe: farbe))
                    }

                    Toggle(isOn: Binding(
                        get: { progress.istGelesen(kapitel) },
                        set: { neu in
                            Haptik.tippen()
                            withAnimation { progress.setGelesen(kapitel, neu) }
                        }
                    )) {
                        Label("Als gelesen markieren", systemImage: "checkmark.circle")
                    }
                    .tint(Stil.gruen)
                    .padding(16)
                    .glas(20)
                }
                .padding(.horizontal, 20)
                .padding(.top, -28)
                .padding(.bottom, 30)
            }
        }
        .coordinateSpace(name: "scroll")
        .ignoresSafeArea(edges: .top)
        .seitenHintergrund()
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct MerkeBox: View {
    let punkte: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Merke", systemImage: "lightbulb.fill")
                .font(.headline)
                .foregroundStyle(Stil.farbe(3))
            ForEach(punkte, id: \.self) { punkt in
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Image(systemName: "checkmark").font(.caption.bold()).foregroundStyle(Stil.farbe(3))
                    Text(RichText.markdown(punkt))
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Stil.bernstein.opacity(0.14)))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(Stil.bernstein.opacity(0.35)))
    }
}

import SwiftUI

struct WissenView: View {
    @Environment(\.appContent) private var content
    @EnvironmentObject private var progress: ProgressStore

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(content.meta.untertitel)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        ProgressView(value: Double(progress.anzahlGelesen), total: Double(max(content.kapitel.count, 1)))
                        Text("\(progress.anzahlGelesen) von \(content.kapitel.count) Kapiteln gelesen · Stand \(content.meta.stand)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    NavigationLink {
                        SucheView()
                    } label: {
                        Label("Suche & Glossar", systemImage: "magnifyingglass")
                    }
                }

                Section("Kapitel") {
                    ForEach(content.kapitel) { kapitel in
                        NavigationLink(value: kapitel) {
                            KapitelZeile(kapitel: kapitel, gelesen: progress.istGelesen(kapitel))
                        }
                    }
                }
            }
            .navigationTitle("Wissen")
            .navigationDestination(for: Kapitel.self) { KapitelDetailView(kapitel: $0) }
        }
    }
}

struct KapitelZeile: View {
    let kapitel: Kapitel
    let gelesen: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: kapitel.icon)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(kapitel.titel).font(.headline)
                Text(kapitel.kurz).font(.caption).foregroundStyle(.secondary).lineLimit(2)
            }
            Spacer(minLength: 0)
            if gelesen {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(kapitel.kurz)
                    .font(.headline)
                    .foregroundStyle(.secondary)

                ForEach(kapitel.abschnitte, id: \.self) { abschnitt in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(abschnitt.titel).font(.title3.bold())
                        RichText(text: abschnitt.text)
                    }
                }

                if !kapitel.merke.isEmpty {
                    MerkeBox(punkte: kapitel.merke)
                }

                if !fragen.isEmpty {
                    NavigationLink {
                        QuizView(fragen: fragen, titel: kapitel.titel)
                    } label: {
                        Label("\(fragen.count) Quizfragen zu diesem Kapitel", systemImage: "questionmark.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }

                Toggle("Als gelesen markieren", isOn: Binding(
                    get: { progress.istGelesen(kapitel) },
                    set: { progress.setGelesen(kapitel, $0) }
                ))
                .padding(.top, 8)
            }
            .padding()
        }
        .navigationTitle(kapitel.titel)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct MerkeBox: View {
    let punkte: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Merke", systemImage: "lightbulb.fill")
                .font(.headline)
                .foregroundStyle(.orange)
            ForEach(punkte, id: \.self) { punkt in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Image(systemName: "checkmark").font(.caption.bold()).foregroundStyle(.orange)
                    Text(RichText.markdown(punkt))
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
    }
}

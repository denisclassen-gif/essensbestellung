import SwiftUI

/// Geführte Einführung beim ersten Start. Die letzte Seite muss ausdrücklich bestätigt werden.
struct OnboardingView: View {
    let seiten: [OnboardingSeite]
    let fertig: () -> Void

    @State private var index = 0
    @State private var bestaetigt = false

    private var istLetzte: Bool { index >= seiten.count - 1 }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Einführung \(min(index + 1, seiten.count)) von \(seiten.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                if !istLetzte {
                    Button("Zum letzten Schritt") { withAnimation { index = seiten.count - 1 } }
                        .font(.subheadline)
                }
            }
            .padding()

            TabView(selection: $index) {
                ForEach(Array(seiten.enumerated()), id: \.offset) { i, seite in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            Image(systemName: seite.icon)
                                .font(.system(size: 56))
                                .foregroundStyle(.tint)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 20)
                            Text(seite.titel)
                                .font(.largeTitle.bold())
                                .fixedSize(horizontal: false, vertical: true)
                            RichText(text: seite.text)
                                .font(.title3)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                    .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            VStack(spacing: 12) {
                if istLetzte {
                    Toggle(isOn: $bestaetigt) {
                        Text("Ich habe den Hinweis gelesen und verstanden.")
                            .font(.headline)
                    }
                    .toggleStyle(.switch)
                    Button {
                        fertig()
                    } label: {
                        Text("Los geht's").font(.headline).frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(!bestaetigt)
                } else {
                    HStack(spacing: 12) {
                        if index > 0 {
                            Button {
                                withAnimation { index -= 1 }
                            } label: {
                                Text("Zurück").frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                        Button {
                            withAnimation { index += 1 }
                        } label: {
                            Text("Weiter").font(.headline).frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .controlSize(.large)
                }
            }
            .padding()
            .background(.bar)
        }
    }
}

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
                            Group {
                                if i == 0 {
                                    Emblem(groesse: 76)
                                        .padding(26)
                                        .background(RoundedRectangle(cornerRadius: 34, style: .continuous).fill(Stil.heroVerlauf))
                                        .shadow(color: Stil.tiefgruen.opacity(0.4), radius: 20, y: 12)
                                } else {
                                    IconPlakette(icon: seite.icon, farbe: Stil.farbe(i), groesse: 96)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 24)
                            .scaleEffect(index == i ? 1 : 0.7)
                            .opacity(index == i ? 1 : 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: index)
                            Text(seite.titel)
                                .font(.system(.largeTitle, design: .rounded).weight(.bold))
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
                    .tint(Stil.gruen)
                    .padding(14)
                    .glas(18)
                    Button {
                        fertig()
                    } label: {
                        Text("Los geht's")
                    }
                    .buttonStyle(PrimaerStil())
                    .disabled(!bestaetigt)
                    .opacity(bestaetigt ? 1 : 0.45)
                } else {
                    HStack(spacing: 12) {
                        if index > 0 {
                            Button {
                                withAnimation { index -= 1 }
                            } label: {
                                Text("Zurück")
                            }
                            .buttonStyle(GlasKnopfStil())
                        }
                        Button {
                            withAnimation { index += 1 }
                        } label: {
                            Text("Weiter")
                        }
                        .buttonStyle(PrimaerStil())
                    }
                }
            }
            .padding(20)
        }
        .seitenHintergrund()
    }
}

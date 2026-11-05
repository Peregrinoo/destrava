import SwiftUI

struct ProcessandoView: View {
    let nomeArquivo: String

    @State private var etapa = 0
    @State private var varrendo = false

    private let etapas = [
        "Lendo o PDF",
        "Entendendo que tipo de documento é",
        "Encontrando prazos e requisitos",
        "Conferindo cada trecho com o original"
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                ilustracao

                VStack(spacing: 6) {
                    Text("Destravando…")
                        .font(.largeTitle.weight(.heavy))
                    Text(nomeArquivo)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                VStack(alignment: .leading, spacing: 18) {
                    ForEach(Array(etapas.enumerated()), id: \.offset) { indice, titulo in
                        HStack(spacing: 12) {
                            indicador(indice)
                                .frame(width: 26, height: 26)
                            Text(titulo)
                                .font(.callout.weight(indice == etapa ? .bold : .medium))
                                .foregroundStyle(indice > etapa ? AnyShapeStyle(.secondary) : AnyShapeStyle(.primary))
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.white.opacity(0.07), in: .rect(cornerRadius: 24, style: .continuous))

                Text("Pode sair do app, o processamento continua.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
            .padding(.top, 12)
        }
        .scrollBounceBehavior(.basedOnSize)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Paleta.processamento)
        .environment(\.colorScheme, .dark)
        .task {
            while !Task.isCancelled && etapa < etapas.count - 1 {
                try? await Task.sleep(for: .seconds(1.5))
                withAnimation(.snappy) { etapa += 1 }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                varrendo = true
            }
        }
    }

    @ViewBuilder
    private func indicador(_ indice: Int) -> some View {
        if indice < etapa {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(Paleta.sucesso)
                .transition(.scale.combined(with: .opacity))
        } else if indice == etapa {
            ProgressView()
        } else {
            Image(systemName: "circle")
                .font(.title3)
                .foregroundStyle(.tertiary)
        }
    }

    private var ilustracao: some View {
        let larguras: [CGFloat] = [0.7, 1, 0.92, 1, 0.8, 0.96, 0.64]
        return ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white.opacity(0.12))
                .frame(width: 140, height: 186)
                .rotationEffect(.degrees(-6))
                .offset(x: 10, y: -8)

            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white)
                .frame(width: 148, height: 192)
                .overlay(alignment: .topLeading) {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(Array(larguras.enumerated()), id: \.offset) { indice, largura in
                            Capsule()
                                .fill(indice == 0 ? Color.black : Color.gray.opacity(0.25))
                                .frame(width: 108 * largura, height: indice == 0 ? 10 : 7)
                        }
                    }
                    .padding(20)
                }

            Capsule()
                .fill(Paleta.destaque)
                .frame(width: 172, height: 3)
                .shadow(color: Paleta.destaque, radius: 10)
                .offset(y: varrendo ? 80 : -80)
        }
        .frame(height: 220)
        .accessibilityHidden(true)
    }
}

#Preview {
    ProcessandoView(nomeArquivo: "Normas-Selecao-Bolsa.pdf")
}

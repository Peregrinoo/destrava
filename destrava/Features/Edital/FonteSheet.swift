import SwiftUI
import UIKit

struct FonteSheet: View {
    let trecho: TrechoFonte

    @Environment(\.dismiss) private var dismiss
    @State private var copiado = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("O DESTRAVA DISSE")
                            .font(.caption.weight(.bold))
                            .tracking(0.8)
                            .foregroundStyle(.secondary)
                        Text(trecho.afirmacao)
                            .font(.title3.weight(.semibold))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("NO EDITAL")
                                .font(.caption.weight(.bold))
                                .tracking(0.8)
                            Spacer()
                            if let pagina = trecho.fonte.pagina {
                                Text("Página \(pagina)")
                                    .font(.caption.weight(.semibold))
                            }
                        }
                        .foregroundStyle(.secondary)

                        Text("“\(trecho.fonte.trecho)”")
                            .font(.system(.body, design: .serif))
                            .lineSpacing(4)
                            .textSelection(.enabled)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Paleta.neutro, in: .rect(cornerRadius: 20, style: .continuous))

                    if trecho.fonte.verificada == false {
                        Label("Não achamos esse trecho exato no PDF. Confira no original antes de confiar.",
                              systemImage: "exclamationmark.circle.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Paleta.atencaoTexto)
                    } else {
                        Label("Trecho conferido no PDF original", systemImage: "checkmark.shield.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Paleta.sucesso)
                    }

                    Button {
                        UIPasteboard.general.string = trecho.fonte.trecho
                        copiado = true
                    } label: {
                        Label(copiado ? "Copiado" : "Copiar trecho",
                              systemImage: copiado ? "checkmark" : "doc.on.doc")
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    .sensoryFeedback(.success, trigger: copiado)
                    .task(id: copiado) {
                        guard copiado else { return }
                        try? await Task.sleep(for: .seconds(2))
                        copiado = false
                    }
                }
                .padding(20)
            }
            .navigationTitle("De onde veio isso?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

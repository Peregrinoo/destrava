import SwiftUI

struct Cartao: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Paleta.cartao, in: .rect(cornerRadius: 24, style: .continuous))
    }
}

extension View {
    func cartao() -> some View { modifier(Cartao()) }
}

struct Etiqueta: View {
    let texto: String
    var destaque = false

    var body: some View {
        Text(texto)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .foregroundStyle(destaque ? AnyShapeStyle(Paleta.destaque) : AnyShapeStyle(.secondary))
            .background(destaque ? Paleta.destaqueSuave : Paleta.neutro, in: .capsule)
    }
}

struct CabecalhoSecao<Acessorio: View>: View {
    let titulo: String
    let icone: String
    let acessorio: Acessorio

    init(_ titulo: String, icone: String, @ViewBuilder acessorio: () -> Acessorio) {
        self.titulo = titulo
        self.icone = icone
        self.acessorio = acessorio()
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icone)
                .font(.headline)
                .foregroundStyle(Paleta.destaque)
                .accessibilityHidden(true)
            Text(titulo)
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 8)
            acessorio
        }
    }
}

extension CabecalhoSecao where Acessorio == EmptyView {
    init(_ titulo: String, icone: String) {
        self.init(titulo, icone: icone) { EmptyView() }
    }
}

struct CartaoPrazo<Botao: View>: View {
    let data: Date
    let rotulo: String
    let descricao: String
    let botao: Botao

    init(data: Date, rotulo: String, descricao: String, @ViewBuilder botao: () -> Botao) {
        self.data = data
        self.rotulo = rotulo
        self.descricao = descricao
        self.botao = botao()
    }

    private var dias: Int { Date.now.dias(ate: data) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(rotulo.uppercased(), systemImage: "clock")
                .font(.caption.weight(.bold))
                .tracking(0.8)

            Group {
                if dias > 0 {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(dias)")
                            .font(.system(size: 56, weight: .heavy, design: .rounded))
                            .contentTransition(.numericText())
                        Text(dias == 1 ? "dia" : "dias")
                            .font(.title2.bold())
                    }
                } else if dias == 0 {
                    Text("É hoje!")
                        .font(.system(size: 44, weight: .heavy, design: .rounded))
                } else {
                    Text("Prazo encerrado")
                        .font(.title.bold())
                }
            }
            .accessibilityElement(children: .combine)

            Text(descricao)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                botao
                Spacer()
                Text(data.curta)
                    .font(.footnote.weight(.semibold))
            }
        }
        .foregroundStyle(Paleta.sobreDestaque)
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Paleta.destaque, in: .rect(cornerRadius: 28, style: .continuous))
    }
}

struct BotaoSobreDestaque: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.bold())
            .padding(.horizontal, 18)
            .frame(minHeight: 44)
            .foregroundStyle(.black)
            .background(.white, in: .capsule)
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

struct TrechoFonte: Identifiable {
    let id = UUID()
    let afirmacao: String
    let fonte: Fonte
}

struct MarcadorFonte: View {
    let fonte: Fonte

    var body: some View {
        HStack(spacing: 2) {
            if fonte.verificada == false {
                Image(systemName: "exclamationmark.circle")
            }
            Text(fonte.pagina.map { "p. \($0)" } ?? "fonte")
            Image(systemName: "chevron.right")
        }
        .font(.caption2.weight(.bold))
        .foregroundStyle(.secondary)
        .accessibilityLabel(fonte.pagina.map { "Ver trecho original, página \($0)" } ?? "Ver trecho original")
    }
}

struct LinhaComFonte: View {
    let texto: String
    var detalhe: String?
    let fonte: Fonte?
    let aoAbrirFonte: (TrechoFonte) -> Void

    var body: some View {
        if let fonte {
            Button {
                aoAbrirFonte(TrechoFonte(afirmacao: texto, fonte: fonte))
            } label: {
                conteudo(marcador: MarcadorFonte(fonte: fonte))
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
        } else {
            conteudo(marcador: EmptyView())
        }
    }

    private func conteudo(marcador: some View) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(texto)
                    .multilineTextAlignment(.leading)
                if let detalhe {
                    Text(detalhe)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 8)
            marcador
        }
        .frame(minHeight: 32)
    }
}

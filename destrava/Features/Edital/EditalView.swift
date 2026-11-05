import SwiftData
import SwiftUI

struct EditalView: View {
    let id: String

    @Environment(EditalStore.self) private var store
    @State private var erro: String?
    @State private var fonteAberta: TrechoFonte?

    var body: some View {
        Group {
            if let edital = store.edital(id: id) {
                conteudo(de: edital)
            } else if let erro {
                ContentUnavailableView {
                    Label("Não deu para abrir", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(erro)
                } actions: {
                    Button("Tentar de novo") { Task { await abrir() } }
                        .buttonStyle(.borderedProminent)
                }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .animation(.smooth, value: store.edital(id: id)?.status)
        .background(Paleta.fundo)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $fonteAberta) { trecho in
            FonteSheet(trecho: trecho)
        }
        .task(id: id) { await abrir() }
    }

    @ViewBuilder
    private func conteudo(de edital: Edital) -> some View {
        switch edital.status {
        case .processando:
            ProcessandoView(nomeArquivo: edital.nomeArquivo ?? "edital.pdf")
        case .falhou:
            ContentUnavailableView(
                "Não conseguimos destravar este edital",
                systemImage: "doc.questionmark",
                description: Text(edital.erro ?? "Tente enviar o arquivo de novo ou use o link do PDF original.")
            )
        case .pronto:
            if let conteudo = edital.conteudo {
                DetalheEdital(edital: edital, conteudo: conteudo) { fonteAberta = $0 }
            }
        }
    }

    private func abrir() async {
        erro = nil
        do {
            try await store.atualizar(id: id)
        } catch is CancellationError {
            return
        } catch {
            if store.edital(id: id) == nil { erro = mensagem(de: error) }
        }
    }
}

struct DetalheEdital: View {
    let edital: Edital
    let conteudo: ConteudoEdital
    let aoAbrirFonte: (TrechoFonte) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                cabecalho
                proximoPasso

                if !conteudo.destaques.isEmpty { destaques }

                ForEach(conteudo.secoes) { secao in
                    BlocoSecao(editalId: edital.id, secao: secao, aoAbrirFonte: aoAbrirFonte)
                }

                if !conteudo.datas.isEmpty { cronograma }
                if !conteudo.atencao.isEmpty { atencao }
                if !conteudo.naoInformado.isEmpty { naoInformado }

                Text("Toque em um item com página para ver o trecho original.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
    }

    private var cabecalho: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Etiqueta(texto: conteudo.documento.tipo.rotulo, destaque: true)
                if let orgao = conteudo.documento.orgao {
                    Etiqueta(texto: orgao)
                }
            }
            Text(conteudo.documento.titulo)
                .font(.title.weight(.heavy))
                .fixedSize(horizontal: false, vertical: true)
            Text(conteudo.resumoSimples)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 8)
    }

    @ViewBuilder
    private var proximoPasso: some View {
        if !conteudo.exigeAcao {
            Label("Este documento só informa. Você não precisa fazer nada.", systemImage: "checkmark.seal.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Paleta.sucesso)
                .cartao()
        } else if let passo = conteudo.proximoPasso {
            if let prazo = passo.prazo {
                CartaoPrazo(data: prazo, rotulo: "Próximo passo", descricao: passo.acao) {
                    if let link = passo.link {
                        Link("Abrir", destination: link)
                            .buttonStyle(BotaoSobreDestaque())
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    CabecalhoSecao("Próximo passo", icone: "arrow.forward.circle")
                    Text(passo.acao)
                    if let link = passo.link {
                        Link("Abrir", destination: link)
                            .buttonStyle(.borderedProminent)
                            .buttonBorderShape(.capsule)
                    }
                }
                .cartao()
            }
        }
    }

    private var destaques: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("EM 10 SEGUNDOS")
                .font(.caption.weight(.bold))
                .tracking(0.8)
                .foregroundStyle(.secondary)
            ForEach(Array(conteudo.destaques.enumerated()), id: \.offset) { _, destaque in
                Label {
                    Text(destaque).fixedSize(horizontal: false, vertical: true)
                } icon: {
                    Image(systemName: "sparkle").foregroundStyle(Paleta.destaque)
                }
                .font(.subheadline.weight(.medium))
            }
        }
        .cartao()
    }

    private var cronograma: some View {
        let hoje = Calendar.current.startOfDay(for: .now)
        let proxima = conteudo.datas.first { ($0.data ?? .distantPast) >= hoje }?.id

        return VStack(alignment: .leading, spacing: 14) {
            CabecalhoSecao("Quando acontece?", icone: "calendar")
            ForEach(conteudo.datas) { item in
                HStack(alignment: .firstTextBaseline, spacing: 14) {
                    Text(item.data?.curta ?? "—")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(item.id == proxima ? AnyShapeStyle(Paleta.destaque) : AnyShapeStyle(.secondary))
                        .frame(width: 64, alignment: .leading)
                    LinhaComFonte(
                        texto: item.evento,
                        detalhe: item.hora.map { "até \($0)" },
                        fonte: item.fonte,
                        aoAbrirFonte: aoAbrirFonte
                    )
                    .fontWeight(item.id == proxima ? .semibold : .regular)
                }
            }
        }
        .cartao()
    }

    private var atencao: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Atenção", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            ForEach(conteudo.atencao) { alerta in
                LinhaComFonte(texto: alerta.alerta, fonte: alerta.fonte, aoAbrirFonte: aoAbrirFonte)
                    .fontWeight(alerta.gravidade == .alta ? .semibold : .regular)
            }
        }
        .foregroundStyle(Paleta.atencaoTexto)
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Paleta.atencaoFundo, in: .rect(cornerRadius: 24, style: .continuous))
    }

    private var naoInformado: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("O edital não diz", systemImage: "questionmark.circle")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            ForEach(Array(conteudo.naoInformado.enumerated()), id: \.offset) { _, item in
                Text(item).foregroundStyle(.secondary)
            }
            if let email = conteudo.contato?.email, let url = URL(string: "mailto:\(email)") {
                Link("Perguntar por e-mail", destination: url)
                    .font(.subheadline.weight(.semibold))
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Paleta.neutro, in: .rect(cornerRadius: 24, style: .continuous))
    }
}

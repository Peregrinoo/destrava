import SwiftUI
import UIKit

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

extension Color {
    init(claro: UInt32, escuro: UInt32) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(hex: escuro) : UIColor(hex: claro)
        })
    }
}

enum Paleta {
    static let destaque = Color(claro: 0x3448F0, escuro: 0x7B8BFF)
    static let destaqueSuave = Color(claro: 0xE8EBFF, escuro: 0x232A5C)
    static let sobreDestaque = Color(claro: 0xFFFFFF, escuro: 0x0B0D1A)

    static let atencaoFundo = Color(claro: 0xFFF3D9, escuro: 0x3A2C0C)
    static let atencaoTexto = Color(claro: 0x5C3A00, escuro: 0xFFD58A)
    static let sucesso = Color(claro: 0x0F7B5F, escuro: 0x4ED1A1)
    static let erro = Color(claro: 0xC2410C, escuro: 0xFF8A5C)

    static let fundo = Color(uiColor: .systemGroupedBackground)
    static let cartao = Color(uiColor: .secondarySystemGroupedBackground)
    static let neutro = Color(uiColor: .tertiarySystemFill)
    static let processamento = Color(uiColor: UIColor(hex: 0x111318))
}

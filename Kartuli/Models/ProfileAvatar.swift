import SwiftUI

enum ProfileAvatar: String, CaseIterable, Identifiable {
    case khinkali
    case wine
    case khachapuri
    case churchkhela
    case pomegranate

    var id: String { rawValue }

    var name: String {
        switch self {
        case .khinkali: "Khinkali"
        case .wine: "Wine"
        case .khachapuri: "Khachapuri"
        case .churchkhela: "Churchkhela"
        case .pomegranate: "Pomegranate"
        }
    }

    var assetName: String {
        switch self {
        case .khinkali: "AvatarKhinkali"
        case .wine: "AvatarWine"
        case .khachapuri: "AvatarKhachapuri"
        case .churchkhela: "AvatarChurchkhela"
        case .pomegranate: "AvatarPomegranate"
        }
    }
}

struct ProfileAvatarImage: View {
    let avatar: ProfileAvatar
    let size: CGFloat

    var body: some View {
        Image(avatar.assetName)
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay {
                Circle().stroke(.white.opacity(0.75), lineWidth: max(2, size * 0.035))
            }
            .shadow(color: .black.opacity(0.12), radius: size * 0.09, y: size * 0.05)
    }
}

import SwiftUI

/// Stylized tsurumaru-inspired mark. Not the official logo — a respectful nod
/// using a circular badge with an abstracted crane silhouette built from SF Symbols.
struct CraneMark: View {
    var size: CGFloat = 36
    var tint: Color = .white
    var background: Color = JALTheme.crane

    var body: some View {
        ZStack {
            Circle().fill(background)
            Image(systemName: "bird.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(tint)
                .padding(size * 0.22)
                .rotationEffect(.degrees(-15))
        }
        .frame(width: size, height: size)
        .accessibilityLabel("JAL")
    }
}

#Preview {
    HStack(spacing: 16) {
        CraneMark(size: 28)
        CraneMark(size: 56)
        CraneMark(size: 88)
    }.padding().background(JALTheme.mist)
}

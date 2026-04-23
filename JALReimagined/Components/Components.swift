import SwiftUI

// MARK: - Section header

struct SectionHeader: View {
    let title: String
    var action: String? = nil
    var onAction: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(.jal(13, .semibold))
                .tracking(1.4)
                .foregroundStyle(JALTheme.inkSoft)
                .textCase(.uppercase)
            Spacer()
            if let action {
                Button(action: { onAction?() }) {
                    Text(action)
                        .font(.jal(13, .semibold))
                        .foregroundStyle(JALTheme.crane)
                }
            }
        }
    }
}

// MARK: - Pill / chip

struct Pill: View {
    let text: String
    var icon: String? = nil
    var tint: Color = JALTheme.crane
    var filled: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            if let icon { Image(systemName: icon).font(.system(size: 11, weight: .bold)) }
            Text(text).font(.jal(12, .semibold))
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .foregroundStyle(filled ? Color.white : tint)
        .background(
            Capsule().fill(filled ? tint : tint.opacity(0.12))
        )
    }
}

// MARK: - Stat

struct StatBlock: View {
    let value: String
    let label: String
    var sub: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.jal(22, .bold))
                .foregroundStyle(JALTheme.ink)
            Text(label)
                .font(.jal(11, .semibold))
                .tracking(0.8)
                .textCase(.uppercase)
                .foregroundStyle(JALTheme.inkSoft)
            if let sub {
                Text(sub).font(.jal(11)).foregroundStyle(JALTheme.inkSoft)
            }
        }
    }
}

// MARK: - Dashed separator

struct DashedDivider: View {
    var color: Color = JALTheme.line
    var body: some View {
        GeometryReader { geo in
            Path { p in
                p.move(to: .init(x: 0, y: 0))
                p.addLine(to: .init(x: geo.size.width, y: 0))
            }
            .stroke(color, style: .init(lineWidth: 1, dash: [4, 4]))
        }
        .frame(height: 1)
    }
}

// MARK: - Quick action button

struct QuickAction: View {
    let icon: String
    let label: String
    var tint: Color = JALTheme.ink
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle().fill(JALTheme.mist)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(tint)
                }
                .frame(width: 56, height: 56)

                Text(label)
                    .font(.jal(12, .medium))
                    .foregroundStyle(JALTheme.ink)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Big primary button

struct PrimaryButton: View {
    let title: String
    var icon: String? = nil
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let icon { Image(systemName: icon) }
                Text(title).font(.jal(16, .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(JALTheme.craneGradient)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: JALTheme.crane.opacity(0.25), radius: 14, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Date helpers

extension Date {
    func formatted(in tzId: String, _ format: String) -> String {
        let f = DateFormatter()
        f.timeZone = TimeZone(identifier: tzId)
        f.dateFormat = format
        return f.string(from: self)
    }
}

import SwiftUI

enum CommandCenterTheme {
    static let backgroundTop = Color(red: 0.05, green: 0.08, blue: 0.13)
    static let backgroundBottom = Color(red: 0.02, green: 0.03, blue: 0.06)
    static let card = Color(red: 0.08, green: 0.11, blue: 0.17)
    static let cardAlt = Color(red: 0.11, green: 0.15, blue: 0.22)
    static let stroke = Color.white.opacity(0.10)
    static let shadow = Color.black.opacity(0.28)
    static let title = Color.white
    static let body = Color(red: 0.90, green: 0.93, blue: 0.98)
    static let muted = Color(red: 0.62, green: 0.69, blue: 0.80)
    static let accent = Color(red: 0.41, green: 0.63, blue: 0.98)
    static let warmAccent = Color(red: 0.96, green: 0.64, blue: 0.29)
    static let countdown = Color(red: 1.00, green: 0.73, blue: 0.42)
}

struct ProgressRing: View {
    let progress: Double
    let label: String
    let tint: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(tint.opacity(0.16), lineWidth: 16)

            Circle()
                .trim(from: 0, to: max(0, min(progress, 1)))
                .stroke(
                    AngularGradient(
                        colors: [tint.opacity(0.65), tint],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            Text(label)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(CommandCenterTheme.title)
                .padding(22)
        }
    }
}

struct CommandCenterBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                LinearGradient(
                    colors: [
                        CommandCenterTheme.backgroundTop,
                        CommandCenterTheme.backgroundBottom
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
}

struct CommandCenterCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(CommandCenterTheme.card.opacity(0.95))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(CommandCenterTheme.stroke, lineWidth: 1)
            )
            .shadow(color: CommandCenterTheme.shadow, radius: 18, x: 0, y: 12)
    }
}

extension View {
    func commandCenterBackground() -> some View {
        modifier(CommandCenterBackground())
    }

    func commandCenterCard() -> some View {
        modifier(CommandCenterCard())
    }
}

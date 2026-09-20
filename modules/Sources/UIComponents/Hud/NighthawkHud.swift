import SwiftUI
import Generated

public struct NighthawkHudPanel<Content: View>: View {
    public var connectedGlow: Bool
    public var compact: Bool
    @ViewBuilder public var content: () -> Content

    public init(
        connectedGlow: Bool = false,
        compact: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.connectedGlow = connectedGlow
        self.compact = compact
        self.content = content
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: compact ? 2 : 8) {
            content()
        }
        .padding(compact ? 4 : 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(StealthTheme.Colors.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(StealthTheme.Colors.border, lineWidth: 1)
        )
        .shadow(
            color: connectedGlow ? StealthTheme.Colors.primary.opacity(0.35) : .clear,
            radius: connectedGlow ? 8 : 0
        )
        .accessibilityIdentifier("nighthawk_hud_panel")
    }
}

public struct PeerSlotRow: View {
    public let slotIndex: Int
    public let label: String
    public let connected: Bool
    public var compact: Bool

    public init(slotIndex: Int, label: String, connected: Bool, compact: Bool = false) {
        self.slotIndex = slotIndex
        self.label = label
        self.connected = connected
        self.compact = compact
    }

    public var body: some View {
        HStack(spacing: compact ? 6 : 10) {
            Circle()
                .fill(connected ? StealthTheme.Colors.primary : StealthTheme.Colors.border)
                .frame(width: 8, height: 8)
            Text("\(slotIndex)")
                .font(StealthTheme.Heading.regular(12))
                .foregroundColor(StealthTheme.Colors.textMuted)
            Text(label)
                .font(.system(size: compact ? 12 : 13, design: .monospaced))
                .foregroundColor(connected ? StealthTheme.Colors.primary : StealthTheme.Colors.textMuted)
                .lineLimit(1)
            Spacer()
        }
        .frame(minHeight: compact ? 28 : 44)
        .accessibilityIdentifier("nighthawk_hud_peer_slot_\(slotIndex)")
    }
}

public struct TransportSegment: View {
    public let torSelected: Bool
    public var compact: Bool
    public let onSelectTor: (Bool) -> Void

    public init(torSelected: Bool, compact: Bool = false, onSelectTor: @escaping (Bool) -> Void) {
        self.torSelected = torSelected
        self.compact = compact
        self.onSelectTor = onSelectTor
    }

    public var body: some View {
        HStack(spacing: 0) {
            chip("tcp", selected: !torSelected) { onSelectTor(false) }
            chip("tor", selected: torSelected) { onSelectTor(true) }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(StealthTheme.Colors.border, lineWidth: 1)
        )
        .fixedSize(horizontal: compact, vertical: true)
        .accessibilityIdentifier("nighthawk_hud_transport")
    }

    private func chip(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(StealthTheme.Heading.medium(compact ? 11 : 14))
                .foregroundColor(selected ? StealthTheme.Colors.primary : StealthTheme.Colors.textMuted)
                .frame(maxWidth: compact ? nil : .infinity, minHeight: compact ? 22 : 44)
                .padding(.horizontal, compact ? 8 : 0)
                .background(selected ? StealthTheme.Colors.primary.opacity(0.18) : Color.clear)
        }
        .buttonStyle(.plain)
    }
}

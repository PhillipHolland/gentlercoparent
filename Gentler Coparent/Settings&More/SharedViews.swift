import SwiftUI

// MARK: - Legacy card group (kept for non-List sheets that still need it)
struct SettingsSectionGroup<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(
            RoundedRectangle(cornerRadius: GCPTheme.radiusCard, style: .continuous)
                .fill(GCPTheme.cardFill)
                .shadow(color: Color.black.opacity(0.04), radius: 8, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: GCPTheme.radiusCard, style: .continuous)
                .stroke(GCPTheme.primary.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - SF Symbol badge used in settings rows
struct SettingsIconBadge: View {
    let systemName: String
    var tint: Color = GCPTheme.primary
    var background: Color = GCPTheme.mint.opacity(0.55)
    
    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: 32, height: 32)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(background)
            )
            .accessibilityHidden(true)
    }
}

// MARK: - Consistent detail sheet chrome (nav title + Done)
struct SettingsDetailShell<Content: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(GCPTheme.canvas.ignoresSafeArea())
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { dismiss() }
                            .font(GCPTheme.bodyMedium(16))
                            .foregroundStyle(GCPTheme.primary)
                    }
                }
                .toolbarBackground(GCPTheme.canvas, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}

// MARK: - Article-style text block for info screens
struct SettingsArticleBlock: View {
    let title: String?
    let bodyText: String
    
    init(_ title: String? = nil, _ bodyText: String) {
        self.title = title
        self.bodyText = bodyText
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let title, !title.isEmpty {
                Text(title)
                    .font(GCPTheme.title(17))
                    .foregroundStyle(GCPTheme.primary)
            }
            Text(bodyText)
                .font(GCPTheme.body(15))
                .foregroundStyle(GCPTheme.primary.opacity(0.92))
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Feature / FAQ card
struct SettingsInfoCard: View {
    let icon: String
    let title: String
    let detail: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            SettingsIconBadge(systemName: icon)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(GCPTheme.title(16))
                    .foregroundStyle(GCPTheme.primary)
                Text(detail)
                    .font(GCPTheme.body(14))
                    .foregroundStyle(GCPTheme.primary.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: GCPTheme.radiusCard, style: .continuous)
                .fill(GCPTheme.cardFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: GCPTheme.radiusCard, style: .continuous)
                .stroke(GCPTheme.primary.opacity(0.08), lineWidth: 1)
        )
    }
}

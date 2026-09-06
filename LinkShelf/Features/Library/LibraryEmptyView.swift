import SwiftUI

struct LibraryEmptyView: View {
    let destination: LibraryDestination

    var body: some View {
        VStack(spacing: AppSpacing.large) {
            Image(systemName: destination == .all ? "link" : destination.symbol)
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
                .padding(.bottom, AppSpacing.small)
            Text(destination.emptyTitle)
                .font(.title2.weight(.semibold))
            Text(destination.emptyMessage)
                .font(.body)
                .foregroundStyle(.primary)
                .lineSpacing(AppSpacing.xSmall)
                .fixedSize(horizontal: false, vertical: true)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: 350)
        .padding(.horizontal, AppSpacing.xLarge)
    }
}

struct BuildInformationView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xLarge) {
            Label("LinkShelf", systemImage: "books.vertical")
                .font(.title2.weight(.semibold))
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                Text("A foundation for your library")
                    .font(.title3.weight(.semibold))
                Text("This first development build includes native navigation, view preferences, and appearance settings.")
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                Label("Next: folders and custom icons", systemImage: "folder")
                Label("Then: saved links and rich previews", systemImage: "link")
                Label("Later: configurable desktop widgets", systemImage: "rectangle.3.group")
            }
            Text("Saving links is not available in this build yet.")
                .font(.callout)
                .foregroundStyle(.primary)
            HStack {
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(AppSpacing.xxLarge)
        .frame(width: 450)
    }
}

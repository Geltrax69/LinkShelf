import SwiftUI

struct SettingsView: View {
    @AppStorage("appearance") private var appearance = AppAppearance.system.rawValue
    @AppStorage("libraryLayout") private var layout = LibraryLayout.grid.rawValue

    var body: some View {
        Form {
            Section("Appearance") {
                Picker("Appearance", selection: $appearance) {
                    ForEach(AppAppearance.allCases) { option in
                        Text(option.title).tag(option.rawValue)
                    }
                }
                .pickerStyle(.menu)
                .accessibilityLabel("Appearance")
                .accessibilityIdentifier("appearancePicker")
                Picker("Library view", selection: $layout) {
                    ForEach(LibraryLayout.allCases) { option in
                        Text(option.title).tag(option.rawValue)
                    }
                }
                .pickerStyle(.menu)
                .accessibilityLabel("Library view")
            }
            Section {
                Text("LinkShelf follows your Mac’s appearance by default.")
                    .font(.callout)
                    .foregroundStyle(.primary)
            }
        }
        .formStyle(.grouped)
        .padding(AppSpacing.large)
        .frame(width: 420, height: 240)
        .navigationTitle("LinkShelf Settings")
    }
}

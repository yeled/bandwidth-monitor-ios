import SwiftUI

struct SettingsView: View {
    @AppStorage(SettingsKey.serverURL, store: AppGroup.defaults) private var serverURL: String = ""
    @Environment(\.dismiss) private var dismiss
    @State private var draft: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("http://192.168.1.1:8080", text: $draft)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("Server")
                } footer: {
                    Text("Address of your bandwidth-monitor instance (awlx/bandwidth-monitor). Plain HTTP on your LAN is fine.")
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        serverURL = draft
                        dismiss()
                    }
                }
            }
            .onAppear { draft = serverURL }
        }
    }
}

#Preview {
    SettingsView()
}

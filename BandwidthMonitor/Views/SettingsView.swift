import SwiftUI

struct SettingsView: View {
    @AppStorage(SettingsKey.serverURL, store: AppGroup.defaults) private var serverURL: String = ""
    @AppStorage(SettingsKey.liveActivityPushToken, store: AppGroup.defaults) private var pushToken: String = ""
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

                if !pushToken.isEmpty {
                    Section {
                        Button {
                            UIPasteboard.general.string = pushToken
                        } label: {
                            HStack {
                                Text(pushToken)
                                    .font(.caption.monospaced())
                                    .lineLimit(2)
                                    .truncationMode(.middle)
                                Spacer()
                                Image(systemName: "doc.on.doc")
                            }
                        }
                    } header: {
                        Text("Live Activity push token")
                    } footer: {
                        Text("Tap to copy. Hand to the push sender (scripts/live_activity_push.py) so the Lock Screen view updates while the app is closed.")
                    }
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

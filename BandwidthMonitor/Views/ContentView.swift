import SwiftUI
import WidgetKit

struct ContentView: View {
    @AppStorage(SettingsKey.serverURL, store: AppGroup.defaults) private var serverURL: String = ""
    @StateObject private var viewModel = TrafficViewModel()
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            Group {
                if serverURL.isEmpty {
                    ContentUnavailableView(
                        "No Server Configured",
                        systemImage: "server.rack",
                        description: Text("Add your bandwidth-monitor server address in Settings.")
                    )
                } else {
                    trafficList
                }
            }
            .navigationTitle("Bandwidth Monitor")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .task(id: serverURL) {
                if !serverURL.isEmpty {
                    viewModel.start(baseURLString: serverURL)
                } else {
                    viewModel.stop()
                }
                WidgetCenter.shared.reloadTimelines(ofKind: TrafficWidgetKind.id)
            }
        }
    }

    private var trafficList: some View {
        List {
            if let error = viewModel.errorMessage {
                Section {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }

            if !viewModel.interfaces.isEmpty {
                Section("Interface") {
                    Picker("Interface", selection: $viewModel.selectedInterface) {
                        ForEach(viewModel.interfaces) { stat in
                            Text(stat.name).tag(Optional(stat.name))
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Traffic") {
                    Picker("Range", selection: $viewModel.timeRange) {
                        ForEach(TimeRange.allCases) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)

                    TrafficChartView(points: viewModel.chartPoints)
                        .listRowInsets(EdgeInsets())
                        .padding()
                }
            }

            Section("Interfaces") {
                ForEach(viewModel.interfaces) { stat in
                    InterfaceRowView(stat: stat)
                }
                if viewModel.interfaces.isEmpty && viewModel.isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                }
            }
        }
        .refreshable {
            await viewModel.refreshNow(baseURLString: serverURL)
        }
    }
}

#Preview {
    ContentView()
}

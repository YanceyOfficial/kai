import SwiftUI
import KaiServices
import KaiUI

/// The Diagnostics screen: browse, filter, share, and clear the app's collected logs.
struct LogsView: View {
    private enum Filter: String, CaseIterable, Identifiable {
        case all = "All", warnings = "Warnings", errors = "Errors"
        var id: String { rawValue }
        var minLevel: LogLevel {
            switch self {
            case .all: return .debug
            case .warnings: return .warning
            case .errors: return .error
            }
        }
    }

    @State private var filter: Filter = .all
    @State private var records: [LogRecord] = []
    @State private var showingClear = false

    var body: some View {
        VStack(spacing: 0) {
            Picker("Filter", selection: $filter) {
                ForEach(Filter.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding(KaiSpacing.m)

            List {
                if records.isEmpty {
                    ContentUnavailableView("No logs", systemImage: "doc.text.magnifyingglass",
                                           description: Text("Diagnostic records will appear here."))
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(records) { record in
                        row(record).listRowBackground(KaiColor.cardFace)
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .background(KaiColor.washi)
        .navigationTitle("Diagnostics")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    ShareLink(item: LogCollector.shared.exportText()) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    Button(role: .destructive) { showingClear = true } label: {
                        Label("Clear", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .tint(KaiColor.vermilion)
            }
        }
        .confirmationDialog("Clear all logs?", isPresented: $showingClear, titleVisibility: .visible) {
            Button("Clear", role: .destructive) {
                LogCollector.shared.clear()
                reload()
            }
            Button("Cancel", role: .cancel) {}
        }
        .onAppear(perform: reload)
        .onChange(of: filter) { reload() }
    }

    private func row(_ record: LogRecord) -> some View {
        VStack(alignment: .leading, spacing: KaiSpacing.xs) {
            HStack(spacing: KaiSpacing.s) {
                Text(record.level.label)
                    .font(KaiFont.body(10, weight: .bold))
                    .foregroundStyle(KaiColor.cardFace)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(color(for: record.level)))
                Text(record.category)
                    .font(KaiFont.body(12, weight: .medium))
                    .foregroundStyle(KaiColor.inkSecondary)
                Spacer()
                Text(record.timestamp.formatted(date: .omitted, time: .standard))
                    .font(KaiFont.phonetic(11))
                    .foregroundStyle(KaiColor.inkSecondary)
            }
            Text(record.message)
                .font(KaiFont.body(14))
                .foregroundStyle(KaiColor.sumi)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 2)
    }

    private func color(for level: LogLevel) -> Color {
        switch level {
        case .error: return KaiColor.danger
        case .warning: return KaiColor.vermilion
        case .info, .debug: return KaiColor.inkSecondary
        }
    }

    private func reload() {
        records = LogCollector.shared.snapshot(minLevel: filter.minLevel)
    }
}

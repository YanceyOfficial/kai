import SwiftUI
import Charts
import KaiCore
import KaiUI

/// The statistics dashboard: quick counts, a 7-day review bar chart (Swift Charts),
/// and overall accuracy. All aggregation is done by the pure `StatsAggregator`.
struct StatsView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var totalWords = 0
    @State private var learnedWords = 0
    @State private var dueWords = 0
    @State private var bars: [DayBar] = []
    @State private var accuracy: Double?
    @State private var totalReviews = 0

    var body: some View {
        NavigationStack {
            ZStack {
                KaiColor.washi.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: KaiSpacing.l) {
                        summaryRow
                        reviewsCard
                        accuracyCard
                    }
                    .padding(KaiSpacing.l)
                }
            }
            .navigationTitle("Stats")
        }
        .onAppear(perform: reload)
    }

    // MARK: Sections

    private var summaryRow: some View {
        HStack(spacing: KaiSpacing.m) {
            statCard(value: "\(totalWords)", label: "Words")
            statCard(value: "\(learnedWords)", label: "Learned")
            statCard(value: "\(dueWords)", label: "Due")
        }
    }

    private func statCard(value: String, label: String) -> some View {
        VStack(spacing: KaiSpacing.xs) {
            Text(value)
                .font(KaiFont.display(30, weight: .bold))
                .foregroundStyle(KaiColor.sumi)
            Text(label)
                .font(KaiFont.body(13, weight: .medium))
                .foregroundStyle(KaiColor.inkSecondary)
                .textCase(.uppercase)
                .tracking(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, KaiSpacing.m)
        .background(cardBackground)
    }

    private var reviewsCard: some View {
        VStack(alignment: .leading, spacing: KaiSpacing.m) {
            Text("Reviews · last 7 days")
                .font(KaiFont.body(15, weight: .semibold))
                .foregroundStyle(KaiColor.sumi)

            if totalReviews == 0 {
                emptyHint("No reviews yet — rate a few cards to see your history.")
            } else {
                Chart(bars) { bar in
                    BarMark(
                        x: .value("Day", bar.date, unit: .day),
                        y: .value("Reviews", bar.count)
                    )
                    .foregroundStyle(KaiColor.vermilion)
                    .cornerRadius(4)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisValueLabel(format: .dateTime.weekday(.narrow))
                    }
                }
                .chartYAxis { AxisMarks(position: .leading) }
                .frame(height: 180)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(KaiSpacing.l)
        .background(cardBackground)
    }

    private var accuracyCard: some View {
        VStack(alignment: .leading, spacing: KaiSpacing.s) {
            Text("Accuracy")
                .font(KaiFont.body(15, weight: .semibold))
                .foregroundStyle(KaiColor.sumi)
            if let accuracy {
                HStack(alignment: .firstTextBaseline, spacing: KaiSpacing.s) {
                    Text("\(Int((accuracy * 100).rounded()))%")
                        .font(KaiFont.display(40, weight: .bold))
                        .foregroundStyle(KaiColor.vermilion)
                    Text("over \(totalReviews) review\(totalReviews == 1 ? "" : "s")")
                        .font(KaiFont.body(14, weight: .regular))
                        .foregroundStyle(KaiColor.inkSecondary)
                }
            } else {
                emptyHint("No reviews yet.")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(KaiSpacing.l)
        .background(cardBackground)
    }

    private func emptyHint(_ text: String) -> some View {
        Text(text)
            .font(KaiFont.body(14, weight: .regular))
            .foregroundStyle(KaiColor.inkSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(KaiColor.cardFace)
            .shadow(color: KaiColor.shadow, radius: 10, x: 0, y: 6)
    }

    // MARK: Data

    private func reload() {
        let repository = VocabularyRepository(context: modelContext)
        let entries = (try? repository.entries(for: .english)) ?? []
        let logs = (try? repository.allReviewLogs()) ?? []
        let now = Date()

        totalWords = entries.count
        learnedWords = entries.filter { $0.scheduling.state == .review }.count
        dueWords = entries.filter { $0.dueAt <= now }.count
        bars = StatsAggregator.reviewsByDay(logs.map(\.timestamp), lastDays: 7, now: now)
        accuracy = StatsAggregator.accuracy(logs.map(\.isCorrect))
        totalReviews = logs.count
    }
}

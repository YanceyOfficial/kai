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
    @State private var streak = 0
    @State private var curve: [RecallPoint] = []
    @State private var atRisk = 0
    @State private var maturityCounts: [MaturityCount] = []

    var body: some View {
        NavigationStack {
            ZStack {
                KaiColor.washi.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: KaiSpacing.l) {
                        Text("Stats")
                            .font(KaiFont.display(34, weight: .bold))
                            .foregroundStyle(KaiColor.sumi)
                        summaryRow
                        secondRow
                        forgettingCard
                        maturityCard
                        reviewsCard
                        accuracyCard
                    }
                    .padding(KaiSpacing.l)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
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

    private var secondRow: some View {
        HStack(spacing: KaiSpacing.m) {
            statCard(value: "\(streak)", label: "Day streak")
            statCard(value: "\(atRisk)", label: "At risk · 7d")
        }
    }

    /// The deck's aggregate forgetting curve: predicted recall over the next 30 days.
    private var forgettingCard: some View {
        VStack(alignment: .leading, spacing: KaiSpacing.m) {
            HStack(alignment: .firstTextBaseline) {
                Text("Forgetting curve")
                    .font(KaiFont.body(15, weight: .semibold))
                    .foregroundStyle(KaiColor.sumi)
                Spacer()
                if let now = curve.first?.recall {
                    Text("\(Int((now * 100).rounded()))% recall now")
                        .font(KaiFont.body(13, weight: .medium))
                        .foregroundStyle(KaiColor.inkSecondary)
                }
            }

            if curve.isEmpty {
                emptyHint("Review some words to model your memory.")
            } else {
                Chart {
                    ForEach(curve) { point in
                        LineMark(
                            x: .value("Day", point.dayOffset),
                            y: .value("Recall", point.recall)
                        )
                        .foregroundStyle(KaiColor.vermilion)
                        .interpolationMethod(.monotone)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                    }
                    RuleMark(y: .value("Target", 0.9))
                        .foregroundStyle(KaiColor.inkSecondary.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .annotation(position: .top, alignment: .trailing) {
                            Text("90% target")
                                .font(KaiFont.body(10))
                                .foregroundStyle(KaiColor.inkSecondary)
                        }
                }
                .chartYScale(domain: 0...1)
                .chartYAxis { AxisMarks(position: .leading, values: [0, 0.5, 1]) { value in
                    AxisValueLabel {
                        if let d = value.as(Double.self) { Text("\(Int(d * 100))%") }
                    }
                } }
                .chartXAxis { AxisMarks(values: [0, 7, 14, 21, 30]) { value in
                    AxisValueLabel { if let d = value.as(Int.self) { Text("\(d)d") } }
                } }
                .frame(height: 180)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(KaiSpacing.l)
        .background(cardBackground)
    }

    /// Memory maturity: how many words are new / learning / young / mature.
    private var maturityCard: some View {
        VStack(alignment: .leading, spacing: KaiSpacing.m) {
            Text("Memory maturity")
                .font(KaiFont.body(15, weight: .semibold))
                .foregroundStyle(KaiColor.sumi)

            if maturityCounts.allSatisfy({ $0.count == 0 }) {
                emptyHint("Add words to see your deck's maturity.")
            } else {
                Chart(maturityCounts) { item in
                    BarMark(
                        x: .value("Count", item.count),
                        y: .value("Maturity", item.bucket.rawValue)
                    )
                    .foregroundStyle(maturityColor(item.bucket))
                    .cornerRadius(4)
                    .annotation(position: .trailing) {
                        Text("\(item.count)")
                            .font(KaiFont.body(11, weight: .medium))
                            .foregroundStyle(KaiColor.inkSecondary)
                    }
                }
                .chartYScale(domain: MaturityBucket.allCases.reversed().map(\.rawValue))
                .chartXAxis(.hidden)
                .frame(height: 150)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(KaiSpacing.l)
        .background(cardBackground)
    }

    /// Single-hue sequential ramp: new (light) → mature (full vermilion).
    private func maturityColor(_ bucket: MaturityBucket) -> Color {
        switch bucket {
        case .new: return KaiColor.vermilion.opacity(0.30)
        case .learning: return KaiColor.vermilion.opacity(0.50)
        case .young: return KaiColor.vermilion.opacity(0.72)
        case .mature: return KaiColor.vermilion
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
        streak = StatsAggregator.streak(reviewDates: logs.map(\.timestamp), now: now)

        // Memories that have been reviewed at least once model the forgetting curve.
        let memories: [(stability: Double, elapsedDays: Double)] = entries.compactMap { entry in
            let s = entry.scheduling
            guard s.stability > 0, let last = s.lastReview else { return nil }
            return (s.stability, max(0, now.timeIntervalSince(last) / 86_400))
        }
        curve = StatsAggregator.forgettingCurve(memories, overDays: 30)
        atRisk = StatsAggregator.atRisk(memories, threshold: 0.9, within: 7)
        maturityCounts = StatsAggregator.maturity(entries.map { ($0.scheduling.state, $0.scheduling.stability) })
    }
}

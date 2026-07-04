import WidgetKit
import SwiftUI
import KaiServices
import KaiUI

/// One timeline entry: the latest snapshot the app published to the App Group.
struct ReviewEntry: TimelineEntry {
    let date: Date
    let snapshot: ReviewWidgetSnapshot?
}

struct ReviewProvider: TimelineProvider {
    func placeholder(in context: Context) -> ReviewEntry {
        ReviewEntry(date: .now, snapshot: ReviewWidgetSnapshot(dueCount: 5, totalWords: 20))
    }

    func getSnapshot(in context: Context, completion: @escaping (ReviewEntry) -> Void) {
        completion(ReviewEntry(date: .now, snapshot: WidgetSnapshotStore().read()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ReviewEntry>) -> Void) {
        let entry = ReviewEntry(date: .now, snapshot: WidgetSnapshotStore().read())
        // Refresh in an hour; the app also force-reloads whenever the count changes.
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct ReviewWidgetView: View {
    var entry: ReviewEntry

    private var due: Int { entry.snapshot?.dueCount ?? 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: KaiSpacing.xs) {
            Text("甲")
                .font(.system(size: 15, weight: .heavy))
                .foregroundStyle(KaiColor.vermilion)
            Spacer(minLength: 0)
            Text("\(due)")
                .font(KaiFont.display(42, weight: .bold))
                .foregroundStyle(due == 0 ? KaiColor.inkSecondary : KaiColor.sumi)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(subtitle)
                .font(KaiFont.body(13, weight: .medium))
                .foregroundStyle(KaiColor.inkSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(KaiColor.cardFace, for: .widget)
    }

    private var subtitle: String {
        switch due {
        case 0: return "all caught up"
        case 1: return "word due"
        default: return "words due"
        }
    }
}

struct ReviewWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ReviewWidget", provider: ReviewProvider()) { entry in
            ReviewWidgetView(entry: entry)
        }
        .configurationDisplayName("Words due")
        .description("How many words are due for review.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct KaiWidgetBundle: WidgetBundle {
    var body: some Widget {
        ReviewWidget()
    }
}

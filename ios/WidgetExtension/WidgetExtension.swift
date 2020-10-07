// Copyright 2020 David Sansome
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Intents
import SwiftUI
import WidgetKit

struct WidgetDataProvider: TimelineProvider {
  fileprivate func getData(_ date: Date) -> ExpandedWidgetData {
    WidgetHelper.readProjectedData(date)
  }

  func placeholder(in _: Context) -> WidgetExtensionEntry {
    WidgetExtensionEntry(date: Date(), data: getData(Date()))
  }

  func getSnapshot(in _: Context, completion: @escaping (WidgetExtensionEntry) -> Void) {
    let entry = WidgetExtensionEntry(date: Date(), data: getData(Date()))
    completion(entry)
  }

  func getTimeline(in _: Context, completion: @escaping (Timeline<Entry>) -> Void) {
    var entries: [WidgetExtensionEntry] = []

    // Generate a timeline consisting of now and 24 entries an hour apart.
    let currentDate = Date()
    entries.append(WidgetExtensionEntry(date: currentDate, data: getData(currentDate)))
    let zeroOffsetDate = Calendar.current.date(bySettingHour: currentDate.hour, minute: 0,
                                               second: 0,
                                               of: currentDate)!
    for hourOffset in 1 ... 24 {
      let entryDate = zeroOffsetDate + Double(3600 * hourOffset)
      let entry = WidgetExtensionEntry(date: entryDate, data: getData(entryDate))
      entries.append(entry)
    }

    let timeline = Timeline(entries: entries, policy: .atEnd)
    completion(timeline)
  }
}

struct WidgetExtensionEntry: TimelineEntry {
  let date: Date
  let data: ExpandedWidgetData
}

struct WidgetExtensionEntryView: View {
  var entry: WidgetDataProvider.Entry
  @Environment(\.widgetFamily) private var widgetFamily

  private var lessonReviewSmallBox: some View {
    VStack {
      HStack(alignment: .center, spacing: 50.0) {
        Text("\(entry.data.lessons)").font(.largeTitle)
        Text("\(entry.data.reviews)").font(.largeTitle)
      }
      HStack(alignment: .center, spacing: 30.0) {
        Text("Lessons").font(.subheadline)
        Text("Reviews").font(.subheadline)
      }
      Text(entry.date.time)
    }
  }

  private func gridLayout(columns: Int, spacing: CGFloat = 30,
                          _ bonusFirst: CGFloat = 20,
                          _ bonusLast: CGFloat = 0) -> [GridItem] {
    var items = Array(repeating: GridItem(.fixed(spacing)), count: columns)
    items[0].size = .fixed(spacing + bonusFirst)
    if columns > 2 {
      items[items.count - 2].size = .fixed(spacing + bonusLast)
      items[items.count - 1].size = .fixed(spacing + bonusLast)
    }
    return items
  }

  private var forecastSmFont: Font {
    .system(size: 11, weight: .light, design: .default)
  }

  private var forecastMedFont: Font {
    .system(size: 10, weight: .light, design: .monospaced)
  }

  private var currentDayForecastSmallBox: some View {
    LazyVGrid(columns: gridLayout(columns: 3), alignment: .trailing) {
      ForEach(entry.data.todayForecast(date: entry.date)) { forecastEntry in
        if forecastEntry.newReviews != 0 {
          Text(forecastEntry.date.time).font(forecastSmFont)
          Text("+\(forecastEntry.newReviews)").font(forecastSmFont)
          Text("\(forecastEntry.totalReviews)").font(forecastSmFont)
        }
      }
    }
  }

  private var weekForecastMediumBox: some View {
    LazyVGrid(columns: gridLayout(columns: 10, spacing: 25, -6, 6), alignment: .trailing) {
      Text("").font(forecastMedFont)
      ForEach([0, 4, 8, 12, 16, 20, 23], id: \.self) { hour in
        Text("\(hour)").font(forecastMedFont)
      }
      Text("New").font(forecastMedFont)
      Text("All").font(forecastMedFont)
      ForEach(entry.data.dailyReviewForecast(date: entry.date)) { dayForecast in
        Text(dayForecast.dayOfWeek).font(forecastMedFont)
        ForEach(dayForecast.newReviewForecast, id: \.self) { futureReviews in
          Text("+\(futureReviews.newReviews)").font(forecastMedFont)
        }
        Text("+\(String(dayForecast.newReviews))").font(forecastMedFont)
        Text("\(String(dayForecast.totalReviews))").font(forecastMedFont)
      }
    }
  }

  private var currentDayForecastDefault: some View {
    Text("No additional reviews today! \u{1F389}")
  }

  private var weekForecastDefault: some View {
    Text("No upcoming reviews this week! \u{1F389}")
  }

  var body: some View {
    if widgetFamily == .systemSmall {
      lessonReviewSmallBox
    } else if widgetFamily == .systemMedium {
      HStack {
        lessonReviewSmallBox
        Divider()
        if entry.data.reviewForecast.count > 0 { currentDayForecastSmallBox }
        else { currentDayForecastDefault }
      }
    } else {
      VStack {
        HStack {
          lessonReviewSmallBox
          if entry.data.reviewForecast.count > 0 { currentDayForecastSmallBox }
          else { currentDayForecastDefault }
        }
        Divider()
        weekForecastMediumBox
        Spacer()
      }
    }
  }
}

@main struct WidgetExtension: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "com.matthewbenedict.wanikani.Tsurukame-Widget-Extension",
                        provider: WidgetDataProvider()) { entry in
      WidgetExtensionEntryView(entry: entry)
    }
    .configurationDisplayName("Tsurukame Widget")
    .description("Displays lessons, reviews, and forecast!")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
  }
}

struct WidgetExtension_Previews: PreviewProvider {
  static var previews: some View {
    WidgetExtensionEntryView(entry: WidgetExtensionEntry(date: Date(),
                                                         data: WidgetHelper
                                                           .readProjectedData(Date())))
      .previewContext(WidgetPreviewContext(family: .systemLarge))
  }
}

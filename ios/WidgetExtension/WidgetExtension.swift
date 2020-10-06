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
    for hourOffset in 1 ... 24 {
      let _hour = Calendar.current.dateComponents([.hour], from: currentDate).hour!
      var entryDate = Calendar.current.date(bySettingHour: _hour, minute: 0, second: 0,
                                            of: currentDate)!
      entryDate += Double(3600 * hourOffset)
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

  private func formatTime(_ time: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .none
    formatter.timeStyle = .short
    return formatter.string(from: time)
  }

  private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .full
    formatter.timeStyle = .none
    return formatter.string(from: date)
  }

  private func dayOfWeek(_ date: Date) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "EEEE"
    return dateFormatter.string(from: date).capitalized
  }

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
      Text(formatTime(entry.date))
    }
  }

  private var threeColumnLayout: [GridItem] {
    // GridItem(spacing: 0), GridItem(spacing: 0), GridItem(spacing: 0)
    [GridItem(.fixed(50)),
     GridItem(.fixed(30)),
     GridItem(.fixed(30))]
  }

  private var eightColumnLayout: [GridItem] {
    // GridItem(spacing: 0), GridItem(spacing: 0), GridItem(spacing: 0)
    [GridItem(.fixed(50)),
     GridItem(.fixed(30)),
     GridItem(.fixed(30)),
     GridItem(.fixed(30)),
     GridItem(.fixed(30)),
     GridItem(.fixed(30)),
     GridItem(.fixed(30)),
     GridItem(.fixed(30))]
  }

  private var truncatedForecast: ReviewForecast {
    var workingForecast: ReviewForecast = []
    for forecastEntry in entry.data.reviewForecast {
      if formatDate(forecastEntry.date) == formatDate(entry.date) {
        workingForecast.append(forecastEntry)
      }
    }
    return workingForecast
  }

  private var currentDayForecastSmallBox: some View {
    LazyVGrid(columns: threeColumnLayout) {
      ForEach(truncatedForecast, id: \.self) { forecastEntry in
        if forecastEntry.newReviews != 0 {
          Text(formatTime(forecastEntry.date)).font(.caption2)
          Text("+\(forecastEntry.newReviews)").font(.caption2)
          Text("\(forecastEntry.totalReviews)").font(.caption2)
        }
      }
    }
  }

  private var currentDayForecastDefault: some View {
    Text("No additional reviews today! \u{1F389}")
  }

  private var weekForecastMediumBox: some View {
    LazyVGrid(columns: eightColumnLayout) {
      ForEach(entry.data.reviewForecast, id: \.self) { forecastEntry in
        if forecastEntry.newReviews != 0 {
          Text(dayOfWeek(forecastEntry.date)).font(.caption2)
          Text("+\(forecastEntry.newReviews)").font(.caption2)
          Text("\(forecastEntry.totalReviews)").font(.caption2)
        }
      }
    }
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
          currentDayForecastSmallBox
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

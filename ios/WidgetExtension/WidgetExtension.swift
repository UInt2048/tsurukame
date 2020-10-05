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
  fileprivate static func getData(_ date: Date) -> WidgetData {
    WidgetHelper.updateData(WidgetHelper.readGroupData(), date)
  }

  func placeholder(in _: Context) -> WidgetExtensionEntry {
    WidgetExtensionEntry(date: Date(), data: WidgetDataProvider.getData(Date()))
  }

  func getSnapshot(in _: Context, completion: @escaping (WidgetExtensionEntry) -> Void) {
    let entry = WidgetExtensionEntry(date: Date(), data: WidgetDataProvider.getData(Date()))
    completion(entry)
  }

  func getTimeline(in _: Context, completion: @escaping (Timeline<Entry>) -> Void) {
    var entries: [WidgetExtensionEntry] = []

    // Generate a timeline consisting of now and 24 entries an hour apart.
    let currentDate = Date()
    entries
      .append(WidgetExtensionEntry(date: currentDate,
                                   data: WidgetDataProvider.getData(currentDate)))
    for hourOffset in 1 ... 24 {
      let _hour = Calendar.current.dateComponents([.hour], from: currentDate).hour!
      var entryDate = Calendar.current.date(bySettingHour: _hour, minute: 0, second: 0,
                                            of: currentDate)!
      entryDate += Double(3600 * hourOffset)
      let entry = WidgetExtensionEntry(date: entryDate, data: WidgetDataProvider.getData(entryDate))
      entries.append(entry)
    }

    let timeline = Timeline(entries: entries, policy: .atEnd)
    completion(timeline)
  }
}

struct WidgetExtensionEntry: TimelineEntry {
  let date: Date
  let data: WidgetData
}

struct WidgetExtensionEntryView: View {
  var entry: WidgetDataProvider.Entry

  var body: some View {
    let formatter = DateFormatter()
    formatter.dateStyle = .none
    formatter.timeStyle = .short
    return Text("\(entry.data.lessons), \(entry.data.reviews)\n\(formatter.string(from: entry.date))")
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
                                                         data: WidgetDataProvider.getData(Date())))
      .previewContext(WidgetPreviewContext(family: .systemSmall))
  }
}

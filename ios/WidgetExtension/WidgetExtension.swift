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

struct Provider: IntentTimelineProvider {
  fileprivate static func getData(_ date: Date) -> WidgetData {
    WidgetHelper.updateData(WidgetHelper.readGroupData(), date)
  }

  func placeholder(in _: Context) -> SimpleEntry {
    SimpleEntry(date: Date(), data: Provider.getData(Date()), configuration: ConfigurationIntent())
  }

  func getSnapshot(for configuration: ConfigurationIntent, in _: Context,
                   completion: @escaping (SimpleEntry) -> Void) {
    let entry = SimpleEntry(date: Date(), data: Provider.getData(Date()),
                            configuration: configuration)
    completion(entry)
  }

  func getTimeline(for configuration: ConfigurationIntent, in _: Context,
                   completion: @escaping (Timeline<Entry>) -> Void) {
    var entries: [SimpleEntry] = []

    // Generate a timeline consisting of now and 24 entries an hour apart.
    let currentDate = Date()
    entries
      .append(SimpleEntry(date: currentDate, data: Provider.getData(currentDate),
                          configuration: configuration))
    for hourOffset in 1 ... 24 {
      let _hour = Calendar.current.dateComponents([.hour], from: currentDate).hour!
      var entryDate = Calendar.current.date(bySettingHour: _hour, minute: 0, second: 0,
                                            of: currentDate)!
      entryDate += Double(3600 * hourOffset)
      let entry = SimpleEntry(date: entryDate, data: Provider.getData(entryDate),
                              configuration: configuration)
      entries.append(entry)
    }

    let timeline = Timeline(entries: entries, policy: .atEnd)
    completion(timeline)
  }
}

struct SimpleEntry: TimelineEntry {
  let date: Date
  let data: WidgetData
  let configuration: ConfigurationIntent
}

struct WidgetExtensionEntryView: View {
  var entry: Provider.Entry

  var body: some View {
    Text("\(entry.data.lessons) / \(entry.data.reviews)")
  }
}

@main struct WidgetExtension: Widget {
  let kind: String = "WidgetExtension"

  var body: some WidgetConfiguration {
    IntentConfiguration(kind: kind, intent: ConfigurationIntent.self,
                        provider: Provider()) { entry in
      WidgetExtensionEntryView(entry: entry)
    }
    .configurationDisplayName("Tsurukame Widget")
    .description("Displays lessons, reviews, and forecast!")
  }
}

struct WidgetExtension_Previews: PreviewProvider {
  static var previews: some View {
    WidgetExtensionEntryView(entry: SimpleEntry(date: Date(),
                                                data: Provider.getData(Date()),
                                                configuration: ConfigurationIntent()))
      .previewContext(WidgetPreviewContext(family: .systemSmall))
  }
}

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

import Foundation
#if canImport(WidgetKit)
  import WidgetKit
#endif

public struct WidgetData: Codable {
  public var lessons: Int
  public var reviews: Int
  public var reviewForecast: [Int]
  public var date: Date
}

public enum AppGroup: String {
  case wanikani = "group.com.matthewbenedict.wanikani"

  public var containerURL: URL {
    switch self {
    case .wanikani:
      return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: rawValue)!
    }
  }
}

public class WidgetHelper {
  private static let dataURL = AppGroup.wanikani.containerURL
    .appendingPathComponent("WidgetData.plist")
  public static func readGroupData() -> WidgetData {
    if let xml = FileManager.default.contents(atPath: dataURL.absoluteString),
      let widgetData = try? PropertyListDecoder().decode(WidgetData.self, from: xml) {
      print("Data read: \(widgetData)")
      return widgetData
    }
    fatalError("Reading property list failed.")
  }

  public static func writeGroupData(_ lessons: Int, _ reviews: Int, _ reviewForecast: [Int]) {
    let _date = Date(),
      _hour = Calendar.current.dateComponents([.hour], from: _date).hour!,
      date = Calendar.current.date(bySettingHour: _hour, minute: 0, second: 0, of: _date)!
    let data = WidgetData(lessons: lessons, reviews: reviews, reviewForecast: reviewForecast,
                          date: date)
    let encoder = PropertyListEncoder()
    encoder.outputFormat = .xml
    try! encoder.encode(data).write(to: dataURL)
    print("Data written: \(lessons), \(reviews), \(reviewForecast)")
    if #available(iOS 14.0, macOS 11.0, *) {
      WidgetCenter.shared.reloadAllTimelines()
      print("Reloaded timeline!")
    }
  }

  public static func updateData(_ data: inout WidgetData, _ updateDate: Date) {
    let calendar = Calendar(identifier: .gregorian),
      entryDate = calendar.dateComponents([.year, .month, .day, .hour], from: updateDate).date!
    while data.date < entryDate {
      data.reviews += data.reviewForecast.removeFirst()
      data.date += 3600
    }
  }
}

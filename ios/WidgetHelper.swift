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

public typealias ReviewForecast = [FutureReviewCount]

public struct CodedWidgetData: Codable {
  public var lessons: Int
  public var reviews: Int
  public var reviewForecast: [Int]
  public var date: Date
}

public struct ExpandedWidgetData: Codable {
  public var lessons: Int
  public var reviews: Int
  public var reviewForecast: ReviewForecast
  public var date: Date
}

public struct FutureReviewCount: Codable, Hashable {
  public var totalReviews: Int
  public var newReviews: Int
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

  private static func generateReviewForecast(widgetData d: CodedWidgetData) -> ReviewForecast {
    let _hour = Calendar.current.dateComponents([.hour], from: d.date).hour!,
      initial = Calendar.current.date(bySettingHour: _hour, minute: 0, second: 0, of: d.date)!
    var workingDate = initial, workingForecast: ReviewForecast = [], workingReviews = d.reviews
    for newReviews in d.reviewForecast {
      workingDate += 3600
      workingReviews += newReviews
      workingForecast
        .append(FutureReviewCount(totalReviews: workingReviews, newReviews: newReviews,
                                  date: workingDate))
    }
    return workingForecast
  }

  @available(iOS 14.0, iOSApplicationExtension 14.0, macCatalyst 14.0, *)
  public static func reloadTimeline() {
    #if arch(arm64) || arch(i386) || arch(x86_64) || targetEnvironment(simulator)
      #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        print("Reloaded timeline!")
      #endif
    #endif
  }

  public static func readGroupData() -> ExpandedWidgetData {
    var d: CodedWidgetData
    if let xml = FileManager.default.contents(atPath: dataURL.absoluteString),
      let codedData = try? PropertyListDecoder().decode(CodedWidgetData.self, from: xml) {
      print("Data read: \(codedData)")
      d = codedData
    } else {
      print("Reading property list (at \(dataURL.absoluteString)) failed")
      d = CodedWidgetData(lessons: -1, reviews: -1,
                          reviewForecast: [5, 4, 0, 42, 69, 8, 3, 100, 43, 6, 0, 44], date: Date())
    }
    return ExpandedWidgetData(lessons: d.lessons, reviews: d.reviews,
                              reviewForecast: generateReviewForecast(widgetData: d),
                              date: d.date)
  }

  public static func writeGroupData(_ lessons: Int, _ reviews: Int, _ reviewForecast: [Int]) {
    let _date = Date(),
      _hour = Calendar.current.dateComponents([.hour], from: _date).hour!,
      date = Calendar.current.date(bySettingHour: _hour, minute: 0, second: 0, of: _date)!
    let data = CodedWidgetData(lessons: lessons, reviews: reviews, reviewForecast: reviewForecast,
                               date: date)
    let encoder = PropertyListEncoder()
    encoder.outputFormat = .xml
    try! encoder.encode(data).write(to: dataURL)
    print("Data written: \(lessons), \(reviews), \(reviewForecast)")
    if #available(iOS 14.0, iOSApplicationExtension 14.0, macCatalyst 14.0, *) { reloadTimeline() }
  }

  private static func projectedData(data: ExpandedWidgetData, date: Date) -> ExpandedWidgetData {
    var workingData = data, reviews = data.reviews, workingDate = date
    while workingData.reviewForecast.count > 0 {
      if workingData.reviewForecast.first!.date > Date() { break }
      let entry = workingData.reviewForecast.removeFirst()
      reviews = entry.totalReviews
      workingDate = entry.date
    }
    return ExpandedWidgetData(lessons: data.lessons, reviews: reviews,
                              reviewForecast: workingData.reviewForecast, date: workingDate)
  }

  public static func readProjectedData(_ date: Date) -> ExpandedWidgetData {
    projectedData(data: readGroupData(), date: date)
  }
}

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

public struct CodedWidgetData: Codable {
  public var lessons: Int
  public var reviews: Int
  public var reviewForecast: [Int]
  public var date: Date
}

public struct ExpandedWidgetData: Codable {
  public var lessons: Int
  public var reviews: Int
  public var reviewForecast: [FutureReviewCount]
  public var date: Date

  public func todayForecast(date: Date) -> [FutureReviewCount] {
    var workingForecast: [FutureReviewCount] = []
    for forecastEntry in reviewForecast {
      if forecastEntry.date.date == date.date {
        workingForecast.append(forecastEntry)
      }
    }
    return workingForecast
  }

  public func dailyReviewForecast(date: Date) -> [FutureDayForecast] {
    var workingDate = ""
    var dailyForecast: [FutureDayForecast] = []
    for forecastEntry in reviewForecast {
      if forecastEntry.date.date == date.date { continue }
      if forecastEntry.date.date != workingDate {
        dailyForecast
          .append(FutureDayForecast(date: forecastEntry.date, startingCount: forecastEntry))
        workingDate = forecastEntry.date.date
        continue
      }
      dailyForecast[dailyForecast.count - 1].addNewReviews(forecastEntry)
    }
    return dailyForecast
  }
}

public struct FutureReviewCount: Codable, Hashable, Identifiable {
  public var id = UUID()
  public var totalReviews: Int
  public var newReviews: Int
  public var date: Date
}

public struct FutureDayForecast: Codable, Hashable, Identifiable {
  public var id = UUID()
  public var dayOfWeek: String
  private var limitedForecast: [FutureReviewCount]
  public var newReviewForecast: [FutureReviewCount] {
    var forecast = limitedForecast
    while forecast.count < 7 {
      let hours = [0, 4, 8, 12, 16, 20, 23]
      let date = Calendar.current.date(bySettingHour: hours[limitedForecast.count], minute: 0,
                                       second: 0, of: limitedForecast.first!.date)!
      forecast.append(FutureReviewCount(totalReviews: forecast[forecast.count - 1].totalReviews,
                                        newReviews: 0, date: date))
    }
    return forecast
  }

  public var startingReviews: Int {
    (limitedForecast.first?.totalReviews ?? 0) - (limitedForecast.first?.newReviews ?? 0)
  }

  public var newReviews: Int { limitedForecast.reduce(0) { $0 + $1.newReviews } }
  public var totalReviews: Int { limitedForecast.last?.totalReviews ?? 0 }
  public init(date: Date, startingCount: FutureReviewCount) {
    dayOfWeek = date.dayOfWeek
    limitedForecast = [startingCount]
  }

  // Adds new reviews if it accepts the hour
  public mutating func addNewReviews(_ forecastEntry: FutureReviewCount) {
    let newTotalReviews = forecastEntry.totalReviews, date = forecastEntry.date
    if [0, 4, 8, 12, 16, 20, 23].contains(date.hour) {
      limitedForecast.append(FutureReviewCount(totalReviews: newTotalReviews,
                                               newReviews: newTotalReviews - totalReviews,
                                               date: date))
    }
  }
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

public extension Date {
  var hour: Int {
    Calendar.current.dateComponents([.hour], from: self).hour!
  }

  var dayOfWeek: String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "EEE"
    return dateFormatter.string(from: self).capitalized
  }

  var time: String {
    let formatter = DateFormatter()
    formatter.dateStyle = .none
    formatter.timeStyle = .short
    return formatter.string(from: self)
  }

  var date: String {
    let formatter = DateFormatter()
    formatter.dateStyle = .full
    formatter.timeStyle = .none
    return formatter.string(from: self)
  }
}

public class WidgetHelper {
  private static let dataURL = AppGroup.wanikani.containerURL
    .appendingPathComponent("WidgetData.plist")

  private static func generateReviewForecast(widgetData d: CodedWidgetData) -> [FutureReviewCount] {
    let _hour = Calendar.current.dateComponents([.hour], from: d.date).hour!,
      initial = Calendar.current.date(bySettingHour: _hour, minute: 0, second: 0, of: d.date)!
    var workingDate = initial, workingForecast: [FutureReviewCount] = [], workingReviews = d.reviews
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
    #if canImport(WidgetKit)
      WidgetCenter.shared.reloadAllTimelines()
      print("Reloaded timeline!")
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
                          reviewForecast: [
                            5,
                            4,
                            0,
                            42,
                            69,
                            8,
                            3,
                            100,
                            43,
                            6,
                            0,
                            44,
                            15,
                            36,
                            5,
                            97,
                            26,
                            25,
                            41,
                            24,
                            48,
                            6,
                            97,
                            69,
                            71,
                            92,
                            35,
                            54,
                            90,
                            68,
                            50,
                            28,
                            15,
                            9,
                            78,
                            85,
                            10,
                            87,
                            47,
                            49,
                            45,
                            45,
                            79,
                            63,
                            69,
                            61,
                            51,
                            33,
                            92,
                            88,
                            43,
                            11,
                            90,
                            43,
                            20,
                            92,
                            41,
                            89,
                            12,
                            33,
                            75,
                            64,
                            53,
                            25,
                            90,
                            13,
                            86,
                            78,
                            56,
                            20,
                            87,
                            31,
                            34,
                            75,
                            46,
                            66,
                            6,
                            69,
                            63,
                            52,
                            79,
                            79,
                            9,
                            17,
                            11,
                            95,
                            5,
                            47,
                            17,
                            100,
                            75,
                            9,
                            74,
                            22,
                            97,
                            52,
                            39,
                            47,
                            85,
                            11,
                            43,
                            1,
                            65,
                            57,
                            95,
                            34,
                            12,
                            42,
                            62,
                            48,
                            16,
                            5,
                          ], date: Date())
    }
    return ExpandedWidgetData(lessons: d.lessons, reviews: d.reviews,
                              reviewForecast: generateReviewForecast(widgetData: d),
                              date: d.date)
  }

  public static func writeGroupData(_ lessons: Int, _ reviews: Int, _ reviewForecast: [Int]) {
    let _date = Date(),
      date = Calendar.current.date(bySettingHour: _date.hour, minute: 0, second: 0, of: _date)!
    let data = CodedWidgetData(lessons: lessons, reviews: reviews, reviewForecast: reviewForecast,
                               date: date)
    let encoder = PropertyListEncoder()
    encoder.outputFormat = .xml
    print("Attempting to write to \(dataURL)")
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

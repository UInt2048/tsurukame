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

public struct WidgetData: Codable {
  public var lessons: Int
  public var reviews: Int
  public var reviewForecast: [Int]
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
      let preferences = try? PropertyListDecoder().decode(WidgetData.self, from: xml) {
      return preferences
    }
    fatalError("Reading property list failed.")
  }

  public static func writeGroupData(_ lessons: Int, _ reviews: Int, _ reviewForecast: [Int]) {
    let data = WidgetData(lessons: lessons, reviews: reviews, reviewForecast: reviewForecast)
    let encoder = PropertyListEncoder()
    encoder.outputFormat = .xml
    try! encoder.encode(data).write(to: dataURL)
  }
}

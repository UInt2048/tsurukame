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

import NotificationCenter
import UIKit

private class Widget {
  var date: Date
  var data: ExpandedWidgetData
  var expanded: Bool

  init(date: Date, data: ExpandedWidgetData, size: CGSize) {
    self.date = date
    self.data = data
    expanded = size.height > 200
  }

  var lessonReviewSmallBox: UIStackView {
    VStack {
      HStack {
        Text("\(data.lessons)").font(UIFont.getFont(size: 34.0, weight: .bold))
        Text("\(data.reviews)").font(UIFont.getFont(size: 34.0, weight: .bold))
      }
      HStack {
        Text("Lessons").font(UIFont.preferredFont(forTextStyle: .subheadline))
        Text("Reviews").font(UIFont.preferredFont(forTextStyle: .subheadline))
      }
      Text(date.time)
    }
  }

  var currentDayForecastSmallBox: UITableView {
    VGrid(columns: 3) {
      ForEach(data.todayForecast(date: date)) { forecastEntry in
        if forecastEntry.newReviews != 0 {
          let forecastSmFont = UIFont.getFont(size: 11, weight: .light)
          Text(forecastEntry.date.time).font(forecastSmFont)
          Text("+\(forecastEntry.newReviews)").font(forecastSmFont)
          Text("\(forecastEntry.totalReviews)").font(forecastSmFont)
        }
      }
    }
  }

  let forecastMedFont = UIFont.getFont(size: 10, weight: .light)

  func forecastText(dayForecast: FutureDayForecast) -> [UILabel] {
    var result: [UILabel] = []
    result.append(Text(dayForecast.dayOfWeek).font(forecastMedFont))
    for futureReviews in dayForecast.newReviewForecast {
      result.append(Text("+\(futureReviews.newReviews)").font(forecastMedFont))
    }
    result.append(Text("+\(String(dayForecast.newReviews))").font(forecastMedFont))
    result.append(Text("\(String(dayForecast.totalReviews))").font(forecastMedFont))
    return result
  }

  var weekForecastMediumBox: UITableView {
    VGrid(columns: 10) {
      ForEach(["", "0", "4", "8", "12", "16", "20", "23", "New", "All"]) { header in
        Text(header).font(forecastMedFont)
      }
      ForEach(data.dailyReviewForecast(date: date)) { dayForecast in
        forecastText(dayForecast: dayForecast)
      }
    }
  }

  var body: UIStackView {
    if expanded {
      return VStack {
        HStack {
          lessonReviewSmallBox
          currentDayForecastSmallBox
        }
        weekForecastMediumBox
      }
    } else {
      return HStack {
        lessonReviewSmallBox
        currentDayForecastSmallBox
      }
    }
  }
}

class TodayViewController: UIViewController, NCWidgetProviding {
  func updateWidget() {
    print("Attempting to update widget")
    let widget = Widget(date: Date(), data: WidgetHelper.readProjectedData(Date()),
                        size: preferredContentSize)
    view.addSubview(widget.body)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    print("Today View widget loaded!")
  }

  override func viewWillAppear(_: Bool) {
    extensionContext?.widgetLargestAvailableDisplayMode = .expanded
    print("Today View widget will appear...")
    updateWidget()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    updateWidget()
  }

  override func loadView() {
    view = UIView(frame: CGRect(x: 0.0, y: 0, width: 320.0, height: 200.0))
  }

  func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode,
                                        withMaximumSize maxSize: CGSize) {
    let expanded = activeDisplayMode == .expanded
    preferredContentSize = expanded ? CGSize(width: maxSize.width, height: 200) : maxSize
  }
}

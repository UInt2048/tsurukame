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

private extension UIFont {
  static func getFont(size: CGFloat, weight: UIFont.Weight, monospace: Bool = true) -> UIFont {
    if monospace {
      return UIFont.monospacedDigitSystemFont(ofSize: size, weight: weight)
    } else {
      return UIFont.systemFont(ofSize: size, weight: weight)
    }
  }
}

private extension UILabel {
  func font(_ font: UIFont) -> UILabel {
    self.font = font
    return self
  }
}

private class TableViewSource: NSObject, UITableViewDataSource {
  var columns: Int
  var rows: Int
  var labels: [UILabel]

  func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int { rows }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView
      .dequeueReusableCell(withIdentifier: "\(indexPath.section)-\(indexPath.row)",
                           for: indexPath)
    let view = labels[indexPath.section + indexPath.row * columns]
    cell.textLabel?.text = view.text
    cell.textLabel?.font = view.font
    return cell
  }

  init(columns: Int, rows: Int, labels: [UILabel]) {
    self.columns = columns
    self.rows = rows
    self.labels = labels
  }
}

@_functionBuilder struct LabelBuilder {
  static func buildBlock(_ labels: UILabel...) -> [UILabel] { labels }
  static func buildBlock(_ labels: [UILabel]...) -> [UILabel] { labels.flatMap { $0 } }
  static func buildBlock(_ labels: [[UILabel]]...) -> [UILabel] { labels.flatMap { $0 }
    .flatMap { $0 }
  }

  static func buildOptional(_ labels: UILabel?...) -> [UILabel] { labels }
  static func buildOptional(_ labels: [UILabel]?...) -> [UILabel] { labels ?? [] }
}

@_functionBuilder struct StackBuilder {
  static func buildBlock(_ views: UIView...) -> UIStackView {
    UIStackView(arrangedSubviews: views)
  }
}

func VGrid(columns: Int, @LabelBuilder _ content: () -> [UILabel]) -> UITableView {
  let view = UITableView(), labels = content()
  let rows = Int(ceil(Double(labels.count) / Double(columns))),
    dataSource = TableViewSource(columns: columns, rows: rows, labels: labels)
  view.dataSource = dataSource
  return view
}

func HStack(@StackBuilder _ content: () -> UIStackView) -> UIStackView {
  let view = content()
  view.axis = .horizontal
  return view
}

func VStack(@StackBuilder _ content: () -> UIStackView) -> UIStackView {
  let view = content()
  view.axis = .vertical
  return view
}

func Text(_ text: String) -> UILabel {
  let label = UILabel()
  label.text = text
  return label
}

func ForEach<Data: RandomAccessCollection>(_ array: Data,
                                           @LabelBuilder _ content: (Data.Element) -> [UILabel])
  -> [UILabel] {
  var combinedArray: [UILabel]
  for element in array {
    combinedArray.append(contentsOf: content(element))
  }
  return combinedArray
}

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

  var weekForecastMediumBox: UITableView {
    VGrid(columns: 10) {
      let forecastMedFont = UIFont.getFont(size: 10, weight: .light)
      ForEach(["", "0", "4", "8", "12", "16", "20", "23", "New", "All"]) { header in
        Text(header).font(forecastMedFont)
      }
      ForEach(entry.data.dailyReviewForecast(date: entry.date)) { dayForecast in
        Text(dayForecast.dayOfWeek).font(forecastMedFont)
        ForEach(dayForecast.newReviewForecast) { futureReviews in
          Text("+\(futureReviews.newReviews)").font(forecastMedFont)
        }
        Text("+\(String(dayForecast.newReviews))").font(forecastMedFont)
        Text("\(String(dayForecast.totalReviews))").font(forecastMedFont)
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
    view.addSubview(widget.lessonReviewSmallBox)
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

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

extension UIFont {
  static func getFont(size: CGFloat, weight: UIFont.Weight, monospace: Bool = true) -> UIFont {
    if monospace {
      return UIFont.monospacedDigitSystemFont(ofSize: size, weight: weight)
    } else {
      return UIFont.systemFont(ofSize: size, weight: weight)
    }
  }
}

extension UILabel {
  func font(_ font: UIFont) -> UILabel {
    self.font = font
    return self
  }
}

class TableViewSource: NSObject, UITableViewDataSource {
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

  static func buildOptional(_ labels: UILabel?...) -> [UILabel] {
    var array: [UILabel] = []
    for optionalLabel in labels {
      if let label = optionalLabel { array.append(label) }
    }
    return array
  }

  static func buildOptional(_ labels: [UILabel]?...) -> [UILabel] {
    var array: [UILabel] = []
    for optionalLabels in labels {
      if let labels = optionalLabels { array.append(contentsOf: labels) }
    }
    return array
  }
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
  var combinedArray: [UILabel] = []
  for element in array {
    combinedArray.append(contentsOf: content(element))
  }
  return combinedArray
}

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

class TodayViewController: UIViewController, NCWidgetProviding {
  @IBOutlet var reviewLabel: UILabel!

  func updateWidget() {
    print("Attempting to update widget")
    let data = WidgetHelper.readProjectedData(Date())
    reviewLabel.text = "\(data.lessons) / \(data.reviews)"
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

  func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode,
                                        withMaximumSize maxSize: CGSize) {
    let expanded = activeDisplayMode == .expanded
    preferredContentSize = expanded ? CGSize(width: maxSize.width, height: 200) : maxSize
  }
}

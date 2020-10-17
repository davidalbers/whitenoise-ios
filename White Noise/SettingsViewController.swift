import Foundation
import UIKit

@available(iOS 13.0, *)
class SettingsViewController: UIViewController {
    var themer = Themer()
    var rootVC: ViewController?
    @IBOutlet weak var themeSegmentedControl: UISegmentedControl!
    
    override func viewDidLoad() {
        updateThemeForViewController(self)
        themeSegmentedControl.selectedSegmentIndex = themer.getTheme().rawValue
    }
    
    @IBAction func themeChanged(_ sender: UISegmentedControl) {
        themer.saveTheme(Themer.Theme.init(rawValue: sender.selectedSegmentIndex))
        updateThemeForViewController(self)
        if let vc = rootVC { updateThemeForViewController(vc) }
    }
    
    @IBAction func done(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    private func updateThemeForViewController(_ viewController: UIViewController) {
        viewController.overrideUserInterfaceStyle = themer.getUIUserInterfaceStyle()
        viewController.setNeedsStatusBarAppearanceUpdate()
        viewController.view.setNeedsDisplay()
    }
}

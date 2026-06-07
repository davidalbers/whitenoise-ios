import UIKit

extension UIColor {
    func lightened(by amount: CGFloat = 0.18) -> UIColor {
        var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
        getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        return UIColor(hue: hue, saturation: max(0, saturation - amount * 0.5), brightness: min(1, brightness + amount), alpha: alpha)
    }
}

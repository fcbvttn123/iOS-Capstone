import UIKit

/// Utility class to create reusable back buttons for navigation.
class BackButtonManager {
    
    /// Creates a back button and attaches an action to it.
    /// - Parameters:
    ///   - target: The target object that implements the action.
    ///   - action: The selector to invoke when the button is tapped.
    /// - Returns: A configured `UIBarButtonItem` instance.
    static func createBackButton(target: Any?, action: Selector) -> UIBarButtonItem {
        return UIBarButtonItem(title: "Back", style: .plain, target: target, action: action)
    }
}

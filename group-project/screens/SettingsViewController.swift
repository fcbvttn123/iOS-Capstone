//
//  SettingsViewController.swift
//  group-project
//
//  Created by Default User on 10/3/24.
//

import UIKit

class SettingsViewController: UIViewController {
    
    @IBOutlet weak var darkModeSwitch: UISwitch!
    @IBOutlet weak var textSizeSlider: UISlider!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        darkModeSwitch.isOn = UserDefaults.standard.bool(forKey: "darkModeEnabled")
        textSizeSlider.value = UserDefaults.standard.float(forKey: "textSize")
        updateTextSize()
        updateAppearance()
        // Do any additional setup after loading the view.
    }
    
    
    @IBAction func darkModeToggled(_ sender: UISwitch) {
        let isDarkMode = sender.isOn
            UserDefaults.standard.set(isDarkMode, forKey: "darkModeEnabled")
            
            // Update app appearance
            if isDarkMode {
                overrideUserInterfaceStyle = .dark
            } else {
                overrideUserInterfaceStyle = .light
            }
            
            // Post notification for appearance change
            NotificationCenter.default.post(name: Notification.Name("AppearanceChanged"), object: nil)
    }
    private func updateAppearance() {
        let isDarkMode = UserDefaults.standard.bool(forKey: "darkModeEnabled")
        overrideUserInterfaceStyle = isDarkMode ? .dark : .light
    }
    
    @IBAction func textSizeChanged(_ sender: UISlider) {
        let textSize = sender.value
        UserDefaults.standard.set(textSize, forKey: "textSize")
        updateTextSize()
    }

    private func updateTextSize() {
        let textSize = UserDefaults.standard.float(forKey: "textSize")
        // Update font sizes throughout your app as needed
        // Example: someLabel.font = UIFont.systemFont(ofSize: CGFloat(textSize))
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

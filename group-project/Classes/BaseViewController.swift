//
//  BaseViewController.swift
//  group-project
//
//  Created by Default User on 10/6/24.
//

import UIKit

class BaseViewController: UIViewController {
    override func viewDidLoad() {
            super.viewDidLoad()
            
            // Add observer for appearance changes
            NotificationCenter.default.addObserver(self, selector: #selector(updateAppearance), name: Notification.Name("AppearanceChanged"), object: nil)
        }

        deinit {
            // Remove observer when the view controller is deallocated
            NotificationCenter.default.removeObserver(self)
        }
    
    override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            updateAppearance()
        }

    @objc func updateAppearance() {
            let isDarkMode = UserDefaults.standard.bool(forKey: "darkModeEnabled")
            print("Dark Mode Enabled: \(isDarkMode)")
            overrideUserInterfaceStyle = isDarkMode ? .dark : .light
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

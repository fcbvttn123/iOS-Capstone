import UIKit
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    // Currently Signed-in User Information
    var isLoggedIn: Bool = false
    var givenName: String = ""
    var imgUrl: String? = ""
    var dob = ""
    
    var email: String? = ""
    var isEmailVerified: Bool = false
    var college: String? = ""
    var country: String? = ""
    var username: String? = ""
    var currentUserUID: String!
    var userDomain: String? = ""
    var collegeWebsite: String? = ""
    
    static let shared = AppDelegate()
    
    // Firestore reference
    private var db: Firestore?

    // Notification Permission
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert,
            .sound, .badge]) {(granted, error) in
                if granted {
                            DispatchQueue.main.async {
                                UIApplication.shared.registerForRemoteNotifications()
                            }
                        }
                        else
                        {
                            print("Permission for push notifications denied.")
                        }
                        
        }
        
        FirebaseApp.configure()
        
        // Initialize Firestore after configuring Firebase
        db = Firestore.firestore()
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
                let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
                print("Device Token: \(token)")
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
               // Handle the notification and perform necessary actions
               completionHandler()
       }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
    
}


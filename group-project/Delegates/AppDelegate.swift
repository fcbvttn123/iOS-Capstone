import UIKit
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

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

    // System Generated
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        
        // Initialize Firestore after configuring Firebase
        db = Firestore.firestore()
        
        return true
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
    
}


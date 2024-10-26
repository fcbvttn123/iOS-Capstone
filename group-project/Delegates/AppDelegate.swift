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
    var currentUserUID: String?
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
    
    // Fetches user data from Firestore based on the email as document ID
    func fetchUserData(completion: @escaping (Bool) -> Void) {
        guard let email = self.email else {
            completion(false)
            return
        }
        
        // Ensure Firestore is initialized
        guard let db = db else {
            print("Firestore is not initialized.")
            completion(false)
            return
        }
        
        // Access Firestore collection 'users' and check if a document exists with ID 'email'
        db.collection("users").document(email).getDocument { (document, error) in
            if let error = error {
                print("Error fetching user document: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            // Check if the document exists
            if let document = document, document.exists {
                // Update properties with the fetched data
                self.username = document.get("username") as? String ?? ""
                self.college = document.get("college") as? String ?? ""
                self.country = document.get("country") as? String ?? ""
                self.dob = document.get("dob") as? String ?? ""
                self.imgUrl = document.get("imgUrl") as? String ?? ""
                self.userDomain = document.get("userDomain") as? String ?? ""
                self.collegeWebsite = document.get("collegeWebsite") as? String ?? ""
                print("User data successfully fetched and updated.")
                completion(true)
            } else {
                print("No user document found with this email.")
                completion(false)
            }
        }
    }
}


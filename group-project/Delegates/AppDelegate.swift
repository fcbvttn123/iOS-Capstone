import UIKit

// Created by David
// These Imports are used for Firebase - Authentication
import FirebaseCore
import FirebaseAuth

//Created by David
// These Imports are used for Firebase - Firestore Database
import FirebaseFirestore

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    // Currently Sign-in User Information
    // Will be changed after successful sign-in
    var isLoggedIn: Bool = false
    var username: String = ""
    var givenName: String = ""
    var imgUrl: URL?
    var college = ""
    var dob = ""
    var currentUserUID: String?
    
    var email: String? = ""
    var isEmailVerified : Bool = false
    
    static let shared = AppDelegate()
    
    // Created by David
    // This function is used to fetch all account information from firestore
    // This function is mostly used for checkCredentials() function
    func fetchAccountInformationFromFirestore() async throws -> [String: Any] {
        let collection = Firestore.firestore().collection("accounts")
        let querySnapshot = try await collection.getDocuments()
        var data = [String: Any]()
        for document in querySnapshot.documents {
            data[document.documentID] = document.data()
        }
        return data
    }
    
    // System Generated
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Created by David
        // This code is used to configure Google Firebase
        FirebaseApp.configure()
        
        return true
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }


}



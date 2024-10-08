//
//  SceneDelegate.swift
//  group-project
//
//  Created by Default User on 3/13/24.
//

import UIKit
import StreamChat
import StreamChatUI
import FirebaseCore
import GoogleSignIn
import FirebaseAuth
import FirebaseFirestore

// Creataed by David
struct LoginResponse: Codable {
    let id: String
    let username: String
    let token: String
}

func applyChatCustomizations() {
    Appearance.default.colorPalette.background6 = .green
    Appearance.default.images.sendArrow = UIImage(systemName: "arrowshape.turn.up.right")!
    Components.default.channelVC = DemoChannelVC.self
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }
        
        // Chat Feature - Created by David
        applyChatCustomizations()
        var username = "david"
        var firstTimeLogIn = false
        Task {
            do {
                let usernames = try await fetchUsernames()
                // Check if the username exists
                if usernames.contains(username) {
                    firstTimeLogIn = false
                } else {
                    firstTimeLogIn = true
                    try await addUserToFirestore(username: username)
                }
                loginUser(username: username, firstTimeLogIn: firstTimeLogIn) { result in
                    switch result {
                    case .success(let response):
                        print("Login successful!")
                        print("User ID: \(response.id)")
                        print("Token: \(response.token)")
                        
                        // Store the token or use it for your chat API calls
                        self.connectChatUser(
                            userId: response.id,
                            userName: response.id,
                            token: try! Token(rawValue: response.token),
                            imageUrl: "https://images.app.goo.gl/sZkqZcyAopghZMgo9"
                        )
                    case .failure(let error):
                        print("Login failed with error: \(error.localizedDescription)")
                    }
                }
            } catch {
                print("Error fetching usernames: \(error.localizedDescription)")
            }
        }
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
    
    // Created by David
    func connectChatUser(userId: String, userName: String, token: Token, imageUrl: String) {
        let chatClient = ChatManager.shared.chatClient
        let userInfo = UserInfo(
            id: userId,
            name: userName,
            imageURL: URL(string: imageUrl)
        )

        chatClient.connectUser(userInfo: userInfo, token: token) { error in
            if let error = error {
                print("Error connecting user \(userName): \(error.localizedDescription)")
            } else {
                print("User \(userName) connected successfully.")
            }
        }
    }
    
    // Created by David
    func loginUser(username: String, firstTimeLogIn: Bool, completion: @escaping (Result<LoginResponse, Error>) -> Void) {
        // 1. Prepare the URL
        guard let url = URL(string: "https://react-chat-app-v2.onrender.com/api/auth/login") else {
            print("Invalid URL")
            return
        }
        
        // 2. Prepare the request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 3. Prepare the POST body data
        let body: [String: Any] = [
            "username": username,
            "firstTimeLogIn": firstTimeLogIn
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            print("Failed to serialize JSON")
            return
        }
        
        // 4. Send the request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // 5. Handle the error
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // 6. Handle the response
            guard let data = data else {
                print("No data received")
                return
            }
            
            // 7. Decode the JSON response
            do {
                let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
                completion(.success(loginResponse))
            } catch {
                completion(.failure(error))
            }
        }
        
        // 8. Start the network task
        task.resume()
    }
    
    //Created by David
    func fetchUsernames() async throws -> [String] {
        let collection = Firestore.firestore().collection("chat-test")
        let querySnapshot = try await collection.getDocuments()
        var usernames = [String]()

        for document in querySnapshot.documents {
            if let username = document.data()["username"] as? String { // Accessing the username field
                usernames.append(username)
            }
        }
        return usernames
    }
    
    // Created by David
    func addUserToFirestore(username: String) async throws {
        let db = Firestore.firestore()
        let collection = db.collection("chat-test") // Your Firestore collection
        
        // Create a new document with the username field
        try await collection.document(username).setData([
            "username": username
        ])
        
        print("User \(username) added to Firestore successfully!")
    }

}


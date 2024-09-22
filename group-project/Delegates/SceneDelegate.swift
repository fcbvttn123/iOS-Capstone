//
//  SceneDelegate.swift
//  group-project
//
//  Created by Default User on 3/13/24.
//

import UIKit
import StreamChat
import StreamChatUI

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
        
        // Chat Feature
        applyChatCustomizations()
        let chatClient = ChatManager.shared.chatClient
        
        let userId = "david"
        let token: Token =
                "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiZGF2aWQifQ.cy9cqFhPJRyxhLwwEmmk6t8AQmG26CztBh6H3UdySvg"
        let userId2 = "peter"
        let token2: Token =
                "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoicGV0ZXIifQ.453u2mILSHhnbcjFhvPhqXtjnT87A5pIDqe6UlWMT2Y"
        
        /*
        chatClient.connectUser(
            userInfo: UserInfo(
                id: userId,
                name: userId,
                imageURL: URL(string: "https://images.app.goo.gl/r3w1DyHsraFETzZN6")
            ),
            token: token
        )
         */
        chatClient.connectUser(
            userInfo: UserInfo(
                id: userId2,
                name: userId2,
                imageURL: URL(string: "https://images.app.goo.gl/sZkqZcyAopghZMgo9")
            ),
            token: token2
        )
          
        

        do {
            let channelController = try chatClient.channelController(
                createDirectMessageChannelWith: [userId, userId2],
                extraData: [:]
            )
            
            // Synchronize the channel
            channelController.synchronize { error in
                if let error = error {
                    print("Error synchronizing channel: \(error.localizedDescription)")
                } else {
                    print("Channel synchronized successfully!")
                }
            }
        } catch {
            print("Error creating channel: \(error.localizedDescription)")
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


}


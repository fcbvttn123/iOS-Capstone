//
//  ChatManager.swift
//  group-project
//
//  Created by Default User on 9/22/24.
//

import Foundation
import StreamChat

class ChatManager {
    static let shared = ChatManager()
    let chatClient: ChatClient
    private init() {
        let config = ChatClientConfig(apiKeyString: "API Key")
        chatClient = ChatClient(config: config)
    }
}

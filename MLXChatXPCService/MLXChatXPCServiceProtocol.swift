//
//  MLXChatXPCServiceProtocol.swift
//  MLXChatXPCService
//
//  Created by Alfian Losari on 22/02/24.
//

import Foundation

let xpcServiceLabel = "com.xca.MLXChatXPCService"

@objc protocol MLXChatXPCServiceProtocol {
    
    func prompt(text: String, model: String, maxTokens: Int, temperature: Float, seed: UInt64, completion: @escaping (Error?) -> Void)
    func stopResponse()
}

@objc protocol MLXChatClientProtocol {

    func tokenReceived(t: String)

}

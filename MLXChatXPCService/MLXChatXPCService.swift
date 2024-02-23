//
//  MLXChatXPCService.swift
//  MLXChatXPCService
//
//  Created by Alfian Losari on 22/02/24.
//

import Foundation

class MLXChatXPCService: NSObject, NSXPCListenerDelegate, MLXChatXPCServiceProtocol {

    
    let listener : NSXPCListener
    var connection : NSXPCConnection?
    var mlxChat: MLXChat?
        
    override init() {
        listener = NSXPCListener(machServiceName: xpcServiceLabel)
        super.init()
        listener.delegate = self
    }
    
    func start() { listener.resume() }
    func stop() { listener.suspend() }
    
    var clientApp : MLXChatClientProtocol {
        connection!.remoteObjectProxyWithErrorHandler { err in
            print(err)
        } as! MLXChatClientProtocol
    }

    // MARK: NSXPCListenerDelegate

    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        // Set the exported object of the new connection to be ourself
        newConnection.exportedObject = self
        
        // Specify the interface the exported object will conform to
        newConnection.exportedInterface = NSXPCInterface(with: MLXChatXPCServiceProtocol.self)
        
        // Set the XPC interface of the connection's remote object using the client app's protocol
        newConnection.remoteObjectInterface = NSXPCInterface(with: MLXChatClientProtocol.self)
        
        // New connection start in a suspended state and must be resumed
        newConnection.resume()
        
        // Retain a reference to the new connection for use later
        connection = newConnection
        
        // Always accept the incoming connection
        return true
    }
    
    @objc func prompt(text: String, model: String, maxTokens: Int, temperature: Float, seed: UInt64, completion: @escaping (Error?) -> Void) {
        Task { @MainActor [unowned self] in
            self.mlxChat = MLXChat(maxTokens: maxTokens, temperature: temperature, seed: seed)
            do {
                try self.mlxChat?.promptModel(text: text, model: model) {
                    self.clientApp.tokenReceived(t: $0)
                }
                completion(nil)
            } catch {
                print(error.localizedDescription)
                completion(error)
            }
            exit(0)
        }
    }
    


    
    @objc func stopResponse() {
        self.mlxChat?.isCancelled = true
    }
}


extension String: Error {}

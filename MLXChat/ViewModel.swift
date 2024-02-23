//
//  ConnectionVM.swift
//  MLXChat
//
//  Created by Alfian Losari on 22/02/24.
//

import Observation
import Foundation

@Observable
class ViewModel: NSObject, MLXChatClientProtocol {
    
    private var _connection: NSXPCConnection!
    var messages: [MessageRow] = []
    var model: URL? // URL(string: "file://Users/alfianlosari/Mistral-7B-v0.1-hf-4bit-mlx")!
    var inputMessage = ""
    var isPrompting = false
    var maxTokens: Float = 250
    var temperature = 0.5
    var seed: Double = Double.random(in: 0...99999)
    
    func doSomething() {}
    
    private func establishConnection() -> Void {
        _connection = NSXPCConnection(serviceName: xpcServiceLabel)
        _connection.remoteObjectInterface = NSXPCInterface(with: MLXChatXPCServiceProtocol.self)

        _connection.exportedObject = self
        _connection.exportedInterface = NSXPCInterface(with: MLXChatClientProtocol.self)

        _connection.interruptionHandler = {
          NSLog("connection to XPC service has been interrupted")
        }
        _connection.invalidationHandler = {
          NSLog("connection to XPC service has been invalidated")
          self._connection = nil
        }
        _connection.resume()

        NSLog("successfully connected to XPC service")
    }

    public func xpcService() -> MLXChatXPCServiceProtocol {
        if _connection == nil {
            NSLog("no connection to XPC service")
            establishConnection()
        }
        
        return _connection.remoteObjectProxyWithErrorHandler { err in
            print(err)
        } as! MLXChatXPCServiceProtocol
    }
    
    func invalidateConnection() -> Void {
        guard _connection != nil else { NSLog("no connection to invalidate"); return }
        _connection.invalidate()
    }
    
    func prompt(_ prompt: String) {
        let text = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        isPrompting = true
        self.inputMessage = ""
        
        
        var messageRow = MessageRow(
            isInteracting: true,
            sendImage: "profile",
            send: .rawText(text),
            responseImage: "bot",
            response: .rawText(""),
            responseError: nil)
        
        defer { self.messages.append(messageRow) }

        guard let model else { 
            messageRow.isInteracting = false
            messageRow.responseError = "Please select a folder containing the LocalLLM model first. You can get it from https://huggingface.co/mlx-community"
            return
        }
        
        
        
        xpcService().prompt(text: text, model: model.absoluteString, maxTokens: Int(maxTokens), temperature: Float(temperature), seed: UInt64(seed)) { error in
            DispatchQueue.main.async { [unowned self] in
                self.updateLastMessageInList { message in
                    message.isInteracting = false
                    if let error = error {
                        message.responseError = error.localizedDescription
                    } else {
                        message.response = .rawText(message.responseText?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")
                    }
                }
                self.isPrompting = false
                self.invalidateConnection()
            }
        }
    }
    
    func retry(message: MessageRow) {
        guard let index = messages.firstIndex(where: { $0.id == message.id }) else {
            return
        }
        self.messages.remove(at: index)
        self.prompt(message.sendText)
    }
    
    func tokenReceived(t: String) {
        DispatchQueue.main.async { [unowned self] in
            updateLastMessageInList { message in
                let text = message.responseText ?? ""
                message.response = .rawText(text + t)
            }
        }
    }
    
    func sendTapped() {
        prompt(self.inputMessage)
    }
    
    func clearMessages() {
        self.messages = []
    }
    
    func cancelStreamingResponse() {
        self.xpcService().stopResponse()
        self.isPrompting = false
        updateLastMessageInList { message in
            message.responseError = "Cancelled"
            message.isInteracting = false
        }
    }
    
    func updateLastMessageInList(updateHandler: (inout MessageRow) -> Void) {
        var messageRow = messages[self.messages.count - 1]
        updateHandler(&messageRow)
        self.messages[self.messages.count - 1] = messageRow
    }
    
}
//
//  MLXChat.swift
//  MLXChatXPCService
//
//  Created by Alfian Losari on 22/02/24.
//

import Foundation
import Llama
import MLX
import MLXRandom

class MLXChat {
        
    var maxTokens: Int
    var temperature: Float
    var seed: UInt64
    var isCancelled = false

    init(maxTokens: Int = 500, temperature: Float = 0.0, seed: UInt64 = 0) {
        self.maxTokens = maxTokens
        self.temperature = temperature
        self.seed = seed
    }

    func promptModel(text: String, model: String, callback: @escaping (String) -> ()) throws  {
        MLXRandom.seed(seed)
        
        let (model, tokenizer ) = try load(modelDirectory: URL(filePath: model))

        print("Starting generation ...")
        print(text, terminator: "")

        var start = Date.timeIntervalSinceReferenceDate
        var promptTime: TimeInterval = 0

        let prompt = try MLXArray(tokenizer.encode(text))

        var ntok = 0
        for token in TokenIterator(prompt: prompt, model: model, temp: temperature) {
            if ntok == 0 {
                eval(token)
                let now = Date.timeIntervalSinceReferenceDate
                promptTime = now - start
                start = now
            }

            eval(token)
            let ids = [token.asType(TokenId.self).item(TokenId.self)]
            let s = try tokenizer.decode(ids)
            print(s, terminator: "")
            callback(s)
            fflush(stdout)
            
            ntok += ids.count
            if ntok == maxTokens  || isCancelled {
                break
            }
        }

        print()
        print("------")
        let now = Date.timeIntervalSinceReferenceDate
        let generateTime = now - start

        print(
            """
            Prompt Tokens per second:     \((Double(prompt.size) / promptTime).formatted())
            Generation tokens per second: \((Double(ntok - 1) / generateTime).formatted())
            """)
    }

}

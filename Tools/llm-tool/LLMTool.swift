// Copyright © 2024 Apple Inc.

import ArgumentParser
import Foundation
import Llama
import MLX
import MLXRandom

struct LLMTool: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "Command line tool for generating text using Llama models",
        subcommands: [SyncGenerator.self, AsyncGenerator.self],
        defaultSubcommand: SyncGenerator.self)
}

@main
struct SyncGenerator: ParsableCommand {

    static var configuration = CommandConfiguration(
        commandName: "sync",
        abstract: "Synchronous generator"
    )

    @Option(name: .long, help: "Path to the directory with the model and tokenizer weights")
    var model: String

    @Option(name: .shortAndLong, help: "The message to be processed by the model")
    var prompt = "hello"

    @Option(name: .shortAndLong, help: "Maximum number of tokens to generate")
    var maxTokens = 10000

    @Option(name: .shortAndLong, help: "The sampling temperature")
    var temperature: Float = 0.0

    @Option(name: .long, help: "The PRNG seed")
    var seed: UInt64 = 0

    func run() throws {
        MLXRandom.seed(seed)

        let (model, tokenizer) = try load(modelDirectory: URL(filePath: model))

        print("Starting generation ...")
        print(prompt, terminator: "")

        var start = Date.timeIntervalSinceReferenceDate
        var promptTime: TimeInterval = 0

        let prompt = try MLXArray(tokenizer.encode(prompt))

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
            fflush(stdout)

            ntok += ids.count
            if ntok == maxTokens {
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

/// Example of an async generator.
///
/// Note that all of the computation is done on another thread and TokenId (Int32) are sent
/// rather than MLXArray.
struct AsyncGenerator: AsyncParsableCommand {

    static var configuration = CommandConfiguration(
        commandName: "async",
        abstract: "async generator"
    )

    @Option(name: .long, help: "Path to the directory with the model and tokenizer weights")
    var model: String

    @Option(name: .shortAndLong, help: "The message to be processed by the model")
    var prompt = "hello"

    @Option(name: .shortAndLong, help: "Maximum number of tokens to generate")
    var maxTokens = 100

    @Option(name: .shortAndLong, help: "The sampling temperature")
    var temperature: Float = 0.0

    @Option(name: .long, help: "The PRNG seed")
    var seed: UInt64 = 0

    func run() async throws {
        MLXRandom.seed(seed)

        let (model, tokenizer) = try load(modelDirectory: URL(filePath: model))

        print("Starting generation ...")
        print(prompt, terminator: "")

        var start = Date.timeIntervalSinceReferenceDate
        var promptTime: TimeInterval = 0

        let prompt = try MLXArray(tokenizer.encode(prompt))

        let (task, channel) = generate(prompt: prompt, model: model, temp: temperature)

        var ntok = 0
        for await token in channel {
            if ntok == 0 {
                let now = Date.timeIntervalSinceReferenceDate
                promptTime = now - start
                start = now
            }

            let s = try tokenizer.decode([token])
            print(s, terminator: "")
            fflush(stdout)

            ntok += 1
            if ntok == maxTokens {
                break
            }
        }

        // tell the task to stop
        task.cancel()

        print()
        print("------")
        let now = Date.timeIntervalSinceReferenceDate
        let generateTime = now - start

        print(
            """
            Prompt Tokens per second:     \((Double(prompt.size) / promptTime).formatted())
            Generation tokens per second: \((Double(ntok - 1) / generateTime).formatted())
            """)

        // wait for the task to complete -- since it is running async, it might
        // be in the middle of running the model
        try? await Task.sleep(for: .milliseconds(500))
    }
}

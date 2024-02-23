// Copyright © 2024 Apple Inc.

import AsyncAlgorithms
import Foundation
import MLX
import MLXNN
import MLXRandom
@_exported import SentencePiece

/// Load and return the model and tokenizer
public func load(modelDirectory: URL) throws -> (Model, SentencePiece) {
    let tokenizer = try SentencePiece(model: modelDirectory.appending(component: "tokenizer.model"))

    // load the model parameters
    let configurationURL = modelDirectory.appending(component: "config.json")
    let configuration = try JSONDecoder().decode(
        Configuration.self, from: Data(contentsOf: configurationURL))

    // set up the model
    let model = Model(configuration)
    if let quantization = configuration.quantization {
        QuantizedLinear.quantize(
            model: model, groupSize: quantization.groupSize, bits: quantization.bits)
    }

    // apply the loaded weights
    let weights = try loadArrays(url: modelDirectory.appending(component: "weights.00.safetensors"))
    let parameters = ModuleParameters.unflattened(weights)
    try model.update(parameters: parameters, verify: [.all])
    eval(model.parameters())

    return (model, tokenizer)
}

private func sample(logits: MLXArray, temp: Float) -> MLXArray {
    if temp == 0 {
        return argMax(logits, axis: -1)
    } else {
        return categorical(logits * (1 / temp))
    }
}

/// Synchronous generator of tokens.
///
/// Port of `generate_step()` from https://github.com/ml-explore/mlx-examples/blob/main/llms/mlx_lm/utils.py
public struct TokenIterator: Sequence, IteratorProtocol {
    let model: Model
    let temp: Float

    var y: MLXArray
    var cache: [(MLXArray, MLXArray)]

    var first = true

    public init(prompt: MLXArray, model: Model, temp: Float = 0.0) {
        self.model = model
        self.temp = temp
        self.y = prompt
        self.cache = []
    }

    mutating public func next() -> MLXArray? {
        var logits: MLXArray
        (logits, cache) = model(expandedDimensions(y, axis: 0), cache: cache.isEmpty ? nil : cache)
        y = sample(logits: logits[-1, axis: 1], temp: temp)

        return y
    }
}

/// Async generator of tokens.
///
/// Port of `generate_step()` from https://github.com/ml-explore/mlx-examples/blob/main/llms/mlx_lm/utils.py.
///
/// Note that because MLXArray is not thread safe this eval's the result and sends the TokenId back
/// to the caller.
public func generate(prompt: MLXArray, model: Model, temp: Float = 0.0) -> (
    Task<Void, Never>, AsyncBufferSequence<AsyncChannel<TokenId>>
) {
    let channel = AsyncChannel<TokenId>()
    let buffer = channel.buffer(policy: .bounded(10))

    let task = Task {
        var y = prompt
        var cache = [(MLXArray, MLXArray)]()

        while !Task.isCancelled {
            var logits: MLXArray
            (logits, cache) = model(
                expandedDimensions(y, axis: 0), cache: cache.isEmpty ? nil : cache)
            y = sample(logits: logits[-1, axis: 1], temp: temp)
            eval(y)

            await channel.send(y.asType(TokenId.self).item())
        }
    }

    return (task, buffer)
}

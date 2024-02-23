// Copyright © 2024 Apple Inc.

import Foundation

public enum StringOrNumber: Codable, Equatable {
    case string(String)
    case float(Float)

    public init(from decoder: Decoder) throws {
        let values = try decoder.singleValueContainer()

        if let v = try? values.decode(Float.self) {
            self = .float(v)
        } else {
            let v = try values.decode(String.self)
            self = .string(v)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let v): try container.encode(v)
        case .float(let v): try container.encode(v)
        }
    }
}

public struct Configuration: Codable {

    public struct Quantization: Codable {
        public init(groupSize: Int, bits: Int) {
            self.groupSize = groupSize
            self.bits = bits
        }

        let groupSize: Int
        let bits: Int

        enum CodingKeys: String, CodingKey {
            case groupSize = "group_size"
            case bits = "bits"
        }
    }

    var hiddenSize: Int
    var hiddenLayers: Int
    var intermediateSize: Int
    var attentionHeads: Int
    var rmsNormEps: Float
    var vocabularySize: Int
    var kvHeads: Int
    var ropeTheta: Float = 10_000
    var ropeTraditional: Bool = false
    var modelType: String? = nil
    var ropeScaling: [String: StringOrNumber]? = nil

    var quantization: Quantization?

    enum CodingKeys: String, CodingKey {
        case hiddenSize = "hidden_size"
        case hiddenLayers = "num_hidden_layers"
        case intermediateSize = "intermediate_size"
        case attentionHeads = "num_attention_heads"
        case rmsNormEps = "rms_norm_eps"
        case vocabularySize = "vocab_size"
        case kvHeads = "num_key_value_heads"
        case ropeTheta = "rope_theta"
        case ropeTraditional = "rope_traditional"
        case modelType = "model_type"
        case ropeScaling = "rope_scaling"
        case quantization
    }

    public init(from decoder: Decoder) throws {
        // custom implementation to handle optional keys with required values
        let container: KeyedDecodingContainer<Configuration.CodingKeys> = try decoder.container(
            keyedBy: Configuration.CodingKeys.self)

        self.hiddenSize = try container.decode(
            Int.self, forKey: Configuration.CodingKeys.hiddenSize)
        self.hiddenLayers = try container.decode(
            Int.self, forKey: Configuration.CodingKeys.hiddenLayers)
        self.intermediateSize = try container.decode(
            Int.self, forKey: Configuration.CodingKeys.intermediateSize)
        self.attentionHeads = try container.decode(
            Int.self, forKey: Configuration.CodingKeys.attentionHeads)
        self.rmsNormEps = try container.decode(
            Float.self, forKey: Configuration.CodingKeys.rmsNormEps)
        self.vocabularySize = try container.decode(
            Int.self, forKey: Configuration.CodingKeys.vocabularySize)
        self.kvHeads = try container.decode(Int.self, forKey: Configuration.CodingKeys.kvHeads)
        self.ropeTheta =
            try container.decodeIfPresent(Float.self, forKey: Configuration.CodingKeys.ropeTheta)
            ?? 10_000
        self.ropeTraditional =
            try container.decodeIfPresent(
                Bool.self, forKey: Configuration.CodingKeys.ropeTraditional) ?? false
        self.modelType = try container.decodeIfPresent(
            String.self, forKey: Configuration.CodingKeys.modelType)
        self.ropeScaling = try container.decodeIfPresent(
            [String: StringOrNumber].self, forKey: Configuration.CodingKeys.ropeScaling)
        self.quantization = try container.decodeIfPresent(
            Configuration.Quantization.self, forKey: Configuration.CodingKeys.quantization)

    }
}

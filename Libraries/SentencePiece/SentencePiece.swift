// Copyright © 2024 Apple Inc.

import Foundation

public typealias TokenId = Int32

/// Swift wrapper on `sentencepiece` processor API.
///
/// See https://github.com/google/sentencepiece
public class SentencePiece {

    private let impl: SentencePieceImpl
    private let separator = "▁"

    public init(model: URL) throws {
        precondition(model.isFileURL)
        self.impl = try SentencePieceImpl(model: model)
    }

    public func encode(_ string: String) throws -> [TokenId] {
        try [bosId] + impl.encode(string).map { $0.int32Value }
    }

    public func decode(_ ids: [TokenId]) throws -> String {
        let result = try impl.decode(ids.map { $0 as NSNumber })

        // add a leading space if needed
        if try !ids.isEmpty && modelIdToPiece(ids[0]).hasPrefix(separator) {
            return " " + result
        }

        return result
    }

    public var bosId: TokenId { impl.bosId() }
    public var padId: TokenId { impl.padId() }
    public var eosId: TokenId { impl.eosId() }

    public func modelIdToPiece(_ modelId: TokenId) throws -> String {
        impl.modelId(toPiece: modelId)
    }
}

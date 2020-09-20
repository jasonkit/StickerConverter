//
//  JSON.swift
//  StickerConverter
//
//  Created by Jason Wu on 29/10/2018.
//  Copyright © 2018 Jason Wu. All rights reserved.
//

import Foundation
import PromiseKit

extension JSONEncoder {
    static func createDefault() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }
}

extension JSONDecoder {
    static func createDefault() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}

extension Encodable {
    func toJSON(encoder: JSONEncoder) -> Promise<[String: Any]> {
        do {
            let json = try encoder.encode(self)
            if let args = try JSONSerialization.jsonObject(with: json) as? [String: Any] {
                return .value(args)
            } else {
                return Promise(error: SCError.modelSerializationError(model: "\(Self.self)"))
            }
        } catch {
            return Promise(error: SCError.modelSerializationError(model: "\(Self.self)"))
        }
    }
}

extension Decodable {
    static func fromJSON(decoder: JSONDecoder, _ data: Data) throws -> Self {
        return try decoder.decode(Self.self, from: data)
    }
}

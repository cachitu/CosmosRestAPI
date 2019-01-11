//
//  GaiaSimpleModel.swift
//  CosmosRestApi
//
//  Created by Calin Chitu on 02/01/2019.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import Foundation

public struct AbciInfo: Codable, PersistCodable {
    
    public let jsonrpc: String?
    public let id: String?
    public let result: Result?
    
    enum CodingKeys : String, CodingKey {
        case jsonrpc
        case id
        case result
    }
}


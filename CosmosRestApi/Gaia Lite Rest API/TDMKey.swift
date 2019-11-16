//
//  TDMKey.swift
//  CosmosRestApi
//
//  Created by Calin Chitu on 16/11/2019.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import Foundation

public struct TDMKey: Codable {
    
    public var name: String? = "dummy"
    public var password: String? = "test1234"
    public var type: TDMNodeType? = .cosmos
    public var address: String? = "cosmos1..."
    public var pubAddress: String? = "cosmospub1..."
    public var validator: String? = "cosmosvaloper..."
    public var pubValidator: String? = "cosmosvaloper1..."
    public var mnemonic: String? = "a b c"
    
    public init() {
    }
    
    enum CodingKeys : String, CodingKey {
        case name
        case password
        case type
        case address
        case pubAddress
        case validator
        case pubValidator
        case mnemonic
    }
}


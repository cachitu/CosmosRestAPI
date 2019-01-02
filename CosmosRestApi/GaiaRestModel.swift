//
//  Model.swift
//  CosmosClient
//
//  Created by Calin Chitu on 02/01/2019.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import Foundation


public struct Result: Codable {
    
    public let response: Response?
    
    enum CodingKeys : String, CodingKey {
        case response
    }
}

public struct Response: Codable {
    
    public let data: String?
    public let lastBlockHeight: String?
    public let lastBlockAppHash: String?
    
    enum CodingKeys : String, CodingKey {
        case data
        case lastBlockHeight = "last_block_height"
        case lastBlockAppHash = "last_block_app_hash"
    }
}

public struct Key: Codable {
    
    public let name: String?
    public let type: String?
    public let address: String?
    public let pub_key: String?
    
    enum CodingKeys : String, CodingKey {
        case name
        case type
        case address
        case pub_key
    }
}

public struct Account: Codable {
    
    public let type: String?
    public let value: AccountValue?
    
    enum CodingKeys : String, CodingKey {
        case type
        case value
    }
}

public struct AccountValue: Codable {
    
    public let address: String?
    public let coins: [Coin]?
    public let public_key: PublicKey?
    public let account_number: String?
    public let sequence: String?

    enum CodingKeys : String, CodingKey {
        case address
        case coins
        case public_key
        case account_number
        case sequence
    }
}

public struct Coin: Codable {
    
    public let denom: String?
    public let amount: String?
    
    enum CodingKeys : String, CodingKey {
        case denom
        case amount
    }
}

public struct PublicKey: Codable {
    
    public let type: String?
    public let value: String?
    
    enum CodingKeys : String, CodingKey {
        case type
        case value
    }
}

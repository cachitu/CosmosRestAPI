//
//  Model.swift
//  CosmosClient
//
//  Created by Calin Chitu on 02/01/2019.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import Foundation


//ICS0 - endermint APIs, such as query blocks, transactions and validatorset

public struct NodeInfo: Codable {
    
    public let protocol_version: ProtocolVersion?
    public let id: String?
    public let listen_addr: String?
    public let network: String?
    public var version: String?
    public var channels: String?
    public var moniker: String?
    public var other: NodeInfoOther?

    enum CodingKeys : String, CodingKey {
        case protocol_version
        case id
        case listen_addr
        case network
        case version
        case channels
        case moniker
        case other
    }
}

public struct ProtocolVersion: Codable {
    
    public let p2p: String?
    public let block: String?
    public let app: String?
    
    enum CodingKeys : String, CodingKey {
        case p2p
        case block
        case app
    }
}

public struct NodeInfoOther: Codable {
    
    public let tx_index: String?
    public let rpc_address: String?
    
    enum CodingKeys : String, CodingKey {
        case tx_index
        case rpc_address
    }
}


//ICS1 - Key management APIs

public struct Keys: PersistCodable {
    
    public var items: [Key]?
    
    public init(items: [Key]?) {
        self.items = items
    }
    
    enum CodingKeys : String, CodingKey {
        case items
    }
}

public struct Key: Codable {
    
    public let name: String?
    public let type: String?
    public let address: String?
    public let pub_key: String?
    public var seed: String?
    
    enum CodingKeys : String, CodingKey {
        case name
        case type
        case address
        case pub_key
        case seed
    }
}

public struct KeyPostData: Codable {
    
    public let name: String
    public let password: String?
    public let seed: String?
    
    public init(name: String, pass: String?, seed: String?) {
        self.name = name
        self.password  = pass
        self.seed = seed
    }
    
    enum CodingKeys : String, CodingKey {
        case name
        case password
        case seed
    }
}

public struct KeyPasswordData: Codable {
    
    public let name: String
    public let oldPass: String
    public let newPass: String
    
    public init(name: String, oldPass: String, newPass: String) {
        self.name    = name
        self.oldPass = oldPass
        self.newPass = newPass
    }
    
    enum CodingKeys : String, CodingKey {
        case name
        case oldPass = "old_password"
        case newPass = "new_password"
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


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
    
    public let protocolVersion: ProtocolVersion?
    public let id: String?
    public let listenAddr: String?
    public let network: String?
    public var version: String?
    public var channels: String?
    public var moniker: String?
    public var other: NodeInfoOther?

    enum CodingKeys : String, CodingKey {
        case protocolVersion = "protocol_version"
        case id
        case listenAddr = "listen_addr"
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
    
    public let txIndex: String?
    public let rpcAddress: String?
    
    enum CodingKeys : String, CodingKey {
        case txIndex = "tx_index"
        case rpcAddress = "rpc_address"
    }
}

public struct BlockRoot: Codable {
    
    public let blockMeta: BlockMeta?
    public let block: Block?

    enum CodingKeys : String, CodingKey {
        case blockMeta =  "block_meta"
        case block
    }
}

public struct BlockMeta: Codable {
    
    public let blockId: BlockId?
    public let header: BlockHeader?

    enum CodingKeys : String, CodingKey {
        case blockId =  "block_id"
        case header
    }
}

public struct Block: Codable {
    
    public let header: BlockHeader?
    public let data: BlockData?
    public let evidence: BlockEvidence?
    public let lastCommit: LastCommit?

    enum CodingKeys : String, CodingKey {
        case header
        case data
        case evidence
        case lastCommit = "last_commit"
   }
}

public struct BlockId: Codable {
    
    public let hash: String?
    public let parts: Parts?
    
    enum CodingKeys : String, CodingKey {
        case hash
        case parts
    }
}

public struct LastCommit: Codable {
    
    public let blockId: BlockId?
    public let precommits: [Precommit?]?
    
    enum CodingKeys : String, CodingKey {
        case blockId = "block_id"
        case precommits
    }
}

public struct Precommit: Codable {
    
    public let blockId: BlockId?
    public let type: Int
    public let height: String?
    public let round: String?
    public let timestamp: String?
    public let validatorAddress: String?
    public let validatorIndex: String?
    public let signature: String?

    enum CodingKeys : String, CodingKey {
        case blockId = "block_id"
        case type
        case height
        case round
        case timestamp
        case validatorAddress = "validator_address"
        case validatorIndex = "validator_index"
        case signature
    }
}

public struct BlockData: Codable {
    
    public let txs: [String]?
    
    enum CodingKeys : String, CodingKey {
        case txs
    }
}

public struct BlockEvidence: Codable {
    
    public let evidence: String?
    
    enum CodingKeys : String, CodingKey {
        case evidence
    }
}

public struct Parts: Codable {
    
    public let hash: String?
    public let total: String?
    
    enum CodingKeys : String, CodingKey {
        case hash
        case total
    }
}

public struct BlockHeader: Codable {
    
    public let version: BlockVersion?
    public let chainId: String?
    public let height: String?
    public let time: String?
    public let numTxs: String?
    public let totalTxs: String?
    public let lastBlockId: BlockId?
    public let lastCommitHash: String?
    public let dataHash: String?
    public let validatorsHash: String?
    public let nextValidatorsHash: String?
    public let consensusHash: String?
    public let appHash: String?
    public let lastResultsHash: String?
    public let evidenceHash: String?
    public let proposerAddress: String?

    enum CodingKeys : String, CodingKey {
        case version
        case chainId = "chain_id"
        case height
        case time
        case numTxs = "num_txs"
        case totalTxs = "total_txs"
        case lastBlockId = "last_block_id"
        case lastCommitHash = "last_commit_hash"
        case dataHash = "data_hash"
        case validatorsHash = "validators_hash"
        case nextValidatorsHash = "next_validators_hash"
        case consensusHash = "consensus_hash"
        case appHash = "app_hash"
        case lastResultsHash = "last_results_hash"
        case evidenceHash = "evidence_hash"
        case proposerAddress = "proposer_address"
    }
}

public struct BlockVersion: Codable {
    
    public let block: String?
    public let app: String?
    
    enum CodingKeys : String, CodingKey {
        case block
        case app
    }
}

public struct Validators: Codable {
    
    public let blockHeight: String?
    public let validators: [Validator]?
    
    enum CodingKeys : String, CodingKey {
        case blockHeight = "block_height"
        case validators
    }
}

public struct Validator: Codable {
    
    public let address: String?
    public let pubKey: String?
    public let proposerPriority: String?
    public let votingPower: String?

    enum CodingKeys : String, CodingKey {
        case address
        case pubKey = "pub_key"
        case proposerPriority = "proposer_priority"
        case votingPower = "voting_power"
    }
}

public struct Transaction: Codable {
    
    public let hash: String?
    public let height: String?
    public let tx: TransactionTx?
    public let result: TransactionResult?

    enum CodingKeys : String, CodingKey {
        case hash
        case height
        case tx
        case result
    }
}

public struct TransactionTx: Codable {
    
    public let type: String?
    public let value: TxValue?
    
    enum CodingKeys : String, CodingKey {
        case type
        case value
    }
}

public struct TxValue: Codable {
    
    public let msg: [TxValueMsg]?
    public let fee: TxValueFee?
    public let signatures: [TxValueSignature]?
    public let memo: String?

    enum CodingKeys : String, CodingKey {
        case msg
        case fee
        case signatures
        case memo
    }
}

public struct TxValueSignature: Codable {
    
    public let signature: String?
    public let pubKey: TxValSigPubKey?
    
    enum CodingKeys : String, CodingKey {
        case signature
        case pubKey = "pub_key"
    }
}

public struct TxValSigPubKey: Codable {
    
    public let type: String?
    public let value: String?
    
    enum CodingKeys : String, CodingKey {
        case type
        case value
    }
}

public struct TxValueFee: Codable {
    
    public let gas: String?
    public let amount: [TxFeeAmount]?
    
    enum CodingKeys : String, CodingKey {
        case gas
        case amount
    }
}

public struct TxFeeAmount: Codable {
    
    public let denom: String?
    public let amount: String?
    
    enum CodingKeys : String, CodingKey {
        case denom
        case amount
    }
}

public struct TxValueMsg: Codable {
    
    public let type: String?
    public let value: TxMsgVal?
    
    enum CodingKeys : String, CodingKey {
        case type
        case value
    }
}

public struct TxMsgVal: Codable {
    
    public let delegator_addr: String?
    public let validator_addr: String?
    public let delegation: TxMsgValDelegation?
    
    enum CodingKeys : String, CodingKey {
        case delegator_addr = "delegator_addr"
        case validator_addr = "validator_addr"
        case delegation
    }
}

public struct TxMsgValDelegation: Codable {
    
    public let denom: String?
    public let amount: String?
    
    enum CodingKeys : String, CodingKey {
        case denom
        case amount
    }
}

public struct TransactionResult: Codable {
    
    public let code: Int?
    public let log: String?
    public let gasWanted: String?
    public let gasUsed: String?
    public let codespace: String?
    public let tags: [TrResultTag]?
    
    enum CodingKeys : String, CodingKey {
        case code
        case log
        case gasWanted = "gas_wanted"
        case gasUsed = "gas_used"
        case codespace
        case tags
    }
}

public struct TrResultTag: Codable {
    
    public let key: String?
    public let value: String?
    
    enum CodingKeys : String, CodingKey {
        case key
        case value
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


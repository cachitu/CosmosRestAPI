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
    public let publicKey: PublicKey?
    public let accountNumber: String?
    public let sequence: String?

    enum CodingKeys : String, CodingKey {
        case address
        case coins
        case publicKey = "public_key"
        case accountNumber = "account_number"
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

//ICS20 - Bank TransferPostData

public struct TransferPostData: Codable {
    
    public var baseReq: TransferBaseReq?
    public var amount: [TxFeeAmount]?
    
    public init(name: String, pass: String, chain: String, amount: String, denom: String, accNum: String, sequence: String) {
        self.amount = [TxFeeAmount(denom: denom, amount: amount)]
        self.baseReq = TransferBaseReq(name: name, password: pass, chainId: chain, accountNumber: accNum, sequence: sequence)
    }
    
    enum CodingKeys : String, CodingKey {
        case baseReq = "base_req"
        case amount
    }
}

public struct TransferBaseReq: Codable {
    
    public let name: String?
    public let password: String?
    public let chainId: String?
    public let accountNumber: String?
    public let sequence: String?
    public let gas: String? = "simulate"
    public let gasAdjustment: String? = "1.0"
    public let generateOnly: Bool = false
    public let simulate: Bool = false

    enum CodingKeys : String, CodingKey {
        case name
        case password
        case chainId = "chain_id"
        case accountNumber = "account_number"
        case sequence
        case gas
        case gasAdjustment = "gas_adjustment"
        case generateOnly = "generate_only"
        case simulate
    }
}

public struct TransferResponse: Codable {
    
    public let checkTx: TransferCheckTx?
    public let deliverTx: TransferDeliverTx?
    public let hash: String?
    public let height: String?
    
    enum CodingKeys : String, CodingKey {
        case checkTx = "check_tx"
        case deliverTx =  "deliver_tx"
        case hash
        case height
    }
}

public struct TransferError: Codable {
    
    public let codespace: String?
    public let code: Int?
    public let message: String?
    
    enum CodingKeys : String, CodingKey {
        case codespace
        case code
        case message
    }
}

public struct TransferCheckTx: Codable {
    
    public let gasWanted: String?
    public let gasUsed: String?
    
    enum CodingKeys : String, CodingKey {
        case gasWanted
        case gasUsed
    }
}

public struct TransferDeliverTx: Codable {
    
    public let gasWanted: String?
    public let gasUsed: String?
    public let log: String?
    public let tags: [TrResultTag]?

    enum CodingKeys : String, CodingKey {
        case gasWanted
        case gasUsed
        case log
        case tags
    }
}


//ICS21 - Stake module APIs

public struct Delegation: Codable {
    
    public let delegatorAddr: String?
    public let validatorAddr: String?
    public let shares: String?
    public let height: Int?
    
    enum CodingKeys : String, CodingKey {
        case delegatorAddr = "delegator_addr"
        case validatorAddr = "validator_addr"
        case shares
        case height
    }
}

public struct DelegationPostData: Codable {
    
    public var baseReq: TransferBaseReq?
    public var delegation: TxFeeAmount?
    public var validatorAddr: String?
    public var delegatorAddr: String?

    public init(validator: String, delegator: String, name: String, pass: String, chain: String, amount: String, denom: String, accNum: String, sequence: String) {
        self.validatorAddr = validator
        self.delegatorAddr = delegator
        self.delegation  = TxFeeAmount(denom: denom, amount: amount)
        self.baseReq = TransferBaseReq(name: name, password: pass, chainId: chain, accountNumber: accNum, sequence: sequence)
    }
    
    enum CodingKeys : String, CodingKey {
        case baseReq = "base_req"
        case delegation
        case validatorAddr = "validator_addr"
        case delegatorAddr = "delegator_addr"
    }
}

public struct UnbondingDelegation: Codable {
    
    public let delegatorAddr: String?
    public let validatorAddr: String?
    public let creationHeight: String?
    public let balance: TxFeeAmount?
    public let initialBalance: TxFeeAmount?
    public let minTime: String?

    enum CodingKeys : String, CodingKey {
        case delegatorAddr = "delegator_addr"
        case validatorAddr = "validator_addr"
        case creationHeight = "creation_height"
        case balance
        case initialBalance = "initial_balance"
        case minTime = "min_time"
    }
}

public struct UnbondingDelegationPostData: Codable {
    
    public var baseReq: TransferBaseReq?
    public var shares: String?
    public var validatorAddr: String?
    public var delegatorAddr: String?
    
    public init(validator: String, delegator: String, name: String, pass: String, chain: String, amount: String, accNum: String, sequence: String) {
        self.validatorAddr = validator
        self.delegatorAddr = delegator
        self.shares  = amount
        self.baseReq = TransferBaseReq(name: name, password: pass, chainId: chain, accountNumber: accNum, sequence: sequence)
    }
    
    enum CodingKeys : String, CodingKey {
        case baseReq = "base_req"
        case shares
        case validatorAddr = "validator_addr"
        case delegatorAddr = "delegator_addr"
    }
}

public struct Redelegation: Codable {
    
    public let delegatorAddr: String?
    public let validatorSrcAddr: String?
    public let validatorDstAddr: String?
    public let creationHeight: String?
    public let minTime: String?
    public let initialBalance: TxFeeAmount?
    public let balance: TxFeeAmount?
    public let sharesSrc: String?
    public let sharesDst: String?

    enum CodingKeys : String, CodingKey {
        case delegatorAddr = "delegator_addr"
        case validatorSrcAddr = "validator_src_addr"
        case validatorDstAddr = "validator_dst_addr"
        case creationHeight = "creation_height"
        case minTime = "min_time"
        case initialBalance = "initial_balance"
        case balance
        case sharesSrc = "shares_src"
        case sharesDst = "shares_dst"
    }
}

public struct RedelegationPostData: Codable {
    
    public var baseReq: TransferBaseReq?
    public var shares: String?
    public var delegatorAddr: String?
    public var validatorSrcAddr: String?
    public var validatorDstAddr: String?
    
    public init(sourceValidator: String, destValidator: String, delegator: String, name: String, pass: String, chain: String, amount: String, accNum: String, sequence: String) {
        self.validatorSrcAddr = sourceValidator
        self.validatorDstAddr = destValidator
        self.delegatorAddr = delegator
        self.shares  = amount
        self.baseReq = TransferBaseReq(name: name, password: pass, chainId: chain, accountNumber: accNum, sequence: sequence)
    }
    
    enum CodingKeys : String, CodingKey {
        case baseReq = "base_req"
        case shares
        case delegatorAddr = "delegator_addr"
        case validatorSrcAddr = "validator_src_addr"
        case validatorDstAddr = "validator_dst_addr"
    }
}

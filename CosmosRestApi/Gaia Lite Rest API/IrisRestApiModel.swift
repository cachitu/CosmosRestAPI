//
//  IrisRestModel.swift
//  CosmosRestApi
//
//  Created by kytzu on 18/05/2019.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import Foundation

public struct IrisWithdrawData: Codable {
    
    public let baseTx: IrisBaseReq?
    public let validatorAddress: String?
    public let isValidator: Bool? = false

    enum CodingKeys : String, CodingKey {
        case baseTx = "base_tx"
        case validatorAddress = "validator_address"
        case isValidator = "is_validator"
     }
}

public struct IrisBaseReq: Codable {
    
    public let chainId: String?
    public let gas: String?
    public let fee: String?
    public let memo: String?

    enum CodingKeys : String, CodingKey {
        case chainId = "chain_id"
        case gas
        case fee
        case memo
     }
}

public struct IrisAccount: Codable {
    
    public let type: String?
    public let value: IrisAccountData?

    enum CodingKeys : String, CodingKey {
        case type
        case value
   }
}

public struct IrisAccountData: Codable {
    
    public let address: String?
    public let coins: [Coin]?
    public let accountNumber: String?
    public let sequence: String?
    public let publicKey: PublicKey?
    public let memoRegexp: String?

    enum CodingKeys : String, CodingKey {
        case address
        case coins
        case accountNumber = "account_number"
        case sequence
        case publicKey = "public_key"
        case memoRegexp = "memo_regexp"
   }
}

public struct IrisDelegation: Codable {
    
    public let delegatorAddr: String?
    public let validatorAddr: String?
    public let shares: String?
    public let height: String?
    
    enum CodingKeys : String, CodingKey {
        case delegatorAddr = "delegator_addr"
        case validatorAddr = "validator_addr"
        case shares
        case height
    }
}

public struct IrisRewards: Codable {
    
    public let total: [TxFeeAmount]?
    
    enum CodingKeys : String, CodingKey {
        case total
    }
}

public struct IrisProposal: Codable {
    
    public let type: String?
    public let value: IrisProposalStupidStructure?

    enum CodingKeys : String, CodingKey {
        case type
        case value
    }
}

public struct IrisProposalStupidStructure: Codable {
    
    public let basicProposal: IrisProposalContent?
 
    enum CodingKeys : String, CodingKey {
        case basicProposal = "BasicProposal"
    }
}

public struct IrisProposalContent: Codable {
    
    public let proposalId: String?
    public let title: String?
    public let description: String?
    public let proposaltype: String?
    public let proposalStatus: String?
    public var tallyResult: ProposalTallyData?
    public let submitTime: String?
    public let depositEndTime: String?
    public let totalDeposit: [TxFeeAmount]?
    public let votingStartTime: String?
    public let votingEndTime: String?
    public let proposer: String?
    public let params: [IrisProposalParam]?
    
    enum CodingKeys : String, CodingKey {
        case proposalId = "proposal_id"
        case title
        case description
        case proposaltype = "proposal_type"
        case proposalStatus = "proposal_status"
        case tallyResult = "tally_result"
        case submitTime = "submit_time"
        case depositEndTime = "deposit_end_time"
        case totalDeposit = "total_deposit"
        case votingStartTime = "voting_start_time"
        case votingEndTime = "voting_end_time"
        case proposer
        case params
   }
}

public struct IrisProposalParam: Codable {
    
    public let subspace: String?
    public let key: String?
    public let value: String?
    
    enum CodingKeys : String, CodingKey {
        case subspace
        case key
        case value
    }
}

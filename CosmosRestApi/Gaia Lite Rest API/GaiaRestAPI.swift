//
//  GaiaRestAPI.swift
//  CosmosClient
//
//  Created by Calin Chitu on 02/01/2019.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import Foundation

/* Needs RPC server to be started
 
 Specs url:  https://cosmos.network/rpc/
 Sample url: https://localhost:1317/keys
 
 gaiacli rest-server \
 --chain-id=genki-4002 \
 --laddr=tcp://localhost:1317 \
 --node tcp://localhost:26657 \
 --trust-node=true \
 --ssl-hosts localhost \
 --ssl-certfile=/Users/kytzu/.ssh/server.crt \
 --ssl-keyfile=/Users/kytzu/.ssh/server.key \
 
 ICS0 - endermint APIs, such as query blocks, transactions and validatorset
 
 * GET /node_info - The properties of the connected node
 * GET /syncing - Syncing state of node
 * GET /blocks/latest - Get the latest block
 * GET /blocks/{height} - Get a block at a certain height
 * GET /validatorsets/latest - Get the latest validator set
 * GET /validatorsets/{height} - Get a validator set a certain height
 * GET /txs/{hash} - Get a Tx by hash
 GET /txs - Search transactions
 POST - /txs - broadcast Tx
 
 
 ICS1 - Key management APIs
 
 * GET /keys - List of accounts stored locally
 * POST/keys - Create a new account locally
 * GET /keys/seed - Create a new seed to create a new account with
 * POST /keys/{name}/recover - Recover a account from a seed
 * GET /keys/{name} - Get a certain locally stored account
 * PUT /keys/{name} - Update the password for this account in the KMS
 * DELETE /keys/{name} - Remove an account
 * GET /auth/accounts/{address} - Get the account information on blockchain
 
 
 ICS20 - Create, sign and broadcast transactions
 
 POST /tx/sign - Sign a Tx
 POST /tx/broadcast - Send a signed Tx
 * GET /bank/balances/{address} - Get the account balances
 * POST /bank/accounts/{address}/transfers - Send coins (build -> sign -> send)
 
 
 ICS21 - Stake module APIs
 
 * GET /stake/delegators/{delegatorAddr}/delegations - Get all delegations from a delegator
 * POST /stake/delegators/{delegatorAddr}/delegations - Submit delegation
 * GET /stake/delegators/{delegatorAddr}/delegations/{validatorAddr} - Query the current delegation between a delegator and a validator
 * GET /stake/delegators/{delegatorAddr}/unbonding_delegations - Get all unbonding delegations from a delegator
 * POST /stake/delegators/{delegatorAddr}/unbonding_delegations - Submit an unbonding delegation
 * GET /stake/delegators/{delegatorAddr}/unbonding_delegations/{validatorAddr} - Query all unbonding delegations between a delegator and a validator
 * GET /stake/delegators/{delegatorAddr}/redelegations - Get all redelegations from a delegator
 * POST /stake/delegators/{delegatorAddr}/redelegations - Submit a redelegation
 * GET /stake/delegators/{delegatorAddr}/validators - Query all validators that a delegator is bonded to
 * GET /stake/delegators/{delegatorAddr}/validators/{validatorAddr} - Query a validator that a delegator is bonded to
 * GET /stake/delegators/{delegatorAddr}/txs - Get all staking txs (i.e msgs) from a delegator
 * GET /stake/validators - Get all validator candidates
 * GET /stake/validators/{validatorAddr} - Query the information from a single validator
 * GET /stake/validators/{validatorAddr}/delegations - Get all delegations from a validator
 * GET /stake/validators/{validatorAddr}/unbonding_delegations - Get all unbonding delegations from a validator
 * GET /stake/validators/{validatorAddr}/redelegations - Get all outgoing redelegations from a validator
 * GET /stake/pool - Get the current state of the staking pool
 * GET /stake/parameters - Get the current staking parameter values
 
 
 ICS22 - Governance module APIs
 
 * POST /gov/proposals - Submit a proposal
 * GET /gov/proposals - Query proposals
 * GET /gov/proposals/{proposalId} - Query a proposal
 * GET /gov/proposals/{proposalId}/deposits - Query deposits
 * POST /gov/proposals/{proposalId}/deposits - Deposit tokens to a proposal
 * GET /gov/proposals/{proposalId}/deposits/{depositor} - Query deposit
 * GET /gov/proposals/{proposalId}/votes - Query voters
 * POST /gov/proposals/{proposalId}/votes - Vote a proposal
 * GET /gov/proposals/{proposalId}/votes/{voter} - Query vote
 * GET /gov/proposals/{proposalId}/tally - Get a proposal's tally result at the current time
 * GET /gov/parameters/deposit - Query governance deposit parameters
 * GET /gov/parameters/tallying - Query governance tally parameters
 * GET /gov/parameters/voting - Query governance voting parameters
 
 
 ICS23 - Slashing module APIs
 
 * GET /slashing/validators/{validatorPubKey}/signing_info - Get sign info of given validator
 * POST /slashing/validators/{validatorAddr}/unjail - Unjail a jailed validator
 * GET /slashing/parameters - Get the current slashing parameters
 
 
 ICS24 - Fee distribution module APIs (not yet available on server)
 
 GET  /distribution/delegators/{delegatorAddr}/rewards - Get the total rewards balance from all delegations
 POST /distribution/delegators/{delegatorAddr}/rewards - Withdraw all the delegator's delegation rewards
 GET  /distribution/delegators/{delegatorAddr}/rewards/{validatorAddr} - Query a delegation reward
 POST /distribution/delegators/{delegatorAddr}/rewards/{validatorAddr} - Withdraw a delegation reward
 GET  /distribution/delegators/{delegatorAddr}/withdraw_address - Get the rewards withdrawal address
 POST /distribution/delegators/{delegatorAddr}/withdraw_address - Replace the rewards withdrawal address
 GET  /distribution/validators/{validatorAddr} - Validator distribution information
 GET  /distribution/validators/{validatorAddr}/rewards - Commission and self-delegation rewards of a single a validator
 POST /distribution/validators/{validatorAddr}/rewards - Withdraw the validator's rewards
 GET  /distribution/parameters - Fee distribution parameters
 GET  /distribution/pool - Fee distribution pool
 
 
 Query app version
 
 * GET /version - Version of Gaia-lite
 * GET /node_version - Version of the connected node
 
 */

public class GaiaRestAPI: NSObject, RestNetworking, URLSessionDelegate {
    
    static let minVersion = "0.30.0-3-gb8843fcd"
    
    let connectData: ConnectData
    
    public init(scheme: String = "https", host: String = "localhost", port: Int = 1317) {
        connectData = ConnectData(scheme: scheme, host: host, port: port)
        super.init()
    }
    
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(URLSession.AuthChallengeDisposition.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
    
    
    //ICS0 - endermint APIs, such as query blocks, transactions and validatorset
    
    public func getNodeInfo(completion: ((RestResult<[NodeInfo]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/node_info", delegate: self, singleItemResponse: true, timeout: 3, completion: completion)
    }
    
    public func getSyncingInfo(completion: ((RestResult<[String]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/syncing", delegate: self, singleItemResponse: true, timeout: 3, completion: completion)
    }
    
    public func getLatestBlock(completion: ((RestResult<[BlockRoot]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/blocks/latest", delegate: self, singleItemResponse: true, completion: completion)
    }
    
    public func getBlock(at height: Int, completion: ((RestResult<[BlockRoot]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/blocks/\(height)", delegate: self, singleItemResponse: true, completion: completion)
    }
    
    public func getLatestValidators(completion: ((RestResult<[Validators]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/validatorsets/latest", delegate: self, singleItemResponse: true, completion: completion)
    }
    
    public func getValidators(at height: Int, completion: ((RestResult<[Validators]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/validatorsets/\(height)", delegate: self, singleItemResponse: true, completion: completion)
    }
    
    public func getTransaction(by hash: String, completion: ((RestResult<[Transaction]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/txs/\(hash)", delegate: self, singleItemResponse: true, completion: completion)
    }
    
    
    //ICS1 - Key management APIs
    
    public func createSeed(completion: ((RestResult<[String]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/keys/seed", delegate: self, singleItemResponse: true, completion: completion)
    }
    
    public func getKeys(completion: ((RestResult<[Key]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/keys", delegate: self, completion: completion)
    }
    
    public func getKey(by name: String, completion: ((RestResult<[Key]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/keys/\(name)", delegate: self, singleItemResponse: true, completion: completion)
    }
    
    public func createKey(keyData: KeyPostData, completion:((RestResult<[Key]>) -> Void)?) {
        genericRequest(bodyData: keyData, connData: connectData, path: "/keys", delegate: self, reqMethod: "POST", singleItemResponse: true, completion: completion)
    }
    
    public func recoverKey(keyData: KeyPostData, completion:((RestResult<[Key]>) -> Void)?) {
        genericRequest(bodyData: keyData, connData: connectData, path: "/keys/\(keyData.name)/recover", delegate: self, reqMethod: "POST", singleItemResponse: true, completion: completion)
    }
    
    public func deleteKey(keyData: KeyPostData, completion:((RestResult<[String]>) -> Void)?) {
        genericRequest(bodyData: keyData, connData: connectData, path: "/keys/\(keyData.name)", delegate: self, reqMethod: "DELETE", singleItemResponse: true, completion: completion)
    }
    
    public func changeKeyPassword(keyData: KeyPasswordData, completion:((RestResult<[String]>) -> Void)?) {
        genericRequest(bodyData: keyData, connData: connectData, path: "/keys/\(keyData.name)", delegate: self, reqMethod: "PUT", singleItemResponse: true, completion: completion)
    }
    
    public func getAccount(address: String, completion: ((RestResult<[Account]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/auth/accounts/\(address)", delegate: self, singleItemResponse: true, completion: completion)
    }
    
    
    // ICS20
    
    public func bankTransfer(to address: String, transferData: TransferPostData, completion:((RestResult<[TransferResponse]>) -> Void)?) {
        genericRequest(bodyData: transferData, connData: connectData, path: "/bank/accounts/\(address)/transfers", delegate: self, reqMethod: "POST", singleItemResponse: true, completion: completion)
    }
    
    public func getBalance(address: String, completion: ((RestResult<[TxFeeAmount]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/bank/balances/\(address)", delegate: self, singleItemResponse: false, completion: completion)
    }
    
    
    // ICS21 - Stake module APIs
    
    public func getDelegations(for address: String, completion: ((RestResult<[Delegation]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/staking/delegators/\(address)/delegations", delegate: self, completion: completion)
    }
    
    public func delegation(from address: String, transferData: DelegationPostData, completion:((RestResult<[TransferResponse]>) -> Void)?) {
        genericRequest(bodyData: transferData, connData: connectData, path: "/staking/delegators/\(address)/delegations", delegate: self, reqMethod: "POST", singleItemResponse: true, completion: completion)
    }
    
    public func getDelegation(for address: String, validator: String, completion: ((RestResult<[Delegation]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/staking/delegators/\(address)/delegations/\(validator)", delegate: self, singleItemResponse: true, completion: completion)
    }
    
    public func getUnbondingDelegations(for address: String, completion: ((RestResult<[UnbondingDelegation]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/staking/delegators/\(address)/unbonding_delegations", delegate: self, completion: completion)
    }
    
    public func unbonding(from address: String, transferData: UnbondingDelegationPostData, completion:((RestResult<[TransferResponse]>) -> Void)?) {
        genericRequest(bodyData: transferData, connData: connectData, path: "/staking/delegators/\(address)/unbonding_delegations", delegate: self, reqMethod: "POST", singleItemResponse: true, completion: completion)
    }
    
    public func getUnbondingDelegation(for address: String, validator: String, completion: ((RestResult<[UnbondingDelegation]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/staking/delegators/\(address)/unbonding_delegations/\(validator)", delegate: self, singleItemResponse: true, completion: completion)
    }
    
    public func getRedelegations(for address: String, completion: ((RestResult<[Redelegation]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/staking/delegators/\(address)/redelegations", delegate: self, completion: completion)
    }
    
    public func redelegation(from address: String, transferData: RedelegationPostData, completion:((RestResult<[TransferResponse]>) -> Void)?) {
        genericRequest(bodyData: transferData, connData: connectData, path: "/staking/delegators/\(address)/redelegations", delegate: self, reqMethod: "POST", singleItemResponse: true, completion: completion)
    }
    
    public func getDelegatorValidators(for address: String, completion: ((RestResult<[DelegatorValidator]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/staking/delegators/\(address)/validators", delegate: self, singleItemResponse: false, completion: completion)
    }
    
    public func getDelegatorValidator(for address: String,  validator: String, completion: ((RestResult<[DelegatorValidator]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/staking/delegators/\(address)/validators/\(validator)", delegate: self, singleItemResponse: true, completion: completion)
    }
    
    public func getStakingTxs(for address: String, completion: ((RestResult<[Transaction]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/staking/delegators/\(address)/txs", delegate: self, singleItemResponse: false, completion: completion)
    }
    
    public func getStakeValidators(completion: ((RestResult<[DelegatorValidator]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/staking/validators", delegate: self, singleItemResponse: false, completion: completion)
    }
    
    public func getStakeValidator(for valAddress: String, completion: ((RestResult<[DelegatorValidator]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/staking/validators/\(valAddress)", delegate: self, singleItemResponse: true, completion: completion)
    }
    
    public func getStakeValidatorDelegations(for valAddress: String, completion: ((RestResult<[Delegation]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/staking/validators/\(valAddress)/delegations", delegate: self, singleItemResponse: false, completion: completion)
    }
    
    public func getStakeValidatorUnbondingDelegations(for valAddress: String, completion: ((RestResult<[UnbondingDelegation]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/staking/validators/\(valAddress)/unbonding_delegations", delegate: self, singleItemResponse: false, completion: completion)
    }
    
    public func getStakeValidatorRedelegations(for valAddress: String, completion: ((RestResult<[Redelegation]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/staking/validators/\(valAddress)/redelegations", delegate: self, singleItemResponse: false, completion: completion)
    }
    
    public func getStakePool(completion: ((RestResult<[StakePool]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/staking/pool", delegate: self, singleItemResponse: true, completion: completion)
    }
    
    public func getStakeParameters(completion: ((RestResult<[StakeParameters]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/staking/parameters", delegate: self, singleItemResponse: true, completion: completion)
    }
    
    
    //ICS22 - Governance
    
    public func submitProposal(transferData: ProposalPostData, completion:((RestResult<[TransferResponse]>) -> Void)?) {
        genericRequest(bodyData: transferData, connData: connectData, path: "/gov/proposals", delegate: self, reqMethod: "POST", singleItemResponse: true, completion: completion)
    }

    public func getPorposals(completion: ((RestResult<[Proposal]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/gov/proposals", delegate: self, singleItemResponse: false, completion: completion)
    }

    public func getPorposal(forId id: String, completion: ((RestResult<[Proposal]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/gov/proposals/\(id)", delegate: self, singleItemResponse: true, completion: completion)
    }
    
    public func getPorposalDeposits(forId id: String, completion: ((RestResult<[ProposalDeposit]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/gov/proposals/\(id)/deposits", delegate: self, singleItemResponse: false, completion: completion)
    }

    public func getPorposalDeposit(forId id: String, by depositor: String, completion: ((RestResult<[ProposalDeposit]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/gov/proposals/\(id)/deposits/\(depositor)", delegate: self, singleItemResponse: true, completion: completion)
    }

    public func getPorposalVotes(forId id: String, completion: ((RestResult<[ProposalVote]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/gov/proposals/\(id)/votes", delegate: self, singleItemResponse: false, completion: completion)
    }

    public func getPorposalTally(forId id: String, completion: ((RestResult<[ProposalTallyResult]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/gov/proposals/\(id)/tally", delegate: self, singleItemResponse: true, completion: completion)
    }

    public func getPorposalVote(forId id: String, by voter: String, completion: ((RestResult<[ProposalVote]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/gov/proposals/\(id)/votes/\(voter)", delegate: self, singleItemResponse: true, completion: completion)
    }

    public func depositToProposal(id: String, transferData: ProposalDepositPostData, completion:((RestResult<[TransferResponse]>) -> Void)?) {
        genericRequest(bodyData: transferData, connData: connectData, path: "/gov/proposals/\(id)/deposits", delegate: self, reqMethod: "POST", singleItemResponse: true, completion: completion)
    }

    public func voteProposal(id: String, transferData: ProposalVotePostData, completion:((RestResult<[TransferResponse]>) -> Void)?) {
        genericRequest(bodyData: transferData, connData: connectData, path: "/gov/proposals/\(id)/votes", delegate: self, reqMethod: "POST", singleItemResponse: true, completion: completion)
    }

    public func getGovDepositParameters(completion: ((RestResult<[GovDepositParameters]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/gov/parameters/deposit", delegate: self, singleItemResponse: true, completion: completion)
    }

    public func getGovTallyingParameters(completion: ((RestResult<[GovTallyingParameters]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/gov/parameters/tallying", delegate: self, singleItemResponse: true, completion: completion)
    }
    
    public func getGovVotingParameters(completion: ((RestResult<[GovVotingParameters]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/gov/parameters/voting", delegate: self, singleItemResponse: true, completion: completion)
    }


    //ICS23 - Slashing
    
    public func getSlashingSigningInfo(of valPubKey: String, completion: ((RestResult<[SigningInfo]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/slashing/validators/\(valPubKey)/signing_info", delegate: self, singleItemResponse: true, completion: completion)
    }

    public func unjail(validator valAddr: String, transferData: UnjailPostData, completion:((RestResult<[TransferResponse]>) -> Void)?) {
        genericRequest(bodyData: transferData, connData: connectData, path: "/slashing/validators/\(valAddr)/unjail", delegate: self, reqMethod: "POST", singleItemResponse: true, completion: completion)
    }

    public func getSlashingParameters(completion: ((RestResult<[SlashingParameters]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/slashing/parameters", delegate: self, singleItemResponse: true, completion: completion)
    }

    //ICS24 - Fee distribution module APIs
    
    // Wait for implementation on server
    
    
    //Version
    
    public func getGaiaVersion(completion: ((RestResult<[String]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/version", delegate: self, singleItemResponse: true, completion: completion)
    }

    public func getNodeVersion(completion: ((RestResult<[String]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/node_version", delegate: self, singleItemResponse: true, completion: completion)
    }

}

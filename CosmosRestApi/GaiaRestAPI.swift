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
 
 GET /node_info - The properties of the connected node
 GET /syncing - Syncing state of node
 GET /blocks/latest - Get the latest block
 GET /blocks/{height} - Get a block at a certain height
 GET /validatorsets/latest - Get the latest validator set
 GET /validatorsets/{height} - Get a validator set a certain height
 GET /txs/{hash} - Get a Tx by hash
 GET /txs - Search transactions
 POST - /txs - broadcast Tx
 
 
 ICS1 - Key management APIs
 
 GET /keys - List of accounts stored locally
 POST/keys - Create a new account locally
 GET /keys/seed - Create a new seed to create a new account with
 POST /keys/{name}/recover - Recover a account from a seed
 GET /keys/{name} - Get a certain locally stored account
 PUT /keys/{name} - Update the password for this account in the KMS
 DELETE /keys/{name} - Remove an account
 GET /auth/accounts/{address} - Get the account information on blockchain
 
 
 ICS20 - Create, sign and broadcast transactions
 
 POST /tx/sign - Sign a Tx
 POST /tx/broadcast - Send a signed Tx
 GET /bank/balances/{address} - Get the account balances
 POST /bank/accounts/{address}/transfers - Send coins (build -> sign -> send)
 
 
 ICS21 - Stake module APIs
 
 GET /stake/delegators/{delegatorAddr}/delegations - Get all delegations from a delegator
 POST /stake/delegators/{delegatorAddr}/delegations - Submit delegation
 GET /stake/delegators/{delegatorAddr}/delegations/{validatorAddr} - Query the current delegation between a delegator and a validator
 GET /stake/delegators/{delegatorAddr}/unbonding_delegations - Get all unbonding delegations from a delegator
 POST /stake/delegators/{delegatorAddr}/unbonding_delegations - Submit an unbonding delegation
 GET /stake/delegators/{delegatorAddr}/unbonding_delegations/{validatorAddr} - Query all unbonding delegations between a delegator and a validator
 GET /stake/delegators/{delegatorAddr}/redelegations - Get all redelegations from a delegator
 POST /stake/delegators/{delegatorAddr}/redelegations - Submit a redelegation
 GET /stake/delegators/{delegatorAddr}/validators - Query all validators that a delegator is bonded to
 GET /stake/delegators/{delegatorAddr}/validators/{validatorAddr} - Query a validator that a delegator is bonded to
 GET /stake/delegators/{delegatorAddr}/txs - Get all staking txs (i.e msgs) from a delegator
 GET /stake/validators - Get all validator candidates
 GET /stake/validators/{validatorAddr} - Query the information from a single validator
 GET /stake/validators/{validatorAddr}/delegations - Get all delegations from a validator
 GET /stake/validators/{validatorAddr}/unbonding_delegations - Get all unbonding delegations from a validator
 GET /stake/validators/{validatorAddr}/redelegations - Get all outgoing redelegations from a validator
 GET /stake/pool - Get the current state of the staking pool
 GET /stake/parameters - Get the current staking parameter values
 
 
 ICS22 - Governance module APIs
 
 POST /gov/proposals - Submit a proposal
 GET /gov/proposals - Query proposals
 GET /gov/proposals/{proposalId} - Query a proposal
 GET /gov/proposals/{proposalId}/deposits - Query deposits
 POST /gov/proposals/{proposalId}/deposits - Deposit tokens to a proposal
 GET /gov/proposals/{proposalId}/deposits/{depositor} - Query deposit
 GET /gov/proposals/{proposalId}/votes - Query voters
 POST /gov/proposals/{proposalId}/votes - Vote a proposal
 GET /gov/proposals/{proposalId}/votes/{voter} - Query vote
 GET /gov/proposals/{proposalId}/tally - Get a proposal's tally result at the current time
 GET /gov/parameters/deposit - Query governance deposit parameters
 GET /gov/parameters/tallying - Query governance tally parameters
 GET /gov/parameters/voting - Query governance voting parameters
 
 
 ICS23 - Slashing module APIs
 
 GET /slashing/validators/{validatorPubKey}/signing_info - Get sign info of given validator
 POST /slashing/validators/{validatorAddr}/unjail - Unjail a jailed validator
 GET /slashing/parameters - Get the current slashing parameters
 
 
 ICS24 - Fee distribution module APIs
 
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
 
 GET /version - Version of Gaia-lite
 GET /node_version - Version of the connected node
 
 */

public class GaiaRestAPI: NSObject, RestNetworking, URLSessionDelegate {
    
    let scheme: String
    let host: String
    let port: Int
    
    public init(scheme: String = "https", host: String = "localhost", port: Int = 1317) {
        self.scheme = scheme
        self.host   = host
        self.port   = port
        super.init()
    }
    
    public func getkeys(completion: ((RestResult<[Key]>) -> Void)?) {
        genericGet(scheme: scheme, host: host, port: port, path: "/keys", delegate: self, completion: completion)
    }
    
    public func getAccount(address: String?, completion: ((RestResult<Account>) -> Void)?) {
        guard let addr = address else {
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "Invalid address"]) as Error
            completion?(.failure(error))
            return }
        genericGet(scheme: scheme, host: host, port: port, path: "/auth/accounts/\(addr)", delegate: self, completion: completion)
    }

    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(URLSession.AuthChallengeDisposition.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
}

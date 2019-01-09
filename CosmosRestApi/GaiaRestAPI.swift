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
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/node_info", delegate: self, singleItemResponse: true, completion: completion)
    }
    
    public func getSyncingInfo(completion: ((RestResult<[String]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/syncing", delegate: self, singleItemResponse: true, completion: completion)
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
    
    public func getSeed(completion: ((RestResult<[String]>) -> Void)?) {
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
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/stake/delegators/\(address)/delegations", delegate: self, completion: completion)
    }
    
    public func delegation(from address: String, transferData: DelegationPostData, completion:((RestResult<[TransferResponse]>) -> Void)?) {
        genericRequest(bodyData: transferData, connData: connectData, path: "/stake/delegators/\(address)/delegations", delegate: self, reqMethod: "POST", singleItemResponse: true, completion: completion)
    }

    public func getDelegation(for address: String, validator: String, completion: ((RestResult<[Delegation]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/stake/delegators/\(address)/delegations/\(validator)", delegate: self, singleItemResponse: true, completion: completion)
    }
    
    public func getUnbondingDelegations(for address: String, completion: ((RestResult<[UnbondingDelegation]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/stake/delegators/\(address)/unbonding_delegations", delegate: self, completion: completion)
    }

    public func unbonding(from address: String, transferData: UnbondingDelegationPostData, completion:((RestResult<[TransferResponse]>) -> Void)?) {
        genericRequest(bodyData: transferData, connData: connectData, path: "/stake/delegators/\(address)/unbonding_delegations", delegate: self, reqMethod: "POST", singleItemResponse: true, completion: completion)
    }
    
    public func getUnbondingDelegation(for address: String, validator: String, completion: ((RestResult<[UnbondingDelegation]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/stake/delegators/\(address)/unbonding_delegations/\(validator)", delegate: self, singleItemResponse: true, completion: completion)
    }

    public func getRedelegations(for address: String, completion: ((RestResult<[Redelegation]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/stake/delegators/\(address)/redelegations", delegate: self, completion: completion)
    }

    public func redelegation(from address: String, transferData: RedelegationPostData, completion:((RestResult<[TransferResponse]>) -> Void)?) {
        genericRequest(bodyData: transferData, connData: connectData, path: "/stake/delegators/\(address)/redelegations", delegate: self, reqMethod: "POST", singleItemResponse: true, completion: completion)
    }

    public func getDelegatorValidators(for address: String, completion: ((RestResult<[DelegatorValidator]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/stake/delegators/\(address)/validators", delegate: self, singleItemResponse: false, completion: completion)
    }
    
    public func getDelegatorValidator(for address: String,  validator: String, completion: ((RestResult<[DelegatorValidator]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/stake/delegators/\(address)/validators/\(validator)", delegate: self, singleItemResponse: true, completion: completion)
    }

    public func getStakingTxs(for address: String, completion: ((RestResult<[Transaction]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/stake/delegators/\(address)/txs", delegate: self, singleItemResponse: false, completion: completion)
    }

    public func getStakeValidators(completion: ((RestResult<[DelegatorValidator]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/stake/validators", delegate: self, singleItemResponse: false, completion: completion)
    }
    
    public func getStakeValidator(for valAddress: String, completion: ((RestResult<[DelegatorValidator]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/stake/validators/\(valAddress)", delegate: self, singleItemResponse: true, completion: completion)
    }

    public func getStakeValidatorDelegations(for valAddress: String, completion: ((RestResult<[Delegation]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/stake/validators/\(valAddress)/delegations", delegate: self, singleItemResponse: false, completion: completion)
    }
    
    public func getStakeValidatorUnbondingDelegations(for valAddress: String, completion: ((RestResult<[UnbondingDelegation]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/stake/validators/\(valAddress)/unbonding_delegations", delegate: self, singleItemResponse: false, completion: completion)
    }

    public func getStakeValidatorRedelegations(for valAddress: String, completion: ((RestResult<[Redelegation]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/stake/validators/\(valAddress)/redelegations", delegate: self, singleItemResponse: false, completion: completion)
    }

    public func getStakePool(completion: ((RestResult<[StakePool]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/stake/pool", delegate: self, singleItemResponse: true, completion: completion)
    }

    public func getStakeParameters(completion: ((RestResult<[StakeParameters]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/stake/parameters", delegate: self, singleItemResponse: true, completion: completion)
    }

    
    
    public static func selfTesting() {
        
        let restApi = GaiaRestAPI()
        
        let chainID = "kytzu-001"
        let key1name = "validator"
        let addr1 = "cosmos1r627wlvrhkk637d4zarv2jpkuwuwurj9mnyskt"
        let addr2 = "cosmos1f7lf8w6kw6pwutpknyawvhvtkmkneg4932jdpv"
        let val1  = "cosmosvaloper1r627wlvrhkk637d4zarv2jpkuwuwurj978s96c"
        let val2  = "cosmosvaloper1f7lf8w6kw6pwutpknyawvhvtkmkneg4957xcdl"
        let acc1Pass = "test1234"
        let acc2Pass = "test1234"
        let validHash = "0DAE0C1FC7368BEAC8E7BA4CDE8ECF4209303072F0484A7632473631F060BC49"
        let recoverSeed = "survey man plate calm myth giggle ahead park creek marble arrest verb indicate brother donor know hedgehog armed total mechanic job caught alert breeze"
        
        let dispatchGroup = DispatchGroup()
        
        print("... Starting ...")
        
        dispatchGroup.enter()
        restApi.getNodeInfo { result in
            print("\n... Get Node info ...")
            switch result {
            case .success(let data):
                if let item = data.first, let field = item.network {
                    print(" -> [OK] - ", field)
                }
            case .failure(let error):
                print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
            }
            dispatchGroup.leave()
         }

        dispatchGroup.enter()
        restApi.getSyncingInfo { result in
            print("\n... Get Sync info ...")
            switch result {
            case .success(let data):
                if let item = data.first {
                    print(" -> [OK] - ", item)
                }
            case .failure(let error):
                print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
            }
            dispatchGroup.leave()
        }

        dispatchGroup.enter()
        restApi.getLatestBlock { result in
            print("\n... Get Lates block ...")
            switch result {
            case .success(let data):
                if let item = data.first, let field = item.blockMeta?.blockId?.hash {
                    print(" -> [OK] - ", field)
                }
            case .failure(let error):
                print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
            }
            dispatchGroup.leave()
        }

        dispatchGroup.enter()
        restApi.getBlock(at: 1) { result in
            print("\n... Get block at 1 ...")
            switch result {
            case .success(let data):
                if let item = data.first, let field = item.blockMeta?.blockId?.hash {
                    print(" -> [OK] - ", field)
                }
            case .failure(let error):
                print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
            }
            dispatchGroup.leave()
        }

        dispatchGroup.enter()
        restApi.getLatestValidators() { result in
            print("\n... Get latest validators ...")
            switch result {
            case .success(let data):
                if let item = data.first, let field = item.validators?.count {
                    print(" -> [OK] - ", field)
                }
            case .failure(let error):
                print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
            }
            dispatchGroup.leave()
         }

        dispatchGroup.enter()
        restApi.getValidators(at: 1000) { result in
            print("\n... Get validators at 1000 ...")
            switch result {
            case .success(let data):
                if let item = data.first, let field = item.validators?.count {
                    print(" -> [OK] - ", field)
                }
            case .failure(let error):
                print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
            }
            dispatchGroup.leave()
       }

        dispatchGroup.enter()
        restApi.getTransaction(by: validHash) { result in
            print("\n... Get tx by hash:  \(validHash) ...")
            switch result {
            case .success(let data):
                if let item = data.first, let field = item.hash {
                    print(" -> [OK] - ", field)
                }
            case .failure(let error):
                print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
            }
            dispatchGroup.leave()
       }

        dispatchGroup.enter()
        restApi.getKeys { result in
            print("\n... Get all keys on this node ...")
            switch result {
            case .success(let data):
                print(" -> [OK] - ", data.count)
            case .failure(let error):
                print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
            }
            dispatchGroup.leave()
        }

        dispatchGroup.enter()
        let kdata = KeyPostData(name: "testCreate", pass: "test1234", seed: recoverSeed)
        restApi.createKey(keyData: kdata) { result in
            print("\n... Create a test key ...")
            switch result {
            case .success(let data):
                if let item = data.first, let field = item.address {
                    print(" -> [OK] - ", field)
                }
            case .failure(let error):
                print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
            }
            
            restApi.deleteKey(keyData: kdata, completion: { result in
                print("\n... Delete acc <testCreate> ...")
                switch result {
                case .success(let data):
                    if let item = data.first {
                        print(" -> [OK] - ", item)
                    }
                case .failure(let error):
                    print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                }
                dispatchGroup.leave()
             })
        }
        
        dispatchGroup.enter()
        restApi.getSeed { result in
            print("\n... Get seed ...")
            switch result {
            case .success(let data):
                if let item = data.first {
                    print(" -> [OK] - ", item)
                    
                    let kdata = KeyPostData(name: "testRecover", pass: "test1234", seed: recoverSeed)
                    restApi.recoverKey(keyData: kdata, completion: { result in
                        print("\n... Recover testRecover with seed [\(recoverSeed)] ...")
                        switch result {
                        case .success(let data):
                            if let item = data.first, let field = item.address {
                                print(" -> [OK] - ", field)
                            }
                        case .failure(let error):
                            print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                        }
                        
                        restApi.deleteKey(keyData: kdata, completion: { result in
                            print("\n... Delete acc <testRecover> ...")
                            switch result {
                            case .success(let data):
                                if let item = data.first {
                                    print(" -> [OK] - ", item)
                                }
                            case .failure(let error):
                                print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                            }
                            dispatchGroup.leave()
                        })
                    })
                }
            case .failure(let error):
                print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
            }
        }
        
        dispatchGroup.enter()
        let data = KeyPasswordData(name: key1name, oldPass: acc1Pass, newPass: "newpass123")
        restApi.changeKeyPassword(keyData: data) { result in
            print("\n... Change pass for [\(key1name)] ...")
            switch result {
            case .success(let data):
                print(" -> [OK] - ", data.count)
            case .failure(let error):
                print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
            }
            
            let data1 = KeyPasswordData(name: key1name, oldPass: "newpass123", newPass: acc1Pass)
            restApi.changeKeyPassword(keyData: data1) { result in
                print("\n... Change pass back for [\(key1name)] ...")
                switch result {
                case .success(let data):
                    print(" -> [OK] - ", data.count)
                case .failure(let error):
                    print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.enter()
        restApi.getAccount(address: addr1) { result in
            print("\n... Get account for \(addr1) ...")
            switch result {
            case .success(let data):
                if let item = data.first, let field = item.type {
                    print(" -> [OK] - ", field)
                    
                    dispatchGroup.enter()
                    let data = TransferPostData(name: key1name, pass: acc1Pass, chain: chainID, amount: "1", denom: "photinos", accNum: item.value?.accountNumber ?? "0", sequence: item.value?.sequence ?? "0")
                    restApi.bankTransfer(to: addr2, transferData: data) { result in
                        print("\n... Transfer 1 photino ...")
                        switch result {
                        case .success(let data):
                            print(" -> [OK] - ", data.first?.hash ?? "")
                        case .failure(let error):
                            print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                        }
                        dispatchGroup.leave()

                    }

                }
            case .failure(let error):
                print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        restApi.getBalance(address: addr1) { result in
            print("\n... Get balance of \(addr1) ...")
            switch result {
            case .success(let data):
                print(" -> [OK] - ", data.first?.amount ?? "")
            case .failure(let error):
                print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
            }
            dispatchGroup.leave()
        }
        
        
        dispatchGroup.notify(queue: DispatchQueue.main) {
            print("\n... Test Completed ...")
        }
    }
}

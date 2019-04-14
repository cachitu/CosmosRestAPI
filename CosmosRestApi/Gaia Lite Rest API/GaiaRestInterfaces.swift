//
//  GaiaRestInterfaces.swift
//  CosmosRestApi
//
//  Created by Calin Chitu on 11/01/2019.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import Foundation


// Keys management

public protocol GaiaKeysManagementCapable {
    
    var node: GaiaNode? { get set }
    func retrieveAllKeys(node: GaiaNode, clientDelegate: KeysClientDelegate, completion: @escaping (_ data: [GaiaKey]?, _ errMsg: String?)->())
    func createKey(node: GaiaNode, clientDelegate: KeysClientDelegate, name: String, pass: String, seed: String?, completion: @escaping (_ data: GaiaKey?, _ errMsg: String?)->())
    func sendAssets(node: GaiaNode, clientDelegate: KeysClientDelegate, key: GaiaKey, feeAmount: String, toAddress: String, amount: String, denom: String, completion: ((_ data: TransferResponse?, _ errMsg: String?) -> ())?)
}

extension GaiaKeysManagementCapable {
    

    public func sendAssets(node: GaiaNode, clientDelegate: KeysClientDelegate, key: GaiaKey, feeAmount: String, toAddress: String, amount: String, denom: String, completion: ((_ data: TransferResponse?, _ errMsg: String?) -> ())?) {
        let restApi = GaiaRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
        key.getGaiaAccount(node: node, gaiaKey: key) { (gaiaAccount, errMsg) in
            if let gaiaAcc = gaiaAccount  {
                let data = TransferPostData(name: key.address,
                                            chain: node.network,
                                            amount: amount,
                                            denom: denom,
                                            accNum: gaiaAcc.accNumber,
                                            sequence:gaiaAcc.accSequence,
                                            fees: [TxFeeAmount(amount: feeAmount, denom: gaiaAcc.feeDenom)])
                restApi.bankTransfer(to: toAddress, transferData: data) { result in
                    print("\n... Transfered \(amount) \(denom) ...")
                    switch result {
                    case .success(let data):
                        GaiaLocalClient(delegate: clientDelegate).handleSignAndBroadcast(restApi: restApi, data: data, gaiaAcc: gaiaAcc, node: node, completion: completion)
                    case .failure(let error):
                        print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                        DispatchQueue.main.async { completion?(nil, error.localizedDescription) }
                    }
                }
            } else {
                DispatchQueue.main.async { completion?(nil, errMsg) }
            }
        }
    }
    
    public func withdraw(node: GaiaNode, clientDelegate: KeysClientDelegate, key: GaiaKey, feeAmount: String, validator: String, completion: ((_ data: TransferResponse?, _ errMsg: String?) -> ())?) {
        let restApi = GaiaRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
        key.getGaiaAccount(node: node, gaiaKey: key) { (gaiaAccount, errMsg) in
            if let gaiaAcc = gaiaAccount  {
                let data = TransferPostData(name: key.address,
                                            chain: node.network,
                                            accNum: gaiaAcc.accNumber,
                                            sequence: gaiaAcc.accSequence,
                                            fees: [TxFeeAmount(amount: feeAmount, denom: gaiaAcc.feeDenom)])
                restApi.withdrawReward(to: gaiaAcc.address, fromValidator: validator, transferData: data) { result in
                    switch result {
                    case .success(let data):
                        GaiaLocalClient(delegate: clientDelegate).handleSignAndBroadcast(restApi: restApi, data: data, gaiaAcc: gaiaAcc, node: node, completion: completion)
                    case .failure(let error):
                        print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                        DispatchQueue.main.async { completion?(nil, error.localizedDescription) }
                    }
                }
            } else {
                DispatchQueue.main.async { completion?(nil, errMsg) }
            }
        }
    }

    public func withdrawComission(node: GaiaNode, clientDelegate: KeysClientDelegate, key: GaiaKey, feeAmount: String, completion: ((_ data: TransferResponse?, _ errMsg: String?) -> ())?) {
        let restApi = GaiaRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
        key.getGaiaAccount(node: node, gaiaKey: key) { (gaiaAccount, errMsg) in
            if let gaiaAcc = gaiaAccount  {
                let data = TransferPostData(name: key.address,
                                            chain: node.network,
                                            accNum: gaiaAcc.accNumber,
                                            sequence: gaiaAcc.accSequence,
                                            fees: [TxFeeAmount(amount: feeAmount, denom: gaiaAcc.feeDenom)])
                restApi.withdrawComission(from: key.validator, transferData: data) { result in
                    switch result {
                    case .success(let data):
                        GaiaLocalClient(delegate: clientDelegate).handleSignAndBroadcast(restApi: restApi, data: data, gaiaAcc: gaiaAcc, node: node, completion: completion)
                    case .failure(let error):
                        print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                        DispatchQueue.main.async { completion?(nil, error.localizedDescription) }
                    }
                }
            } else {
                DispatchQueue.main.async { completion?(nil, errMsg) }
            }
        }
    }

    public func redelegateStake(node: GaiaNode, clientDelegate: KeysClientDelegate, key: GaiaKey, feeAmount: String, fromValidator: String, toValidator: String, amount: String, completion: ((_ data: TransferResponse?, _ errMsg: String?) -> ())?) {
        let restApi = GaiaRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
        key.getGaiaAccount(node: node, gaiaKey: key) { (gaiaAccount, errMsg) in
            if let gaiaAcc = gaiaAccount  {
                let data = RedelegationPostData(
                    sourceValidator: fromValidator,
                    destValidator: toValidator,
                    delegator: key.address,
                    name: key.address,
                    chain: node.network,
                    amount: amount,
                    denom: node.stakeDenom,
                    accNum: gaiaAcc.accNumber,
                    sequence: gaiaAcc.accSequence,
                    fees: [TxFeeAmount(amount: feeAmount, denom: gaiaAcc.feeDenom)])
                restApi.redelegation(from: key.address, transferData: data) { result in
                    switch result {
                    case .success(let data):
                        GaiaLocalClient(delegate: clientDelegate).handleSignAndBroadcast(restApi: restApi, data: data, gaiaAcc: gaiaAcc, node: node, completion: completion)
                    case .failure(let error):
                        print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                        completion?(nil, error.localizedDescription)
                    }
                }
            } else {
                DispatchQueue.main.async { completion?(nil, errMsg) }
            }
        }
    }

    public func delegateStake(node: GaiaNode, clientDelegate: KeysClientDelegate, key: GaiaKey, feeAmount: String, toValidator: String, amount: String, denom: String, completion: ((_ data: TransferResponse?, _ errMsg: String?) -> ())?) {
        let restApi = GaiaRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
        key.getGaiaAccount(node: node, gaiaKey: key) { (gaiaAccount, errMsg) in
            if let gaiaAcc = gaiaAccount  {
                let data = DelegationPostData(
                    validator: toValidator,
                    delegator: key.address,
                    name: key.address,
                    pass: key.getPassFromKeychain() ?? "",
                    chain: node.network,
                    amount: amount,
                    denom: denom,
                    accNum: gaiaAcc.accNumber,
                    sequence: gaiaAcc.accSequence,
                    fees: [TxFeeAmount(amount: feeAmount, denom: gaiaAcc.feeDenom)])
                restApi.delegation(from: key.address, transferData: data) { result in
                    switch result {
                    case .success(let data):
                        GaiaLocalClient(delegate: clientDelegate).handleSignAndBroadcast(restApi: restApi, data: data, gaiaAcc: gaiaAcc, node: node, completion: completion)
                    case .failure(let error):
                        print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                        completion?(nil, error.localizedDescription)
                    }
                }

            } else {
                DispatchQueue.main.async { completion?(nil, errMsg) }
            }
        }
    }

    public func unbondStake(node: GaiaNode, clientDelegate: KeysClientDelegate, key: GaiaKey, feeAmount: String, fromValidator: String, amount: String, denom: String, completion: ((_ data: TransferResponse?, _ errMsg: String?) -> ())?) {
        let restApi = GaiaRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
        key.getGaiaAccount(node: node, gaiaKey: key) { (gaiaAccount, errMsg) in
            if let gaiaAcc = gaiaAccount  {
                let data = UnbondingDelegationPostData(
                    validator: fromValidator,
                    delegator: key.address,
                    name: key.address,
                    chain: node.network,
                    amount: amount,
                    denom: node.stakeDenom,
                    accNum: gaiaAcc.accNumber,
                    sequence: gaiaAcc.accSequence,
                    fees: [TxFeeAmount(amount: feeAmount, denom: gaiaAcc.feeDenom)])
                restApi.unbonding(from: key.address, transferData: data) { result in
                    switch result {
                    case .success(let data):
                        GaiaLocalClient(delegate: clientDelegate).handleSignAndBroadcast(restApi: restApi, data: data, gaiaAcc: gaiaAcc, node: node, completion: completion)
                    case .failure(let error):
                        print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                        completion?(nil, error.localizedDescription)
                    }
                }
            } else {
                DispatchQueue.main.async { completion?(nil, errMsg) }
            }
        }
    }

    public func retrieveAllKeys(node: GaiaNode, clientDelegate: KeysClientDelegate, completion: @escaping (_ data: [GaiaKey]?, _ errMsg: String?)->()) {
        
        GaiaLocalClient(delegate: clientDelegate).getKeys { result in
            switch result {
            case .success(let data):
                DispatchQueue.main.async { completion(data, nil) }
            case .failure(let error): completion(nil, error.localizedDescription)
             }
        }
    }
    
    public func createKey(node: GaiaNode, clientDelegate: KeysClientDelegate, name: String, pass: String, seed: String? = nil, completion: @escaping (_ data: GaiaKey?, _ errMsg: String?)->()) {
        if let validSeed = seed {
            createGaiaKey(clientDelegate: clientDelegate, name: name, pass: pass, seed: validSeed) { rawkey, seed, errMessage in
                if let error = errMessage {
                    DispatchQueue.main.async { completion(nil, error) }
                } else if let validKey = rawkey {
                    let gaiaKey = GaiaKey(data: validKey, nodeId: node.nodeID)
                    gaiaKey.savePassToKeychain(pass: pass)
                    DispatchQueue.main.async { completion(gaiaKey, nil) }
                }
           }
        } else {
            createSeed(clientDelegate: clientDelegate, name: name, pass: pass) { rawkey, seed, errMessage in
                if let error = errMessage {
                    DispatchQueue.main.async {completion(nil, error) }
                } else if let validKey = rawkey {
                    let gaiaKey = GaiaKey(data: validKey, nodeId: node.nodeID)
                    gaiaKey.savePassToKeychain(pass: pass)
                    DispatchQueue.main.async { completion(gaiaKey, nil) }
                }
            }
        }
    }
    
    func createSeed(clientDelegate: KeysClientDelegate, name: String, pass: String, completion: @escaping (_ data: Key?, _ seed: String?, _ errMsg: String?)->()) {
        GaiaLocalClient(delegate: clientDelegate).createSeed { result in
            switch result {
            case .success(let data):
                if let seed = data.first {
                    self.createGaiaKey(clientDelegate: clientDelegate, name: name, pass: pass, seed: seed, completion: completion)
                } else {
                    DispatchQueue.main.async { completion(nil, nil, "Failed to generate a seed") }
                }
            case .failure(let error):
                DispatchQueue.main.async { completion(nil, nil, error.localizedDescription) }
            }
        }
    }
    
    func createGaiaKey(clientDelegate: KeysClientDelegate, name: String, pass: String, seed: String, completion: @escaping (_ data: Key?, _ seed: String?, _ errMsg: String?)->()) {
        let kdata = KeyPostData(name: name, pass: pass, seed: seed)
        GaiaLocalClient(delegate: clientDelegate).recoverKey(keyData: kdata, completion: { result in
            switch result {
            case .success(let data):
                if let item = data.first as? Key {
                    DispatchQueue.main.async { completion(item, seed, nil) }
                }
            case .failure(let error):
                DispatchQueue.main.async { completion(nil, nil, error.localizedDescription) }
            }
        })
    }
}

public protocol GaiaValidatorsCapable {
    
    var node: GaiaNode? { get set }
    func retrieveAllValidators(node: GaiaNode, completion: @escaping (_ data: [GaiaValidator]?, _ errMsg: String?)->())
}

extension GaiaValidatorsCapable {
    
    public func retrieveAllValidators(node: GaiaNode, completion: @escaping (_ data: [GaiaValidator]?, _ errMsg: String?)->()) {
        let restApi = GaiaRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
        
        restApi.getStakeValidators { result in
            switch result {
            case .success(let data):
                var gaiaValidators: [GaiaValidator] = []
                for validator in data {
                    gaiaValidators.append(GaiaValidator(validator: validator))
                }
                DispatchQueue.main.async { completion(gaiaValidators, nil) }
            case .failure(let error): completion(nil, error.localizedDescription)
                DispatchQueue.main.async { completion(nil, error.localizedDescription) }
            }
        }
    }
}

public protocol GaiaGovernaceCapable {
    
    var node: GaiaNode? { get set }
    
    func retrieveAllPropsals(node: GaiaNode, completion: @escaping (_ data: [GaiaProposal]?, _ errMsg: String?)->())
    func getPropsalDetails(node: GaiaNode, proposal: GaiaProposal, completion: @escaping (_ data: GaiaProposal?, _ errMsg: String?)->())
    func vote(for proposal: String, option: String, node: GaiaNode, clientDelegate: KeysClientDelegate, key: GaiaKey, feeAmount: String, completion: ((_ data: TransferResponse?, _ errMsg: String?) -> ())?)
    func propose(deposit: String, title: String, description: String, type: ProposalType, node: GaiaNode, clientDelegate: KeysClientDelegate, key: GaiaKey, feeAmount: String, completion: ((_ data: TransferResponse?, _ errMsg: String?) -> ())?)
    func depositToProposal(proposalId: String, amount: String, node: GaiaNode, clientDelegate: KeysClientDelegate, key: GaiaKey, feeAmount: String, completion: ((_ data: TransferResponse?, _ errMsg: String?) -> ())?)
}

extension GaiaGovernaceCapable {
    
    public func retrieveAllPropsals(node: GaiaNode, completion: @escaping (_ data: [GaiaProposal]?, _ errMsg: String?)->()) {
        let restApi = GaiaRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
        
        restApi.getPorposals { result in
            switch result {
            case .success(let data):
                var gaiaPropsals: [GaiaProposal] = []
                for proposal in data {
                    gaiaPropsals.append(GaiaProposal(proposal: proposal))
                }
                DispatchQueue.main.async { completion(gaiaPropsals, nil) }
            case .failure(let error): completion(nil, error.localizedDescription)
            DispatchQueue.main.async { completion(nil, error.localizedDescription) }
            }
        }
    }
    
    public func getPropsalDetails(node: GaiaNode, proposal: GaiaProposal, completion: @escaping (_ data: GaiaProposal?, _ errMsg: String?)->()) {
        let restApi = GaiaRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
        
        restApi.getPorposalTally(forId: proposal.proposalId) { result in
            switch result {
            case .success(let data):
                if let tally = data.first {
                    proposal.yes = tally.yes ?? "0"
                    proposal.no = tally.no ?? "0"
                    proposal.abstain = tally.abstain ?? "0"
                    proposal.noWithVeto = tally.noWithVeto ?? "0"
                }
                restApi.getPorposalVotes(forId: proposal.proposalId) { result in
                    switch result {
                    case .success(let data):
                        proposal.votes = data
                        DispatchQueue.main.async { completion(proposal, nil) }
                    case .failure(let error): completion(nil, error.localizedDescription)
                    DispatchQueue.main.async { completion(nil, error.localizedDescription) }
                    }
                }
            case .failure(let error): completion(nil, error.localizedDescription)
            DispatchQueue.main.async { completion(nil, error.localizedDescription) }
            }
        }
    }

    public func vote(for proposal: String, option: String, node: GaiaNode, clientDelegate: KeysClientDelegate, key: GaiaKey, feeAmount: String, completion: ((_ data: TransferResponse?, _ errMsg: String?) -> ())?) {
        let restApi = GaiaRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
        key.getGaiaAccount(node: node, gaiaKey: key) { (gaiaAccount, errMsg) in
            if let gaiaAcc = gaiaAccount  {
                let data = ProposalVotePostData(keyName: key.address,
                                                chain: node.network,
                                                accNum: gaiaAcc.accNumber,
                                                sequence: gaiaAcc.accSequence,
                                                voter: key.address,
                                                option: option,
                                                fees: [TxFeeAmount(amount: feeAmount, denom: gaiaAcc.feeDenom)])
                restApi.voteProposal(id: proposal, transferData: data) { result in
                    print("\n... Submit vote id \(proposal) ...")
                    switch result {
                    case .success(let data):
                        GaiaLocalClient(delegate: clientDelegate).handleSignAndBroadcast(restApi: restApi, data: data, gaiaAcc: gaiaAcc, node: node, completion: completion)
                    case .failure(let error):
                        print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                        completion?(nil, error.localizedDescription)
                    }
                }
            } else {
                DispatchQueue.main.async { completion?(nil, errMsg) }
            }
        }
    }
    
    public func propose(deposit: String, title: String, description: String, type: ProposalType, node: GaiaNode, clientDelegate: KeysClientDelegate, key: GaiaKey, feeAmount: String, completion: ((_ data: TransferResponse?, _ errMsg: String?) -> ())?) {
        let restApi = GaiaRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
        key.getGaiaAccount(node: node, gaiaKey: key) { (gaiaAccount, errMsg) in
            if let gaiaAcc = gaiaAccount  {
                
                let data = ProposalPostData(
                    keyName: key.address,
                    chain: node.network,
                    deposit: deposit,
                    denom: gaiaAcc.denom,
                    accNum: gaiaAcc.accNumber,
                    sequence: gaiaAcc.accSequence,
                    title: title,
                    description: description,
                    proposalType: type,
                    proposer: key.address,
                    fees: [TxFeeAmount(amount: feeAmount, denom: gaiaAcc.feeDenom)])
                restApi.submitProposal(transferData: data) { result in
                    switch result {
                    case .success(let data):
                        GaiaLocalClient(delegate: clientDelegate).handleSignAndBroadcast(restApi: restApi, data: data, gaiaAcc: gaiaAcc, node: node, completion: completion)
                    case .failure(let error):
                        print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                        completion?(nil, error.localizedDescription)
                    }
                }
            } else {
                DispatchQueue.main.async { completion?(nil, errMsg) }
            }
        }
    }

    public func depositToProposal(proposalId: String, amount: String, node: GaiaNode, clientDelegate: KeysClientDelegate, key: GaiaKey, feeAmount: String, completion: ((_ data: TransferResponse?, _ errMsg: String?) -> ())?) {
        let restApi = GaiaRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
        key.getGaiaAccount(node: node, gaiaKey: key) { (gaiaAccount, errMsg) in
            if let gaiaAcc = gaiaAccount  {
                
                let data = ProposalDepositPostData(
                    keyName: key.address,
                    chain: node.network,
                    deposit: amount,
                    denom: gaiaAcc.denom,
                    accNum: gaiaAcc.accNumber,
                    sequence: gaiaAcc.accSequence,
                    depositor: key.address,
                    fees: [TxFeeAmount(amount: feeAmount, denom: gaiaAcc.feeDenom)])
                restApi.depositToProposal(id: proposalId, transferData: data) { result in
                    switch result {
                    case .success(let data):
                        GaiaLocalClient(delegate: clientDelegate).handleSignAndBroadcast(restApi: restApi, data: data, gaiaAcc: gaiaAcc, node: node, completion: completion)
                    case .failure(let error):
                        print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                        completion?(nil, error.localizedDescription)
                    }
                }
            } else {
                DispatchQueue.main.async { completion?(nil, errMsg) }
            }
        }
    }
}

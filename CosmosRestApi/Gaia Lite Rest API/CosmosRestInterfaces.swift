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
    func createKey(node: TDMNode, clientDelegate: KeysClientDelegate, name: String, pass: String, mnemonic: String?, completion: @escaping (_ data: GaiaKey?, _ errMsg: String?)->())
    func sendAssets(node: TDMNode, clientDelegate: KeysClientDelegate, key: GaiaKey, feeAmount: String, toAddress: String, amount: String, denom: String, completion: ((_ data: TransferResponse?, _ errMsg: String?) -> ())?)
}

extension GaiaKeysManagementCapable {
    
    
    public func sendAssets(node: TDMNode, clientDelegate: KeysClientDelegate, key: GaiaKey, feeAmount: String, toAddress: String, amount: String, denom: String, completion: ((_ data: TransferResponse?, _ errMsg: String?) -> ())?) {
        let restApi = CosmosRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
        key.getGaiaAccount(node: node, gaiaKey: key) { (gaiaAccount, errMsg) in
            if let gaiaAcc = gaiaAccount  {
                let data = TransferPostData(name: key.address,
                                            memo: node.defaultMemo,
                                            chain: node.network,
                                            amount: amount,
                                            denom: denom,
                                            accNum: gaiaAcc.accNumber,
                                            sequence:gaiaAcc.accSequence,
                                            fees: node.feeAmount != "0" ? [TxFeeAmount(amount: node.feeAmount, denom: node.feeDenom)] : [])
                switch node.type {
                case .certik:
                    restApi.bankTransferV2(to: toAddress, transferData: data) { result in
                        print("\n... Transfered \(amount) \(denom) ...")
                        switch result {
                        case .success(let data):
                            let adjusted = TransactionTx(type: "bla", value: data.first)
                            GaiaLocalClient(delegate: clientDelegate).handleSignAndBroadcast(restApi: restApi, data: [adjusted], gaiaAcc: gaiaAcc, node: node, completion: completion)
                        case .failure(let error):
                            print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                            DispatchQueue.main.async { completion?(nil, error.localizedDescription) }
                        }
                    }
                default:
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
                }
            } else {
                DispatchQueue.main.async { completion?(nil, errMsg) }
            }
        }
    }
    
    public func withdraw(node: TDMNode, clientDelegate: KeysClientDelegate, key: GaiaKey, feeAmount: String, validator: String, completion: ((_ data: TransferResponse?, _ errMsg: String?) -> ())?) {
        
        let restApi = CosmosRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
        key.getGaiaAccount(node: node, gaiaKey: key) { (gaiaAccount, errMsg) in
            if let gaiaAcc = gaiaAccount  {
                let data = TransferPostData(name: key.address,
                                            memo: node.defaultMemo,
                                            chain: node.network,
                                            accNum: gaiaAcc.accNumber,
                                            sequence: gaiaAcc.accSequence,
                                            fees: [TxFeeAmount(amount: node.feeAmount, denom: node.feeDenom)])
                switch node.type {
                case .certik:
                    restApi.withdrawRewardV2(to: gaiaAcc.address, fromValidator: validator, transferData: data) { result in
                        switch result {
                        case .success(let data):
                            let adjusted = TransactionTx(type: "bla", value: data.first)
                            GaiaLocalClient(delegate: clientDelegate).handleSignAndBroadcast(restApi: restApi, data: [adjusted], gaiaAcc: gaiaAcc, node: node, completion: completion)
                        case .failure(let error):
                            print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                            DispatchQueue.main.async { completion?(nil, error.localizedDescription) }
                        }
                    }
                default:
                    restApi.withdrawReward(to: gaiaAcc.address, fromValidator: validator, transferData: data) { result in
                        switch result {
                        case .success(let data):
                            GaiaLocalClient(delegate: clientDelegate).handleSignAndBroadcast(restApi: restApi, data: data, gaiaAcc: gaiaAcc, node: node, completion: completion)
                        case .failure(let error):
                            print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                            DispatchQueue.main.async { completion?(nil, error.localizedDescription) }
                        }
                    }
                }
            } else {
                DispatchQueue.main.async { completion?(nil, errMsg) }
            }
        }
    }

    public func withdrawComission(node: TDMNode, clientDelegate: KeysClientDelegate, key: GaiaKey, feeAmount: String, completion: ((_ data: TransferResponse?, _ errMsg: String?) -> ())?) {
        let restApi = CosmosRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
        key.getGaiaAccount(node: node, gaiaKey: key) { (gaiaAccount, errMsg) in
            if let gaiaAcc = gaiaAccount  {
                let data = TransferPostData(name: key.address,
                                            memo: node.defaultMemo,
                                            chain: node.network,
                                            accNum: gaiaAcc.accNumber,
                                            sequence: gaiaAcc.accSequence,
                                            fees: [TxFeeAmount(amount: node.feeAmount, denom: node.feeDenom)])
                switch node.type {
                case .certik:
                    restApi.withdrawComissionV2(from: key.validator, transferData: data) { result in
                        switch result {
                        case .success(let data):
                            let adjusted = TransactionTx(type: "bla", value: data.first)
                            GaiaLocalClient(delegate: clientDelegate).handleSignAndBroadcast(restApi: restApi, data: [adjusted], gaiaAcc: gaiaAcc, node: node, completion: completion)
                        case .failure(let error):
                            print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                            DispatchQueue.main.async { completion?(nil, error.localizedDescription) }
                        }
                    }
                default:
                    restApi.withdrawComission(from: key.validator, transferData: data) { result in
                        switch result {
                        case .success(let data):
                            GaiaLocalClient(delegate: clientDelegate).handleSignAndBroadcast(restApi: restApi, data: data, gaiaAcc: gaiaAcc, node: node, completion: completion)
                        case .failure(let error):
                            print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                            DispatchQueue.main.async { completion?(nil, error.localizedDescription) }
                        }
                    }
                }
            } else {
                DispatchQueue.main.async { completion?(nil, errMsg) }
            }
        }
    }

    public func redelegateStake(node: TDMNode, clientDelegate: KeysClientDelegate, key: GaiaKey, feeAmount: String, fromValidator: String, toValidator: String, amount: String, completion: ((_ data: TransferResponse?, _ errMsg: String?) -> ())?) {
        let restApi = CosmosRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
        key.getGaiaAccount(node: node, gaiaKey: key) { (gaiaAccount, errMsg) in
            if let gaiaAcc = gaiaAccount  {
                let data = RedelegationPostData(
                    sourceValidator: fromValidator,
                    destValidator: toValidator,
                    delegator: key.address,
                    name: key.address,
                    memo: node.defaultMemo,
                    chain: node.network,
                    amount: amount,
                    denom: node.stakeDenom,
                    accNum: gaiaAcc.accNumber,
                    sequence: gaiaAcc.accSequence,
                    fees: [TxFeeAmount(amount: node.feeAmount, denom: node.feeDenom)])
                switch node.type {
                case .certik:
                    restApi.redelegationV2(from: key.address, transferData: data) { result in
                        switch result {
                        case .success(let data):
                            let adjusted = TransactionTx(type: "bla", value: data.first)
                            GaiaLocalClient(delegate: clientDelegate).handleSignAndBroadcast(restApi: restApi, data: [adjusted], gaiaAcc: gaiaAcc, node: node, completion: completion)
                        case .failure(let error):
                            print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                            DispatchQueue.main.async { completion?(nil, error.localizedDescription) }
                        }
                    }
                default:
                    restApi.redelegation(from: key.address, transferData: data) { result in
                        switch result {
                        case .success(let data):
                            GaiaLocalClient(delegate: clientDelegate).handleSignAndBroadcast(restApi: restApi, data: data, gaiaAcc: gaiaAcc, node: node, completion: completion)
                        case .failure(let error):
                            print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                            DispatchQueue.main.async { completion?(nil, error.localizedDescription) }
                        }
                    }
                }
            } else {
                DispatchQueue.main.async { completion?(nil, errMsg) }
            }
        }
    }
    
    public func delegateStake(node: TDMNode, clientDelegate: KeysClientDelegate, key: GaiaKey, feeAmount: String, toValidator: String, amount: String, denom: String, completion: ((_ data: TransferResponse?, _ errMsg: String?) -> ())?) {
        let restApi = CosmosRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
        key.getGaiaAccount(node: node, gaiaKey: key) { (gaiaAccount, errMsg) in
            if let gaiaAcc = gaiaAccount  {
                let data = DelegationPostData(
                    validator: toValidator,
                    delegator: key.address,
                    name: key.address,
                    memo: node.defaultMemo,
                    pass: key.getPassFromKeychain() ?? "",
                    chain: node.network,
                    amount: amount,
                    denom: denom,
                    accNum: gaiaAcc.accNumber,
                    sequence: gaiaAcc.accSequence,
                    fees: [TxFeeAmount(amount: node.feeAmount, denom: node.feeDenom)])
                switch node.type {
                case .certik:
                    restApi.delegationV2(from: key.address, transferData: data) { result in
                        switch result {
                        case .success(let data):
                            let adjusted = TransactionTx(type: "bla", value: data.first)
                            GaiaLocalClient(delegate: clientDelegate).handleSignAndBroadcast(restApi: restApi, data: [adjusted], gaiaAcc: gaiaAcc, node: node, completion: completion)
                        case .failure(let error):
                            print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                            DispatchQueue.main.async { completion?(nil, error.localizedDescription) }
                        }
                    }
                default:
                    restApi.delegation(from: key.address, transferData: data) { result in
                        switch result {
                        case .success(let data):
                            GaiaLocalClient(delegate: clientDelegate).handleSignAndBroadcast(restApi: restApi, data: data, gaiaAcc: gaiaAcc, node: node, completion: completion)
                        case .failure(let error):
                            print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                            DispatchQueue.main.async { completion?(nil, error.localizedDescription) }
                        }
                    }
                }

            } else {
                DispatchQueue.main.async { completion?(nil, errMsg) }
            }
        }
    }
    
    public func unbondStake(node: TDMNode, clientDelegate: KeysClientDelegate, key: GaiaKey, feeAmount: String, fromValidator: String, amount: String, denom: String, completion: ((_ data: TransferResponse?, _ errMsg: String?) -> ())?) {
        let restApi = CosmosRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
        key.getGaiaAccount(node: node, gaiaKey: key) { (gaiaAccount, errMsg) in
            if let gaiaAcc = gaiaAccount  {
                let data = UnbondingDelegationPostData(
                    validator: fromValidator,
                    delegator: key.address,
                    name: key.address,
                    memo: node.defaultMemo,
                    chain: node.network,
                    amount: amount,
                    denom: node.stakeDenom,
                    accNum: gaiaAcc.accNumber,
                    sequence: gaiaAcc.accSequence,
                    fees: [TxFeeAmount(amount: node.feeAmount, denom: node.feeDenom)])
                switch node.type {
                case .certik:
                    restApi.unbondingV2(from: key.address, transferData: data) { result in
                        switch result {
                        case .success(let data):
                            let adjusted = TransactionTx(type: "bla", value: data.first)
                            GaiaLocalClient(delegate: clientDelegate).handleSignAndBroadcast(restApi: restApi, data: [adjusted], gaiaAcc: gaiaAcc, node: node, completion: completion)
                        case .failure(let error):
                            print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                            DispatchQueue.main.async { completion?(nil, error.localizedDescription) }
                        }
                    }
                default:
                    restApi.unbonding(from: key.address, transferData: data) { result in
                        switch result {
                        case .success(let data):
                            GaiaLocalClient(delegate: clientDelegate).handleSignAndBroadcast(restApi: restApi, data: data, gaiaAcc: gaiaAcc, node: node, completion: completion)
                        case .failure(let error):
                            print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                            DispatchQueue.main.async { completion?(nil, error.localizedDescription) }
                        }
                    }
                }
            } else {
                DispatchQueue.main.async { completion?(nil, errMsg) }
            }
        }
    }

    public func createKey(node: TDMNode, clientDelegate: KeysClientDelegate, name: String, pass: String, mnemonic: String? = nil, completion: @escaping (_ data: GaiaKey?, _ errMsg: String?)->()) {
        if let validMnemonic = mnemonic {
            createGaiaKey(clientDelegate: clientDelegate, name: name, pass: pass, mnemonic: validMnemonic) { rawkey, seed, errMessage in
                if let error = errMessage {
                    DispatchQueue.main.async { completion(nil, error) }
                } else if let validKey = rawkey {
                    let gaiaKey = GaiaKey(data: validKey, nodeId: node.nodeID, networkName: node.network)
                    gaiaKey.savePassToKeychain(pass: pass)
                    DispatchQueue.main.async { completion(gaiaKey, nil) }
                }
           }
        } else {
            createSeed(clientDelegate: clientDelegate, name: name, pass: pass) { rawkey, seed, errMessage in
                if let error = errMessage {
                    DispatchQueue.main.async {completion(nil, error) }
                } else if let validKey = rawkey {
                    let gaiaKey = GaiaKey(data: validKey, nodeId: node.nodeID, networkName: node.network)
                    gaiaKey.savePassToKeychain(pass: pass)
                    DispatchQueue.main.async { completion(gaiaKey, nil) }
                }
            }
        }
    }
    
    func createSeed(clientDelegate: KeysClientDelegate, name: String, pass: String, completion: @escaping (_ data: TDMKey?, _ seed: String?, _ errMsg: String?)->()) {
        GaiaLocalClient(delegate: clientDelegate).createSeed { result in
            switch result {
            case .success(let data):
                if let seed = data.first {
                    self.createGaiaKey(clientDelegate: clientDelegate, name: name, pass: pass, mnemonic: seed, completion: completion)
                } else {
                    DispatchQueue.main.async { completion(nil, nil, "Failed to generate a seed") }
                }
            case .failure(let error):
                DispatchQueue.main.async { completion(nil, nil, error.localizedDescription) }
            }
        }
    }
    
    func createGaiaKey(clientDelegate: KeysClientDelegate, name: String, pass: String, mnemonic: String, completion: @escaping (_ data: TDMKey?, _ seed: String?, _ errMsg: String?)->()) {
        let kdata = KeyPostData(name: name, address: "", pass: pass, mnemonic: mnemonic)
        GaiaLocalClient(delegate: clientDelegate).recoverKey(keyData: kdata, completion: { result in
            switch result {
            case .success(let data):
                if let item = data.first as? TDMKey {
                    DispatchQueue.main.async { completion(item, mnemonic, nil) }
                }
            case .failure(let error):
                DispatchQueue.main.async { completion(nil, nil, error.localizedDescription) }
            }
        })
    }
}

public protocol GaiaValidatorsCapable {
    func retrieveAllValidators(node: TDMNode, status: String, completion: @escaping (_ data: [GaiaValidator]?, _ errMsg: String?)->())
}

extension GaiaValidatorsCapable {
    
    public func retrieveAllValidators(node: TDMNode, status: String, completion: @escaping (_ data: [GaiaValidator]?, _ errMsg: String?)->()) {
        switch node.type {
        case .stargate, .regen, .iris, .iris_fuxi, .agoric, .osmosis, .microtick, .certik, .emoney, .terra, .terra_118, .juno:
            let restApi = CosmosRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
            restApi.getStakeValidatorsStargate(status: status) { result in
                switch result {
                case .success(let data):
                    var gaiaValidators: [GaiaValidator] = []
                    for validator in data.first?.result ?? [] {
                        gaiaValidators.append(GaiaValidator(validator: validator))
                    }
                    DispatchQueue.main.async { completion(gaiaValidators, nil) }
                case .failure(let error):
                    DispatchQueue.main.async { completion(nil, error.localizedDescription) }
                }
            }
       default:
            let restApi = CosmosRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
            restApi.getStakeValidatorsV2(status: status) { result in
                switch result {
                case .success(let data):
                    var gaiaValidators: [GaiaValidator] = []
                    for validator in data.first?.result ?? [] {
                        gaiaValidators.append(GaiaValidator(validator: validator))
                    }
                    DispatchQueue.main.async { completion(gaiaValidators, nil) }
                case .failure(let error):
                    DispatchQueue.main.async { completion(nil, error.localizedDescription) }
                }
            }
        }
    }
}

public protocol GaiaGovernaceCapable {
    func retrieveAllPropsals(node: TDMNode, completion: @escaping (_ data: [GaiaProposal]?, _ errMsg: String?)->())
    func getPropsalDetails(node: TDMNode, proposal: GaiaProposal, completion: @escaping (_ data: GaiaProposal?, _ errMsg: String?)->())
    func vote(for proposal: String, option: String, node: TDMNode, clientDelegate: KeysClientDelegate, key: GaiaKey, feeAmount: String, completion: ((_ data: TransferResponse?, _ errMsg: String?) -> ())?)
    func propose(deposit: String, title: String, description: String, type: ProposalType, node: TDMNode, clientDelegate: KeysClientDelegate, key: GaiaKey, feeAmount: String, completion: ((_ data: TransferResponse?, _ errMsg: String?) -> ())?)
    func depositToProposal(proposalId: String, amount: String, node: TDMNode, clientDelegate: KeysClientDelegate, key: GaiaKey, feeAmount: String, completion: ((_ data: TransferResponse?, _ errMsg: String?) -> ())?)
}

extension GaiaGovernaceCapable {
    
    public func retrieveAllPropsals(node: TDMNode, completion: @escaping (_ data: [GaiaProposal]?, _ errMsg: String?)->()) {
        switch node.type {
        case .stargate, .regen, .iris, .iris_fuxi, .agoric, .osmosis, .microtick, .certik, .emoney, .terra, .terra_118, .juno:
            let restApi = CosmosRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
            restApi.getPorposalsStargate { result in
                switch result {
                case .success(let data):
                    var gaiaPropsals: [GaiaProposal] = []
                    for proposal in data.first?.result ?? [] {
                        gaiaPropsals.append(GaiaProposal(proposal: proposal))
                    }
                    DispatchQueue.main.async { completion(gaiaPropsals, nil) }
                case .failure(let error):
                    DispatchQueue.main.async { completion(nil, error.localizedDescription) }
                }
            }
        default:
            let restApi = CosmosRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
            restApi.getPorposalsV2 { result in
                switch result {
                case .success(let data):
                    var gaiaPropsals: [GaiaProposal] = []
                    for proposal in data.first?.result ?? [] {
                        gaiaPropsals.append(GaiaProposal(proposal: proposal))
                    }
                    DispatchQueue.main.async { completion(gaiaPropsals, nil) }
                case .failure(let error):
                    DispatchQueue.main.async { completion(nil, error.localizedDescription) }
                }
            }
        }
    }
    
    public func getPropsalDetails(node: TDMNode, proposal: GaiaProposal, completion: @escaping (_ data: GaiaProposal?, _ errMsg: String?)->()) {
        
        func stringStatus(for intStatus: Int) -> String {
            switch intStatus {
            case 1: return "Yes"
            case 2: return "Abstain"
            case 3: return "No"
            case 4: return "No With Veto"
            default: return "-"
            }
        }

        switch node.type {

        case .stargate, .regen, .iris, .iris_fuxi, .agoric, .osmosis, .certik, .emoney, .terra, .terra_118, .juno:
            let restApi = CosmosRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
            restApi.getPorposalTallyStargate(forId: proposal.proposalId) { result in
                switch result {
                case .success(let data):
                    if let tally = data.first?.result {
                        proposal.yes = tally.yes ?? "0"
                        proposal.no = tally.no ?? "0"
                        proposal.abstain = tally.abstain ?? "0"
                        proposal.noWithVeto = tally.noWithVeto ?? "0"
                    }
                    restApi.getPorposalVotesStargate(forId: proposal.proposalId) { result in
                        switch result {
                        case .success(let data):
                            let votes = data.first?.result ?? []
                            var compatibleVotes: [ProposalVote] = []
                            for vote in votes {
                                let newVote = ProposalVote(voter: vote.voter, proposalId: vote.proposalId, option:"\(stringStatus(for: vote.option ?? -1))")
                                compatibleVotes.append(newVote)
                            }
                            proposal.votes = compatibleVotes
                            DispatchQueue.main.async { completion(proposal, nil) }
                        case .failure(let error):
                            DispatchQueue.main.async { completion(nil, error.localizedDescription) }
                        }
                    }
                case .failure(let error):
                    DispatchQueue.main.async { completion(nil, error.localizedDescription) }
                }
            }
        default:
            let restApi = CosmosRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
            restApi.getPorposalTallyV2(forId: proposal.proposalId) { result in
                switch result {
                case .success(let data):
                    if let tally = data.first?.result {
                        proposal.yes = tally.yes ?? "0"
                        proposal.no = tally.no ?? "0"
                        proposal.abstain = tally.abstain ?? "0"
                        proposal.noWithVeto = tally.noWithVeto ?? "0"
                    }
                    restApi.getPorposalVotesV2(forId: proposal.proposalId) { result in
                        switch result {
                        case .success(let data):
                            proposal.votes = data.first?.result ?? []
                            DispatchQueue.main.async { completion(proposal, nil) }
                        case .failure(let error):
                            DispatchQueue.main.async { completion(nil, error.localizedDescription) }
                        }
                    }
                case .failure(let error):
                    DispatchQueue.main.async { completion(nil, error.localizedDescription) }
                }
            }
        }
    }

    public func vote(for proposal: String, option: String, node: TDMNode, clientDelegate: KeysClientDelegate, key: GaiaKey, feeAmount: String, completion: ((_ data: TransferResponse?, _ errMsg: String?) -> ())?) {
        let restApi = CosmosRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
        key.getGaiaAccount(node: node, gaiaKey: key) { (gaiaAccount, errMsg) in
            if let gaiaAcc = gaiaAccount  {
                let data = ProposalVotePostData(keyName: key.address,
                                                memo: node.defaultMemo,
                                                chain: node.network,
                                                accNum: gaiaAcc.accNumber,
                                                sequence: gaiaAcc.accSequence,
                                                voter: key.address,
                                                option: option,
                                                fees: [TxFeeAmount(amount: node.feeAmount, denom: node.feeDenom)])
                restApi.voteProposal(id: proposal, transferData: data) { result in
                    print("\n... Submit vote id \(proposal) ...")
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
    
    public func propose(deposit: String, title: String, description: String, type: ProposalType, node: TDMNode, clientDelegate: KeysClientDelegate, key: GaiaKey, feeAmount: String, completion: ((_ data: TransferResponse?, _ errMsg: String?) -> ())?) {
        let restApi = CosmosRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
        key.getGaiaAccount(node: node, gaiaKey: key) { (gaiaAccount, errMsg) in
            if let gaiaAcc = gaiaAccount  {
                switch node.type {
                default:
                    let data = ProposalPostData(
                        keyName: key.address,
                        memo: node.defaultMemo,
                        chain: node.network,
                        deposit: deposit,
                        denom: gaiaAcc.denom,
                        accNum: gaiaAcc.accNumber,
                        sequence: gaiaAcc.accSequence,
                        title: title,
                        description: description,
                        proposalType: type,
                        proposer: key.address,
                        fees: [TxFeeAmount(amount: node.feeAmount, denom: node.feeDenom)])
                    restApi.submitProposal(transferData: data) { result in
                        switch result {
                        case .success(let data):
                            GaiaLocalClient(delegate: clientDelegate).handleSignAndBroadcast(restApi: restApi, data: data, gaiaAcc: gaiaAcc, node: node, completion: completion)
                        case .failure(let error):
                            print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                            DispatchQueue.main.async { completion?(nil, error.localizedDescription) }
                        }
                    }
                }
            } else {
                DispatchQueue.main.async { completion?(nil, errMsg) }
            }
        }
    }

    public func depositToProposal(proposalId: String, amount: String, node: TDMNode, clientDelegate: KeysClientDelegate, key: GaiaKey, feeAmount: String, completion: ((_ data: TransferResponse?, _ errMsg: String?) -> ())?) {
        let restApi = CosmosRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
        key.getGaiaAccount(node: node, gaiaKey: key) { (gaiaAccount, errMsg) in
            if let gaiaAcc = gaiaAccount  {
                switch node.type {
                default:
                    let data = ProposalDepositPostData(
                        keyName: key.address,
                        memo: node.defaultMemo,
                        chain: node.network,
                        deposit: amount,
                        denom: gaiaAcc.denom,
                        accNum: gaiaAcc.accNumber,
                        sequence: gaiaAcc.accSequence,
                        depositor: key.address,
                        fees: [TxFeeAmount(amount: node.feeAmount, denom: node.feeDenom)])
                    restApi.depositToProposal(id: proposalId, transferData: data) { result in
                        switch result {
                        case .success(let data):
                            GaiaLocalClient(delegate: clientDelegate).handleSignAndBroadcast(restApi: restApi, data: data, gaiaAcc: gaiaAcc, node: node, completion: completion)
                        case .failure(let error):
                            print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                            DispatchQueue.main.async { completion?(nil, error.localizedDescription) }
                        }
                    }
                }
            } else {
                DispatchQueue.main.async { completion?(nil, errMsg) }
            }
        }
    }
}

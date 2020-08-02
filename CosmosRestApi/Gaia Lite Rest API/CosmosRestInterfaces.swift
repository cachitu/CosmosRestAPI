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
                switch node.type {
                case .iris, .iris_fuxi:
                    let irisApi = IrisRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
                    let req = IrisBaseReq(chainId: node.network, gas: "20000", fee: "\(node.feeAmount)\(node.feeDenom)", memo: node.defaultMemo)
                    let data = IrisBankSendData(baseTx: req, recipient: toAddress, amount: amount + denom)
                    irisApi.bankTransfer(from: key.address, transferData: data) { result in
                        print("\n... Transfered \(amount) \(denom) ...")
                        switch result {
                        case .success(let data):
                            GaiaLocalClient(delegate: clientDelegate).handleSignAndBroadcast(restApi: restApi, data: data, gaiaAcc: gaiaAcc, node: node, irisSpaghetti: true, completion: completion)
                        case .failure(let error):
                            print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                            DispatchQueue.main.async { completion?(nil, error.localizedDescription) }
                        }
                        
                    }
                    
                default:
                    let data = TransferPostData(name: key.address,
                                                memo: node.defaultMemo,
                                                chain: node.network,
                                                amount: amount,
                                                denom: denom,
                                                accNum: gaiaAcc.accNumber,
                                                sequence:gaiaAcc.accSequence,
                                                fees: [TxFeeAmount(amount: node.feeAmount, denom: node.feeDenom)])
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
                switch node.type {
                case .iris, .iris_fuxi:
                    let irisApi = IrisRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
                    let req = IrisBaseReq(chainId: node.network, gas: "20000", fee: "\(node.feeAmount)\(node.feeDenom)", memo: node.defaultMemo)
                    let data = IrisWithdrawData(baseTx: req, validatorAddress: validator, isValidator: false)
                    irisApi.withdrawReward(to: key.address, transferData: data) { result in
                        switch result {
                        case .success(let data):
                            GaiaLocalClient(delegate: clientDelegate).handleSignAndBroadcast(restApi: restApi, data: data, gaiaAcc: gaiaAcc, node: node, completion: completion)
                        case .failure(let error):
                            print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                            DispatchQueue.main.async { completion?(nil, error.localizedDescription) }
                        }
                    }
                default:
                    let data = TransferPostData(name: key.address,
                                                memo: node.defaultMemo,
                                                chain: node.network,
                                                accNum: gaiaAcc.accNumber,
                                                sequence: gaiaAcc.accSequence,
                                                fees: [TxFeeAmount(amount: node.feeAmount, denom: node.feeDenom)])
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
                switch node.type {
                case .iris, .iris_fuxi:
                    let irisApi = IrisRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
                    let req = IrisBaseReq(chainId: node.network, gas: "20000", fee: "\(node.feeAmount)\(node.feeDenom)", memo: node.defaultMemo)
                    let data = IrisWithdrawData(baseTx: req, validatorAddress: nil, isValidator: true)
                    irisApi.withdrawReward(to: key.address, transferData: data) { result in
                        switch result {
                        case .success(let data):
                            GaiaLocalClient(delegate: clientDelegate).handleSignAndBroadcast(restApi: restApi, data: data, gaiaAcc: gaiaAcc, node: node, completion: completion)
                        case .failure(let error):
                            print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                            DispatchQueue.main.async { completion?(nil, error.localizedDescription) }
                        }
                    }
                    
                default:
                    let data = TransferPostData(name: key.address,
                                                memo: node.defaultMemo,
                                                chain: node.network,
                                                accNum: gaiaAcc.accNumber,
                                                sequence: gaiaAcc.accSequence,
                                                fees: [TxFeeAmount(amount: node.feeAmount, denom: node.feeDenom)])
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
                switch node.type {
                case .iris, .iris_fuxi:
                    let damount = Double(amount) ?? 0
                    let corrected = "\(damount / pow(10, node.decimals))"
                    let irisApi = IrisRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
                    let req = IrisBaseReq(chainId: node.network, gas: "25000", fee: "\(node.feeAmount)\(node.feeDenom)", memo: node.defaultMemo)
                    let data = IrisRedelegateData(baseTx: req, redelegate: IrisRedelegateContent(validatorSource: fromValidator, validatorDestination: toValidator, sharesAmount: corrected, sharesPercent: nil))
                    irisApi.redelegation(from: key.address, transferData: data) { result in
                        switch result {
                        case .success(let data):
                            GaiaLocalClient(delegate: clientDelegate).handleSignAndBroadcast(restApi: restApi, data: data, gaiaAcc: gaiaAcc, node: node, irisSpaghetti: true, irisRenameShares: true, completion: completion)
                        case .failure(let error):
                            print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                            DispatchQueue.main.async { completion?(nil, error.localizedDescription) }
                        }
                    }
                default:
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
                switch node.type {
                case .iris, .iris_fuxi:
                    let irisApi = IrisRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
                    let req = IrisBaseReq(chainId: node.network, gas: "20000", fee: "\(node.feeAmount)\(node.feeDenom)", memo: node.defaultMemo)
                    let data = IrisDelegateData(baseTx: req, delegate: IrisDelegateContent(delegation: amount + denom, validatorAddr: toValidator))
                    irisApi.delegation(from: key.address, transferData: data) { result in
 
                        switch result {
                        case .success(let data):
                            GaiaLocalClient(delegate: clientDelegate).handleSignAndBroadcast(restApi: restApi, data: data, gaiaAcc: gaiaAcc, node: node, completion: completion)
                        case .failure(let error):
                            print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                            DispatchQueue.main.async { completion?(nil, error.localizedDescription) }
                        }
                    }
                default:
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
                switch node.type {
                case .iris, .iris_fuxi:
                    let damount = Double(amount) ?? 0
                    let corrected = "\(damount / pow(10, node.decimals))"
                    let irisApi = IrisRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
                    let req = IrisBaseReq(chainId: node.network, gas: "20000", fee: "\(node.feeAmount)\(node.feeDenom)", memo: node.defaultMemo)
                    let data = IrisUnbondData(baseTx: req, unbond: IrisUnbondContent(sharesAmount: corrected, sharesPercent: nil, validatorAddr: fromValidator))
                    irisApi.unbonding(from: key.address, transferData: data) { result in
                        switch result {
                        case .success(let data):
                            GaiaLocalClient(delegate: clientDelegate).handleSignAndBroadcast(restApi: restApi, data: data, gaiaAcc: gaiaAcc, node: node, irisSpaghetti: true, completion: completion)
                        case .failure(let error):
                            print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                            DispatchQueue.main.async { completion?(nil, error.localizedDescription) }
                        }
                    }
                    
                default:
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
    func retrieveIrisValidators(node: TDMNode, page: Int, completion: @escaping (_ data: [GaiaValidator]?, _ errMsg: String?)->())
}

extension GaiaValidatorsCapable {
    
    public func retrieveAllValidators(node: TDMNode, status: String, completion: @escaping (_ data: [GaiaValidator]?, _ errMsg: String?)->()) {
        switch node.type {
        case .iris, .iris_fuxi:
            retrieveIrisValidators(node: node, completion: completion)
//        case .regen:
//            let restApi = CosmosRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
//             restApi.getStakeValidators { result in
//                switch result {
//                case .success(let data):
//                    var gaiaValidators: [GaiaValidator] = []
//                    for validator in data {
//                        gaiaValidators.append(GaiaValidator(validator: validator))
//                    }
//                    DispatchQueue.main.async { completion(gaiaValidators, nil) }
//                case .failure(let error):
//                    DispatchQueue.main.async { completion(nil, error.localizedDescription) }
//                }
//            }
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
    
    public func retrieveIrisValidators(node: TDMNode, page: Int = 1, completion: @escaping (_ data: [GaiaValidator]?, _ errMsg: String?)->()) {
        let restApi = IrisRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
        
        var gaiaValidators: [GaiaValidator] = []
        restApi.getStakeValidators(page: page) { result in
            switch result {
            case .success(let data):
                for validator in data {
                    gaiaValidators.append(GaiaValidator(validator: validator))
                }
                restApi.getStakeValidators(page: 2) { result in
                    switch result {
                    case .success(let data):
                        for validator in data {
                            gaiaValidators.append(GaiaValidator(validator: validator))
                        }
                        DispatchQueue.main.async { completion(gaiaValidators.filter { $0.jailed == false }, nil) }
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
        case .iris, .iris_fuxi:
            let irisApi = IrisRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
            irisApi.getPorposals { result in
                switch result {
                case .success(let data):
                    var gaiaPropsals: [GaiaProposal] = []
                    for proposal in data {
                        gaiaPropsals.append(GaiaProposal(proposal: proposal))
                    }
                    DispatchQueue.main.async { completion(gaiaPropsals, nil) }
                case .failure(let error):
                    DispatchQueue.main.async { completion(nil, error.localizedDescription) }
                }
            }
//        case .regen:
//            let restApi = CosmosRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
//            restApi.getPorposals { result in
//                switch result {
//                case .success(let data):
//                    var gaiaPropsals: [GaiaProposal] = []
//                    for proposal in data {
//                        gaiaPropsals.append(GaiaProposal(proposal: proposal))
//                    }
//                    DispatchQueue.main.async { completion(gaiaPropsals, nil) }
//                case .failure(let error):
//                    DispatchQueue.main.async { completion(nil, error.localizedDescription) }
//                }
//            }
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
        
        switch node.type {
        case .iris, .iris_fuxi:
            let restApi = CosmosRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
            restApi.getPorposalVotes(forId: proposal.proposalId) { result in
                switch result {
                case .success(let data):
                    proposal.votes = data
                    DispatchQueue.main.async { completion(proposal, nil) }
                case .failure(let error):
                    DispatchQueue.main.async { completion(nil, error.localizedDescription) }
                }
            }
//        case .regen:
//            let restApi = CosmosRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
//            restApi.getPorposalTally(forId: proposal.proposalId) { result in
//                switch result {
//                case .success(let data):
//                    if let tally = data.first {
//                        proposal.yes = tally.yes ?? "0"
//                        proposal.no = tally.no ?? "0"
//                        proposal.abstain = tally.abstain ?? "0"
//                        proposal.noWithVeto = tally.noWithVeto ?? "0"
//                    }
//                    restApi.getPorposalVotes(forId: proposal.proposalId) { result in
//                        switch result {
//                        case .success(let data):
//                            proposal.votes = data
//                            DispatchQueue.main.async { completion(proposal, nil) }
//                        case .failure(let error):
//                            DispatchQueue.main.async { completion(nil, error.localizedDescription) }
//                        }
//                    }
//                case .failure(let error):
//                    DispatchQueue.main.async { completion(nil, error.localizedDescription) }
//                }
//            }
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
                        GaiaLocalClient(delegate: clientDelegate).handleSignAndBroadcast(restApi: restApi, data: data, gaiaAcc: gaiaAcc, node: node, irisSpaghetti: true, completion: completion)
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
                case .iris, .iris_fuxi:
                    let irisApi = IrisRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
                    let req = IrisBaseReq(chainId: node.network, gas: "20000", fee: "\(node.feeAmount)\(node.feeDenom)", memo: node.defaultMemo)
                    let data = IrisProposeData(baseTx: req, title: title, description: description, proposer: key.address, proposalType: "PlainText", initialDeposit: deposit + node.stakeDenom)
                    irisApi.submitProposal(transferData: data) { result in
                        switch result {
                        case .success(let data):
                            GaiaLocalClient(delegate: clientDelegate).handleSignAndBroadcast(restApi: restApi, data: data, gaiaAcc: gaiaAcc, node: node, irisSpaghetti: true, completion: completion)
                        case .failure(let error):
                            print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                            DispatchQueue.main.async { completion?(nil, error.localizedDescription) }
                        }
                    }
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
                case .iris, .iris_fuxi:
                    let irisApi = IrisRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
                    let req = IrisBaseReq(chainId: node.network, gas: "20000", fee: "\(node.feeAmount)\(node.feeDenom)", memo: node.defaultMemo)
                    let data = IrisProposalDepositData(baseTx: req, depositor: key.address, amount: amount + node.stakeDenom)
                    irisApi.depositToProposal(id: proposalId, transferData: data) { result in
                        switch result {
                        case .success(let data):
                            GaiaLocalClient(delegate: clientDelegate).handleSignAndBroadcast(restApi: restApi, data: data, gaiaAcc: gaiaAcc, node: node, irisSpaghetti: true, completion: completion)
                        case .failure(let error):
                            print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                            DispatchQueue.main.async { completion?(nil, error.localizedDescription) }
                        }
                    }
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

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
    func retrieveAllKeys(node: GaiaNode, completion: @escaping (_ data: [GaiaKey]?, _ errMsg: String?)->())
    func createKey(node: GaiaNode, name: String, pass: String, seed: String?, completion: @escaping (_ data: GaiaKey?, _ errMsg: String?)->())
    func getAccount(node: GaiaNode, key: GaiaKey, completion: ((_ data: GaiaAccount?, _ errMsg: String?) -> ())?)
    func sendAssets(node: GaiaNode, key: GaiaKey, toAddress: String, amount: String, denom: String, completion: ((_ data: TransferResponse?, _ errMsg: String?) -> ())?)
}

extension GaiaKeysManagementCapable {
    
    public func getAccount(node: GaiaNode, key: GaiaKey, completion: ((_ data: GaiaAccount?, _ errMsg: String?) -> ())?) {
        let restApi = GaiaRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
        restApi.getAccount(address: key.address) { result in
            switch result {
            case .success(let data):
                if let item = data.first, let type = item.type {
                    if type.contains("VestingAccount") {
                        self.getVestedAccount(node: node, key: key, completion: completion)
                    } else {
                        let gaiaAcc = GaiaAccount(accountValue: item.value, stakeDenom: node.stakeDenom)
                        DispatchQueue.main.async {
                            completion?(gaiaAcc, nil)
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        completion?(nil, "Request OK but no data")
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    let message = error.code == 204 ? nil : error.localizedDescription
                    completion?(nil, message)
                }
            }
        }
    }
    
    private func getVestedAccount(node: GaiaNode, key: GaiaKey, completion: ((_ data: GaiaAccount?, _ errMsg: String?) -> ())?) {
        let restApi = GaiaRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
        restApi.getVestedAccount(address: key.address) { result in
            switch result {
            case .success(let data):
                if let item = data.first?.value?.baseVestingAccount?.baseAccount {
                    let gaiaAcc = GaiaAccount(accountValue: item, stakeDenom: node.stakeDenom)
                    DispatchQueue.main.async {
                        completion?(gaiaAcc, nil)
                    }
                } else {
                    DispatchQueue.main.async {
                        completion?(nil, "Request OK but no data")
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    let message = error.code == 204 ? nil : error.localizedDescription
                    completion?(nil, message)
                }
            }
        }
    }

    public func sendAssets(node: GaiaNode, key: GaiaKey, toAddress: String, amount: String, denom: String, completion: ((_ data: TransferResponse?, _ errMsg: String?) -> ())?) {
        let restApi = GaiaRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
        restApi.getAccount(address: key.address) { result in
            switch result {
            case .success(let data):
                if let item = data.first, let type = item.type {
                    if type.contains("VestingAccount") {
                        restApi.getVestedAccount(address: key.address) { result in
                            switch result {
                            case .success(let data):
                                if let item = data.first?.value?.baseVestingAccount?.baseAccount {
                                    let gaiaAcc = GaiaAccount(accountValue: item, stakeDenom: node.stakeDenom)
                                    let data = TransferPostData(name: key.name,
                                                                pass: key.getPassFromKeychain() ?? "",
                                                                chain: node.network,
                                                                amount: amount,
                                                                denom: denom,
                                                                accNum: gaiaAcc.accNumber,
                                                                sequence:gaiaAcc.accSequence)
                                    restApi.bankTransfer(to: toAddress, transferData: data) { result in
                                        print("\n... Transfer \(amount) \(denom) ...")
                                        switch result {
                                        case .success(let data):
                                            print(" -> [OK] - ", data.first?.hash ?? "")
                                            DispatchQueue.main.async { completion?(data.first, nil) }
                                        case .failure(let error):
                                            print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                                            completion?(nil, error.localizedDescription)
                                        }
                                    }
                                } else {
                                    DispatchQueue.main.async {
                                        completion?(nil, "Request OK but no data")
                                    }
                                }
                            case .failure(let error):
                                DispatchQueue.main.async {
                                    let message = error.code == 204 ? nil : error.localizedDescription
                                    completion?(nil, message)
                                }
                            }
                        }
                    } else {
                        let gaiaAcc = GaiaAccount(accountValue: item.value, stakeDenom: node.stakeDenom)
                        let data = TransferPostData(name: key.name,
                                                    pass: key.getPassFromKeychain() ?? "",
                                                    chain: node.network,
                                                    amount: amount,
                                                    denom: denom,
                                                    accNum: gaiaAcc.accNumber,
                                                    sequence:gaiaAcc.accSequence)
                        restApi.bankTransfer(to: toAddress, transferData: data) { result in
                            print("\n... Transfer \(amount) \(denom) ...")
                            switch result {
                            case .success(let data):
                                print(" -> [OK] - ", data.first?.hash ?? "")
                                DispatchQueue.main.async { completion?(data.first, nil) }
                            case .failure(let error):
                                print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                                completion?(nil, error.localizedDescription)
                            }
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        completion?(nil, "Request OK but no data")
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    completion?(nil, error.localizedDescription)
                }
            }
        }
    }
    
    public func redelegateStake(node: GaiaNode, key: GaiaKey, fromValidator: String, toValidator: String, amount: String, completion: ((_ data: TransferResponse?, _ errMsg: String?) -> ())?) {
        let restApi = GaiaRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
        restApi.getAccount(address: key.address) { result in
            switch result {
            case .success(let data):
                if let item = data.first, let type = item.type {
                    if type.contains("VestingAccount") {
                        restApi.getVestedAccount(address: key.address) { result in
                            switch result {
                            case .success(let data):
                                if let item = data.first?.value?.baseVestingAccount?.baseAccount {
                                    let gaiaAcc = GaiaAccount(accountValue: item, stakeDenom: node.stakeDenom)
                                    let data = RedelegationPostData(
                                        sourceValidator: fromValidator,
                                        destValidator: toValidator,
                                        delegator: key.address,
                                        name: key.name,
                                        pass: key.getPassFromKeychain() ?? "",
                                        chain: node.network,
                                        amount: amount,
                                        accNum: gaiaAcc.accNumber,
                                        sequence: gaiaAcc.accSequence)
                                    restApi.redelegation(from: key.address, transferData: data) { result in
                                        switch result {
                                        case .success(let rdata):
                                            print(" -> [OK] - ", rdata.first ?? "")
                                            DispatchQueue.main.async { completion?(rdata.first, nil) }
                                        case .failure(let error):
                                            print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                                            completion?(nil, error.localizedDescription)
                                        }
                                    }
                                } else {
                                    DispatchQueue.main.async {
                                        completion?(nil, "Request OK but no data")
                                    }
                                }
                            case .failure(let error):
                                DispatchQueue.main.async {
                                    let message = error.code == 204 ? nil : error.localizedDescription
                                    completion?(nil, message)
                                }
                            }
                        }
                    } else {
                        let gaiaAcc = GaiaAccount(accountValue: item.value, stakeDenom: node.stakeDenom)
                        let data = RedelegationPostData(
                            sourceValidator: fromValidator,
                            destValidator: toValidator,
                            delegator: key.address,
                            name: key.name,
                            pass: key.getPassFromKeychain() ?? "",
                            chain: node.network,
                            amount: amount,
                            accNum: gaiaAcc.accNumber,
                            sequence: gaiaAcc.accSequence)
                        restApi.redelegation(from: key.address, transferData: data) { result in
                            switch result {
                            case .success(let rdata):
                                print(" -> [OK] - ", rdata.first ?? "")
                                DispatchQueue.main.async { completion?(rdata.first, nil) }
                            case .failure(let error):
                                print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                                completion?(nil, error.localizedDescription)
                            }
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        completion?(nil, "Request OK but no data")
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    completion?(nil, error.localizedDescription)
                }
            }
        }
    }

    public func delegateStake(node: GaiaNode, key: GaiaKey, toValidator: String, amount: String, denom: String, completion: ((_ data: TransferResponse?, _ errMsg: String?) -> ())?) {
        let restApi = GaiaRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
        restApi.getAccount(address: key.address) { result in
            switch result {
            case .success(let data):
                if let item = data.first, let type = item.type {
                    if type.contains("VestingAccount") {
                        restApi.getVestedAccount(address: key.address) { result in
                            switch result {
                            case .success(let data):
                                if let item = data.first?.value?.baseVestingAccount?.baseAccount {
                                    let gaiaAcc = GaiaAccount(accountValue: item, stakeDenom: node.stakeDenom)
                                    let data = DelegationPostData(
                                        validator: toValidator,
                                        delegator: key.address,
                                        name: key.name,
                                        pass: key.getPassFromKeychain() ?? "",
                                        chain: node.network,
                                        amount: amount,
                                        denom: denom,
                                        accNum: gaiaAcc.accNumber,
                                        sequence: gaiaAcc.accSequence)
                                    restApi.delegation(from: key.address, transferData: data) { result in
                                        switch result {
                                        case .success(let data):
                                            print(" -> [OK] - ", data.first?.hash ?? "")
                                            DispatchQueue.main.async { completion?(data.first, nil) }
                                        case .failure(let error):
                                            print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                                            completion?(nil, error.localizedDescription)
                                        }
                                    }
                                } else {
                                    DispatchQueue.main.async {
                                        completion?(nil, "Request OK but no data")
                                    }
                                }
                            case .failure(let error):
                                DispatchQueue.main.async {
                                    let message = error.code == 204 ? nil : error.localizedDescription
                                    completion?(nil, message)
                                }
                            }
                        }
                    } else {
                        let gaiaAcc = GaiaAccount(accountValue: item.value, stakeDenom: node.stakeDenom)
                        let data = DelegationPostData(
                            validator: toValidator,
                            delegator: key.address,
                            name: key.name,
                            pass: key.getPassFromKeychain() ?? "",
                            chain: node.network,
                            amount: amount,
                            denom: denom,
                            accNum: gaiaAcc.accNumber,
                            sequence: gaiaAcc.accSequence)
                        restApi.delegation(from: key.address, transferData: data) { result in
                            switch result {
                            case .success(let data):
                                print(" -> [OK] - ", data.first?.hash ?? "")
                                DispatchQueue.main.async { completion?(data.first, nil) }
                            case .failure(let error):
                                print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                                completion?(nil, error.localizedDescription)
                            }
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        completion?(nil, "Request OK but no data")
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    completion?(nil, error.localizedDescription)
                }
            }
        }
    }

    public func unbondStake(node: GaiaNode, key: GaiaKey, fromValidator: String, amount: String, denom: String, completion: ((_ data: TransferResponse?, _ errMsg: String?) -> ())?) {
        let restApi = GaiaRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
        restApi.getAccount(address: key.address) { result in
            switch result {
            case .success(let data):
                if let item = data.first, let type = item.type {
                    if type.contains("VestingAccount") {
                        restApi.getVestedAccount(address: key.address) { result in
                            switch result {
                            case .success(let data):
                                if let item = data.first?.value?.baseVestingAccount?.baseAccount {
                                    let gaiaAcc = GaiaAccount(accountValue: item, stakeDenom: node.stakeDenom)
                                    let data = UnbondingDelegationPostData(
                                        validator: fromValidator,
                                        delegator: key.address,
                                        name: key.name,
                                        pass: key.getPassFromKeychain() ?? "",
                                        chain: node.network,
                                        amount: amount,
                                        accNum: gaiaAcc.accNumber,
                                        sequence: gaiaAcc.accSequence)
                                    restApi.unbonding(from: key.name, transferData: data) { result in
                                        switch result {
                                        case .success(let data):
                                            print(" -> [OK] - ", data.first?.hash ?? "")
                                            DispatchQueue.main.async { completion?(data.first, nil) }
                                        case .failure(let error):
                                            print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                                            completion?(nil, error.localizedDescription)
                                        }
                                    }
                                } else {
                                    DispatchQueue.main.async {
                                        completion?(nil, "Request OK but no data")
                                    }
                                }
                            case .failure(let error):
                                DispatchQueue.main.async {
                                    let message = error.code == 204 ? nil : error.localizedDescription
                                    completion?(nil, message)
                                }
                            }
                        }
                    } else {
                        let gaiaAcc = GaiaAccount(accountValue: item.value, stakeDenom: node.stakeDenom)
                        let data = UnbondingDelegationPostData(
                            validator: fromValidator,
                            delegator: key.address,
                            name: key.name,
                            pass: key.getPassFromKeychain() ?? "",
                            chain: node.network,
                            amount: amount,
                            accNum: gaiaAcc.accNumber,
                            sequence: gaiaAcc.accSequence)
                        restApi.unbonding(from: key.name, transferData: data) { result in
                            switch result {
                            case .success(let data):
                                print(" -> [OK] - ", data.first?.hash ?? "")
                                DispatchQueue.main.async { completion?(data.first, nil) }
                            case .failure(let error):
                                print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                                completion?(nil, error.localizedDescription)
                            }
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        completion?(nil, "Request OK but no data")
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    completion?(nil, error.localizedDescription)
                }
            }
        }
    }

    public func retrieveAllKeys(node: GaiaNode, completion: @escaping (_ data: [GaiaKey]?, _ errMsg: String?)->()) {
        let restApi = GaiaRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
        
        restApi.getKeys { result in
            switch result {
            case .success(let data):
                var gaiaKeys: [GaiaKey] = []
                for key in data {
                    gaiaKeys.append(GaiaKey(data: key, nodeId: node.nodeID))
                }
                DispatchQueue.main.async { completion(gaiaKeys, nil) }
            case .failure(let error): completion(nil, error.localizedDescription)
             }
        }
    }
    
    public func createKey(node: GaiaNode, name: String, pass: String, seed: String? = nil, completion: @escaping (_ data: GaiaKey?, _ errMsg: String?)->()) {
        let restApi = GaiaRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
        if let validSeed = seed {
            self.createGaiaKey(restApi: restApi, name: name, pass: pass, seed: validSeed) { rawkey, seed, errMessage in
                if let error = errMessage {
                    DispatchQueue.main.async { completion(nil, error) }
                } else if let validKey = rawkey {
                    let gaiaKey = GaiaKey(data: validKey, seed: validSeed, nodeId: node.nodeID)
                    gaiaKey.savePassToKeychain(pass: pass)
                    DispatchQueue.main.async { completion(gaiaKey, nil) }
                }
           }
        } else {
            createSeed(restApi: restApi, name: name, pass: pass) { rawkey, seed, errMessage in
                if let error = errMessage {
                    DispatchQueue.main.async {completion(nil, error) }
                } else if let validKey = rawkey {
                    let gaiaKey = GaiaKey(data: validKey, seed: seed, nodeId: node.nodeID)
                    gaiaKey.savePassToKeychain(pass: pass)
                    DispatchQueue.main.async { completion(gaiaKey, nil) }
                }
            }
        }
    }
    
    func createSeed(restApi: GaiaRestAPI, name: String, pass: String, completion: @escaping (_ data: Key?, _ seed: String?, _ errMsg: String?)->()) {
        restApi.createSeed { result in
            switch result {
            case .success(let data):
                if let seed = data.first {
                    self.createGaiaKey(restApi: restApi, name: name, pass: pass, seed: seed, completion: completion)
                } else {
                    DispatchQueue.main.async { completion(nil, nil, "Failed to generate a seed") }
                }
            case .failure(let error):
                DispatchQueue.main.async { completion(nil, nil, error.localizedDescription) }
            }
        }
    }
    
    func createGaiaKey(restApi: GaiaRestAPI, name: String, pass: String, seed: String, completion: @escaping (_ data: Key?, _ seed: String?, _ errMsg: String?)->()) {
        let kdata = KeyPostData(name: name, pass: pass, seed: seed)
        restApi.recoverKey(keyData: kdata, completion: { result in
            switch result {
            case .success(let data):
                if let item = data.first {
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
}

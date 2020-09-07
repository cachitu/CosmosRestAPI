//
//  GaiaRestModel.swift
//  CosmosRestApi
//
//  Created by Calin Chitu on 11/01/2019.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import Foundation

public class GaiaAddressBook: PersistCodable, CustomStringConvertible {
    
    public var items: [GaiaAddressBookItem]
    
    public init(items: [GaiaAddressBookItem]) {
        self.items = items
    }
    
    public var description: String {
        var result: String = "Items:\n"
        for item in items {
            result += " -> name: \(item.name), address: \(item.address)\n"
        }
        return result
    }
}

public class GaiaAddressBookItem: PersistCodable, Equatable {
    
    public static func == (lhs: GaiaAddressBookItem, rhs: GaiaAddressBookItem) -> Bool {
        return lhs.address == rhs.address && lhs.name == rhs.name
    }
    
    public var name: String
    public var address: String
    
    public init(name: String, address: String) {
        self.name = name
        self.address = address
    }
    
    public func validate(node: TDMNode?, completion: ((_ success: Bool) -> ())?) {
        guard let validNode = node else {
            completion?(false)
            return
        }
        switch validNode.type {
        case .iris, .iris_fuxi:
            let restApi = IrisRestAPI(scheme: validNode.scheme, host: validNode.host, port: validNode.rcpPort)
            restApi.getAccount(address: self.address) { result in
                switch result {
                case .success(_): DispatchQueue.main.async { completion?(true) }
                case .failure(_): DispatchQueue.main.async { completion?(false) }
                }
            }
//        case .regen:
//            let restApi = CosmosRestAPI(scheme: validNode.scheme, host: validNode.host, port: validNode.rcpPort)
//            restApi.getAccount(address: self.address) { result in
//                switch result {
//                case .success(_): DispatchQueue.main.async { completion?(true) }
//                case .failure(_): DispatchQueue.main.async { completion?(false) }
//                }
//            }
        default:
            let restApi = CosmosRestAPI(scheme: validNode.scheme, host: validNode.host, port: validNode.rcpPort)
            restApi.getAccountV2(address: self.address) { result in
                switch result {
                case .success(_): DispatchQueue.main.async { completion?(true) }
                case .failure(_): DispatchQueue.main.async { completion?(false) }
                }
            }
        }
    }
}


public class GaiaKey: CustomStringConvertible, Codable, Equatable {
    
    public static func == (lhs: GaiaKey, rhs: GaiaKey) -> Bool {
        lhs.identifier == rhs.identifier
    }
    
    
    public let name: String
    public let type: String
    public let networkName: String
    public let address: String
    public let pubAddress: String
    public let validator: String
    public let pubValidator: String
    public let nodeId: String
    public let watchMode: Bool
    
    public var identifier: String {
        return name + type + address + nodeId + "\(watchMode)"
    }
    
    public var password: String {
        return getPassFromKeychain() ?? ""
    }
    public var mnemonic: String {
        return getMnemonicFromKeychain() ?? ""
    }

    public init(name: String, address: String, valAddress: String?, nodeType: TDMNodeType, nodeId: String, networkName: String) {
        
        self.watchMode = true
        self.nodeId = nodeId
        self.name = name
        self.type = nodeType.rawValue
        self.address = address
        self.pubAddress = ""
        self.validator = valAddress ?? ""
        self.pubValidator = valAddress ?? ""
        self.networkName = networkName
    }

    public init(data: TDMKey, nodeId: String, networkName: String) {
        
        self.watchMode = false
        self.nodeId = nodeId
        self.name = data.name ?? "-"
        self.type = data.type?.rawValue ?? "-"
        self.address = data.address ?? "-"
        self.pubAddress = data.pubAddress ?? "-"
        self.validator = data.validator ?? "-"
        self.pubValidator = data.pubValidator ?? "-"
        self.networkName = networkName

        if let pass = data.password {
            savePassToKeychain(pass: pass)
        }
        if let validMnemonic = data.mnemonic {
            saveMnemonicToKeychain(mnemonic: validMnemonic)
        }
    }
    
    public func getHash(node: TDMNode, gaiaKey: GaiaKey, hash: String, completion: ((_ data: GaiaTransaction?, _ errMsg: String?) -> ())?) {
        switch node.type {
        case .iris, .iris_fuxi:
            let restApi = IrisRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
            restApi.getTransactionBy(hash: hash) { result in
                switch result {
                case .success(let transactionString):
                    let gaiaTransaction = GaiaTransaction(irisString: transactionString.first ?? "", keyAddress: gaiaKey.address, hash: hash)
                    DispatchQueue.main.async {
                        completion?(gaiaTransaction, nil)
                    }

                case .failure(let error): DispatchQueue.main.async { completion?(nil, error.localizedDescription) }
                }
            }
        default:
            let restApi = CosmosRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
            
            restApi.getTransactionBy(hash: hash) { [weak self] result in
                switch result {
                case .success(let transaction):
                    if let tx = transaction.first, let address = self?.address {
                        let gaiaTransaction = GaiaTransaction(tx, keyAddress: address)
                        DispatchQueue.main.async {
                            completion?(gaiaTransaction, nil)
                        }
                    } else {
                        DispatchQueue.main.async { completion?(nil, "Success, but not able to extract the data") }
                    }

                case .failure(let error): DispatchQueue.main.async { completion?(nil, error.localizedDescription) }
                }
            }
        }
    }

    public func getGaiaAccount(node: TDMNode, gaiaKey: GaiaKey, completion: ((_ data: GaiaAccount?, _ errMsg: String?) -> ())?) {
        switch node.type {
        case .iris, .iris_fuxi:
            getIrisAccount(node: node, gaiaKey: gaiaKey, completion: completion)
//        case .regen:
//            let restApi = CosmosRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
//            restApi.getAccount(address: self.address) { [weak self] result in
//                switch result {
//                case .success(let data):
//                    if let item = data.first, let type = item.type {
//                        if type.contains("VestingAccount") {
//                            self?.getVestedAccount(node: node, gaiaKey: gaiaKey, completion: completion)
//                        } else {
//                            let gaiaAcc = GaiaAccount(accountValue: item.value, gaiaKey: gaiaKey, stakeDenom: node.stakeDenom)
//                            DispatchQueue.main.async {
//                                completion?(gaiaAcc, nil)
//                            }
//                        }
//                    } else {
//                        DispatchQueue.main.async {
//                            completion?(nil, nil)
//                        }
//                    }
//                case .failure(let error):
//                    DispatchQueue.main.async {
//                        //let message = error.code == 204 ? nil : error.localizedDescription
//                        completion?(nil, error.localizedDescription)
//                    }
//                }
//            }
        case .certik:
            let restApi = CosmosRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
            restApi.getAccountV5(address: self.address) { [weak self] result in
                switch result {
                case .success(let data):
                    if let item = data.first, let type = item.result?.type {
                        if type.contains("VestingAccount") {
                            self?.getVestedAccount(node: node, gaiaKey: gaiaKey, completion: completion)
                        } else {
                            let gaiaAcc = GaiaAccount(accountValue: item.result?.value, gaiaKey: gaiaKey, stakeDenom: node.stakeDenom)
                            DispatchQueue.main.async {
                                completion?(gaiaAcc, nil)
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            completion?(nil, nil)
                        }
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        //let message = error.code == 204 ? nil : error.localizedDescription
                        completion?(nil, error.localizedDescription)
                    }
                }
            }

        case .microtick, .stargate:
                let restApi = CosmosRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
                restApi.getAccountV4(address: self.address) { [weak self] result in
                    switch result {
                    case .success(let data):
                        if let item = data.first, let type = item.result?.type {
                            if type.contains("VestingAccount") {
                                self?.getVestedAccount(node: node, gaiaKey: gaiaKey, completion: completion)
                            } else {
                                restApi.getBalanceV2(address: self?.address ?? "") { result in
                                    switch result {
                                    case .success(let data):
                                        let gaiaAcc = GaiaAccount(accountValue: item.result?.value, gaiaKey: gaiaKey, stakeDenom: node.stakeDenom)
                                        gaiaAcc.assets = data.first?.result ?? []
                                        DispatchQueue.main.async {
                                            completion?(gaiaAcc, nil)
                                        }

                                    case .failure(let error):
                                        print(error)
                                    }
                                }
                            }
                        } else {
                            DispatchQueue.main.async {
                                completion?(nil, nil)
                            }
                        }
                    case .failure(let error):
                        DispatchQueue.main.async {
                            //let message = error.code == 204 ? nil : error.localizedDescription
                            completion?(nil, error.localizedDescription)
                        }
                    }
                }

        case .regen, .kava, .kava_118:
            let restApi = CosmosRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
            restApi.getAccountV3(address: self.address) { [weak self] result in
                switch result {
                case .success(let data):
                    if let item = data.first, let type = item.result?.type {
                        if type.contains("VestingAccount") {
                            self?.getVestedAccount(node: node, gaiaKey: gaiaKey, completion: completion)
                        } else {
                            let gaiaAcc = GaiaAccount(accountValue: item.result?.value, gaiaKey: gaiaKey, stakeDenom: node.stakeDenom)
                            DispatchQueue.main.async {
                                completion?(gaiaAcc, nil)
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            completion?(nil, nil)
                        }
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        //let message = error.code == 204 ? nil : error.localizedDescription
                        completion?(nil, error.localizedDescription)
                    }
                }
            }

        default:
            let restApi = CosmosRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
            restApi.getAccountV2(address: self.address) { [weak self] result in
                switch result {
                case .success(let data):
                    if let item = data.first, let type = item.result?.type {
                        if type.contains("VestingAccount") {
                            self?.getVestedAccount(node: node, gaiaKey: gaiaKey, completion: completion)
                        } else {
                            let gaiaAcc = GaiaAccount(accountValue: item.result?.value, gaiaKey: gaiaKey, stakeDenom: node.stakeDenom)
                            DispatchQueue.main.async {
                                completion?(gaiaAcc, nil)
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            completion?(nil, nil)
                        }
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        //let message = error.code == 204 ? nil : error.localizedDescription
                        completion?(nil, error.localizedDescription)
                    }
                }
            }
        }
    }
    
    public func getIrisAccount(node: TDMNode, gaiaKey: GaiaKey, completion: ((_ data: GaiaAccount?, _ errMsg: String?) -> ())?) {
        let restApi = IrisRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
        restApi.getAccount(address: self.address) { result in
            switch result {
            case .success(let data):
                if let item = data.first {
                    let gaiaAcc = GaiaAccount(irisAccount: item, gaiaKey: gaiaKey, stakeDenom: "iris-atto")
                    DispatchQueue.main.async {
                        completion?(gaiaAcc, nil)
                    }
                } else {
                    DispatchQueue.main.async {
                        completion?(nil, nil)
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    //let message = error.code == 204 ? "Account not found" : error.localizedDescription
                    completion?(nil, error.localizedDescription)
                }
            }
        }
    }

    private func getVestedAccount(node: TDMNode, gaiaKey: GaiaKey, completion: ((_ data: GaiaAccount?, _ errMsg: String?) -> ())?) {
        switch node.type {
//        case .regen:
//            let restApi = CosmosRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
//            restApi.getVestedAccount(address: self.address) { result in
//                switch result {
//                case .success(let data):
//                    if let item = data.first?.value?.baseVestingAccount?.baseAccount {
//                        let gaiaAcc = GaiaAccount(accountValue: item, gaiaKey: gaiaKey, stakeDenom: node.stakeDenom)
//                        DispatchQueue.main.async {
//                            completion?(gaiaAcc, nil)
//                        }
//                    } else {
//                        DispatchQueue.main.async {
//                            completion?(nil, nil)
//                        }
//                    }
//                case .failure(let error):
//                    DispatchQueue.main.async {
//                        //let message = error.code == 204 ? nil : error.localizedDescription
//                        completion?(nil, error.localizedDescription)
//                    }
//                }
//            }
        default:
            let restApi = CosmosRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
            restApi.getVestedAccountV2(address: self.address) { result in
                switch result {
                case .success(let data):
                    if let item = data.first?.result?.value?.baseVestingAccount?.baseAccount {
                        let gaiaAcc = GaiaAccount(accountValue: item, gaiaKey: gaiaKey, stakeDenom: node.stakeDenom)
                        DispatchQueue.main.async {
                            completion?(gaiaAcc, nil)
                        }
                    } else {
                        DispatchQueue.main.async {
                            completion?(nil, nil)
                        }
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        //let message = error.code == 204 ? nil : error.localizedDescription
                        completion?(nil, error.localizedDescription)
                    }
                }
            }
        }
    }
    
    public func getSentTransactions(node: TDMNode, page: Int, limit: Int, completion: @escaping ((_ transactions: [GaiaTransaction]?, _ totalItems: String?, _ message: String?) -> ())) {
        let restApi = CosmosRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
        restApi.getSentTransactions(by: self.address, page: "\(page)", limit: "\(limit)") { result in
            switch result {
            case .success(let transactions):
                var gaiaTransactions: [GaiaTransaction] = []
                for transaction in transactions.first?.txs ?? [] {
                    let gaiaTransaction = GaiaTransaction(transaction, keyAddress: self.address)
                    gaiaTransactions.append(gaiaTransaction)
                }
                DispatchQueue.main.async {
                    completion(gaiaTransactions, transactions.first?.totalCount, nil)
                }
            case .failure(let error): DispatchQueue.main.async { completion(nil, nil, error.localizedDescription) }
            }
        }
    }

    public func getReceivedTransactions(node: TDMNode, page: Int, limit: Int, completion: @escaping ((_ transactions: [GaiaTransaction]?, _ totalItems: String?, _ message: String?) -> ())) {
        let restApi = CosmosRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
        restApi.getReceivedTransactions(by: self.address, page: "\(page)", limit: "\(limit)") { result in
            switch result {
            case .success(let transactions):
                var gaiaTransactions: [GaiaTransaction] = []
                for transaction in transactions.first?.txs ?? [] {
                    let gaiaTransaction = GaiaTransaction(transaction, keyAddress: self.address)
                    gaiaTransactions.append(gaiaTransaction)
                }
                DispatchQueue.main.async {
                    completion(gaiaTransactions, transactions.first?.totalCount, nil)
                }
            case .failure(let error): DispatchQueue.main.async { completion(nil, nil, error.localizedDescription) }
            }
        }
    }

    public func getUnbondingDelegations(node: TDMNode, completion: @escaping ((_ delegations: [UnbondingDelegationV2]?, _ message: String?) -> ())) {
        switch node.type {
        case .stargate:
            break
        default:
            let restApi = CosmosRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
            restApi.getUnbondingDelegations(for: self.address) { result in
                switch result {
                case .success(let data): DispatchQueue.main.async { completion(data.first?.result, nil) }
                case .failure(let error): DispatchQueue.main.async { completion(nil, error.localizedDescription) }
                }
            }
        }
    }
    
    public func getDelegations(node: TDMNode, completion: @escaping ((_ delegations: [GaiaDelegation]?, _ message: String?) -> ())) {
        switch node.type {
        case .iris, .iris_fuxi:
            getIrisDelegations(node: node, completion: completion)
//        case .regen:
//            let restApi = CosmosRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
//            restApi.getDelegations(for: self.address) { result in
//                switch result {
//                case .success(let delegations):
//                    var gaiaDelegations: [GaiaDelegation] = []
//                    for delegation in delegations {
//                        let gaiaDelegation = GaiaDelegation(delegation: delegation)
//                        gaiaDelegations.append(gaiaDelegation)
//                    }
//                    DispatchQueue.main.async { completion(gaiaDelegations, nil) }
//                case .failure(let error): DispatchQueue.main.async { completion(nil, error.localizedDescription) }
//                }
//            }
        case .stargate:
            let restApi = CosmosRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
            restApi.getDelegationsStargate(for: self.address) { result in
                switch result {
                case .success(let delegations):
                    let results: [DelegationStargate] = delegations.first?.result ?? []
                    var gaiaDelegations: [GaiaDelegation] = []
                    for delegation in results {
                        let gaiaDelegation = GaiaDelegation(delegation: delegation.delegation!)
                        gaiaDelegations.append(gaiaDelegation)
                    }
                    DispatchQueue.main.async { completion(gaiaDelegations, nil) }
                case .failure(let error): DispatchQueue.main.async { completion(nil, error.localizedDescription) }
                }
            }
        default:
            let restApi = CosmosRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
            restApi.getDelegationsV2(for: self.address) { result in
                switch result {
                case .success(let delegations):
                    var gaiaDelegations: [GaiaDelegation] = []
                    for delegation in delegations.first?.result ?? [] {
                        let gaiaDelegation = GaiaDelegation(delegation: delegation)
                        gaiaDelegations.append(gaiaDelegation)
                    }
                    DispatchQueue.main.async { completion(gaiaDelegations, nil) }
                case .failure(let error): DispatchQueue.main.async { completion(nil, error.localizedDescription) }
                }
            }
        }
    }

    public func getIrisDelegations(node: TDMNode, completion: @escaping ((_ delegations: [GaiaDelegation]?, _ message: String?) -> ())) {
        let restApi = IrisRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
        restApi.getDelegations(for: self.address) { result in
            switch result {
            case .success(let delegations):
                var gaiaDelegations: [GaiaDelegation] = []
                for delegation in delegations {
                    let gaiaDelegation = GaiaDelegation(delegation: delegation)
                    gaiaDelegations.append(gaiaDelegation)
                }
                DispatchQueue.main.async { completion(gaiaDelegations, nil) }
            case .failure(let error): DispatchQueue.main.async { completion(nil, error.localizedDescription) }
            }
        }
    }

    public func queryValidatorRewards(node: TDMNode, validator: String, completion: @escaping ((_ delegations: Int?, _ message: String?) -> ())) {

        switch node.type {
        case .iris, .iris_fuxi:
            let restApi = IrisRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
            restApi.getRewards(from: self.address) { result in
                switch result {
                case .success(let rewards):
                    var amount = rewards.first?.total?.first?.amount
                    if amount?.count ?? 0 > 18 {
                        amount = String(amount?.dropLast(18) ?? "0")
                    }
                    let value = Int(amount ?? "0") ?? 0
                    DispatchQueue.main.async { completion(value, nil) }
                case .failure(let error):
                    DispatchQueue.main.async { completion(nil, error.localizedDescription) }
                }
            }
//        case .regen:
//            let restApi = CosmosRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
//            restApi.getValidatorRewards(from: validator) { result in
//                switch result {
//                case .success(let rewards):
//                    let amount = rewards.first?.valCommission?.first?.amount?.split(separator: ".").first
//                    let val = Int(amount ?? "0") ?? 0
//                    DispatchQueue.main.async { completion(val, nil) }
//                case .failure(let error):
//                    DispatchQueue.main.async { completion(nil, error.localizedDescription) }
//                }
//            }
        case .stargate:
            let restApi = CosmosRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
            restApi.getValidatorRewardsStargate(from: validator) { result in
                switch result {
                case .success(let rewards):
                    let amount = rewards.first?.result?.valCommission?.commission?.first?.amount?.split(separator: ".").first
                    let val = Int(amount ?? "0") ?? 0
                    DispatchQueue.main.async { completion(val, nil) }
                case .failure(let error):
                    DispatchQueue.main.async { completion(nil, error.localizedDescription) }
                }
            }
        default:
            let restApi = CosmosRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
            restApi.getValidatorRewardsV2(from: validator) { result in
                switch result {
                case .success(let rewards):
                    let amount = rewards.first?.result?.valCommission?.first?.amount?.split(separator: ".").first
                    let val = Int(amount ?? "0") ?? 0
                    DispatchQueue.main.async { completion(val, nil) }
                case .failure(let error):
                    DispatchQueue.main.async { completion(nil, error.localizedDescription) }
                }
            }
        }
    }
    
    public func queryDelegationRewards(node: TDMNode, validatorAddr: String, completion: @escaping ((_ delegations: Int?, _ message: String?) -> ())) {
        switch node.type {
        case .iris, .iris_fuxi:
            DispatchQueue.main.async { completion(0, nil) }
//        case .regen:
//            let restApi = CosmosRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
//            restApi.getDelegatorReward(for: self.address, fromValidator: validatorAddr) { result in
//                switch result {
//                case .success(let rewards):
//                    let amount = rewards.first?.amount?.split(separator: ".").first
//                    let val = Int(amount ?? "0") ?? 0
//                    DispatchQueue.main.async { completion(val, nil) }
//                case .failure(let error):
//                    DispatchQueue.main.async { completion(nil, error.localizedDescription) }
//                }
//            }
        default:
            let restApi = CosmosRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
            restApi.getDelegatorRewardV2(for: self.address, fromValidator: validatorAddr) { result in
                switch result {
                case .success(let rewards):
                    let amount = rewards.first?.result?.first?.amount?.split(separator: ".").first
                    let val = Int(amount ?? "0") ?? 0
                    DispatchQueue.main.async { completion(val, nil) }
                case .failure(let error):
                    DispatchQueue.main.async { completion(nil, error.localizedDescription) }
                }
            }
        }
    }
    
    private var uniqueID: String {
        return "\(address)-\(name)-\(nodeId)"
    }

    public func savePassToKeychain(pass: String) {
        KeychainWrapper.setString(value: pass, forKey: "GaiaKey-password-\(uniqueID)")
    }
    
    public func getPassFromKeychain() -> String? {
        return KeychainWrapper.stringForKey(keyName: "GaiaKey-password-\(uniqueID)")
    }

    public func forgetPassFromKeychain() -> Bool {
        return KeychainWrapper.removeObjectForKey(keyName: "GaiaKey-password-\(uniqueID)")
    }

    public func saveMnemonicToKeychain(mnemonic: String) {
        KeychainWrapper.setString(value: mnemonic, forKey: "GaiaKey-mnemonic-\(uniqueID)")
    }
    
    public func getMnemonicFromKeychain() -> String? {
        return KeychainWrapper.stringForKey(keyName: "GaiaKey-mnemonic-\(uniqueID)")
    }
    
    public func forgetMnemonicFromKeychain() -> Bool {
        return KeychainWrapper.removeObjectForKey(keyName: "GaiaKey-mnemonic-\(uniqueID)")
    }

    public var description: String {
        return "[\(name), \(address), \(pubAddress)\n]"
    }
    
}

public class GaiaTransaction: Codable, /*Equatable,*/ Hashable {
    
    public static func == (lhs: GaiaTransaction, rhs: GaiaTransaction) -> Bool {
        return lhs.hash == rhs.hash
    }
    
//    public var hashValue: Int {
//        return hash.hashValue ^ time.hashValue &* 16777619
//    }
    
    public func hash(into hasher: inout Hasher) {
        return hasher.combine(hash.hashValue)
    }
    
    public let type: String
    public let gas: String
    public let height: Int
    public let hash: String
    public let time: String
    public let rawLog: String
    
    public let sender: String
    public let recipient: String
    public let amount: String
    public let isSender: Bool
    
    public init(irisString: String, keyAddress: String, hash: String) {
        self.type = "iris"
        self.gas  = ""
        self.height = 0
        self.hash = hash
        self.time = ""
        self.rawLog = irisString
        self.sender = ""
        self.recipient = ""
        self.amount = ""
        self.isSender = true
    }

    public init(_ transaction: TransactionHistoryData, keyAddress: String) {
        self.type = transaction.tx?.value?.msg?.first?.type ?? ""
        self.gas  = transaction.gasUsed ?? ""
        self.height = Int(transaction.height ?? "0") ?? 0
        self.hash = transaction.hash ?? ""
        self.time = transaction.timestamp ?? ""
        self.rawLog = transaction.log ?? transaction.hash ?? "-"
        let messages = transaction.events?.filter() { $0.type == "message" }
        let transfers = transaction.events?.filter() { $0.type == "transfer" }
        if let message = messages?.first {
            let sender = message.attributes?.filter() { $0.key == "sender" }
            self.sender = sender?.first?.value ?? ""
        } else {
            self.sender = ""
        }
        if let transfer = transfers?.first {
            let recipient = transfer.attributes?.filter() { $0.key == "recipient" }
            self.recipient = recipient?.first?.value ?? ""
            let amount = transfer.attributes?.filter() { $0.key == "amount" }
            self.amount = amount?.first?.value ?? ""
        } else {
            self.recipient = ""
            self.amount = ""
        }
        self.isSender = keyAddress == self.sender
    }

}

public class GaiaDelegation {
    
    public let validatorAddr: String
    public let delegatorAddr: String
    public let shares: String
    public let height: Int
    public var availableReward = ""
    
    public func availableRewardNormalised(decimals: Int, displayDecimnals: Int) -> String {
        if availableReward == "" { return "..." }
        var delta = decimals - availableReward.count
        while delta >= 0 {
            availableReward.insert("0", at: availableReward.startIndex)
            delta -= 1
        }
        
        let tail = String(availableReward[availableReward.index(availableReward.startIndex, offsetBy: availableReward.count - decimals)..<availableReward.endIndex])
        let head = String(availableReward[availableReward.startIndex..<availableReward.index(availableReward.startIndex, offsetBy: availableReward.count - decimals)])
        
        return head + "." + tail[tail.startIndex..<tail.index(availableReward.startIndex, offsetBy: displayDecimnals)]
    }

    public init(delegation: Delegation) {
        self.validatorAddr = delegation.validatorAddr ?? "-"
        self.delegatorAddr = delegation.delegatorAddr ?? "-"
        self.height = delegation.height ?? 0
        self.shares = delegation.shares ?? "0"
    }
    
    public init(delegation: IrisDelegation) {
        self.validatorAddr = delegation.validatorAddr ?? "-"
        self.delegatorAddr = delegation.delegatorAddr ?? "-"
        self.height = Int(delegation.height ?? "0") ?? 0
        self.shares = delegation.shares ?? "0"
    }
}

public class GaiaAccount/*: CustomStringConvertible*/ {
    
    public let address: String
    public let pubKey: String
    public var amount: Double
    public var denom: String
    public var assets: [Coin]
    public let accNumber: String
    public let accSequence: String
    public let gaiaKey: GaiaKey
    public let noFeeToken: Bool
    public var isValidator: Bool = false
    public var isEmpty: Bool = false

    init(accountValue: AccountValue?, gaiaKey: GaiaKey, seed: String? = nil, stakeDenom: String) {
        self.accNumber = accountValue?.accountNumber ?? "0"
        self.accSequence = accountValue?.sequence ?? "0"
        self.address = accountValue?.address ?? "="
        self.pubKey = accountValue?.publicKey?.value ?? "-"
        self.amount = 0.0
        self.denom = stakeDenom
        self.gaiaKey = gaiaKey
        self.assets = []
        
        for coin in accountValue?.coins ?? [] {
            if coin.denom == stakeDenom {
                assets.insert(coin, at: 0)
                self.amount = Double(coin.amount ?? "0.0") ?? 0.0
                self.denom = coin.denom ?? stakeDenom
            } else {
                assets.insert(coin, at: assets.count)
            }
        }
        
        self.noFeeToken = true
    }
    
    init(accountValue: AccountValueV4?, gaiaKey: GaiaKey, seed: String? = nil, stakeDenom: String) {
        self.accNumber = accountValue?.accountNumber ?? "0"
        self.accSequence = accountValue?.sequence ?? "0"
        self.address = accountValue?.address ?? "="
        self.pubKey = accountValue?.publicKey ?? "-"
        self.amount = 0.0
        self.denom = stakeDenom
        self.gaiaKey = gaiaKey
        self.assets = []
        
        for coin in accountValue?.coins ?? [] {
            if coin.denom == stakeDenom {
                assets.insert(coin, at: 0)
                self.amount = Double(coin.amount ?? "0.0") ?? 0.0
                self.denom = coin.denom ?? stakeDenom
            } else {
                assets.insert(coin, at: assets.count)
            }
        }
        
        self.noFeeToken = true
    }

    init(accountValue: AccountValueV5?, gaiaKey: GaiaKey, seed: String? = nil, stakeDenom: String) {
        self.accNumber = accountValue?.accountNumber ?? "0"
        self.accSequence = accountValue?.sequence ?? "0"
        self.address = accountValue?.address ?? "="
        self.pubKey = accountValue?.publicKey?.value ?? "-"
        self.amount = 0.0
        self.denom = stakeDenom
        self.gaiaKey = gaiaKey
        self.assets = []
        
        for coin in accountValue?.coins ?? [] {
            if coin.denom == stakeDenom {
                assets.insert(coin, at: 0)
                self.amount = Double(coin.amount ?? "0.0") ?? 0.0
                self.denom = coin.denom ?? stakeDenom
            } else {
                assets.insert(coin, at: assets.count)
            }
        }
        
        self.noFeeToken = true
    }

    init(accountValue: AccountValueV3?, gaiaKey: GaiaKey, seed: String? = nil, stakeDenom: String) {
        self.accNumber = "\(accountValue?.accountNumber ?? 0)"
        self.accSequence = "\(accountValue?.sequence ?? 0)"
        self.address = accountValue?.address ?? "="
        self.pubKey = accountValue?.publicKey ?? "-"
        self.amount = 0.0
        self.denom = stakeDenom
        self.gaiaKey = gaiaKey
        self.assets = []
        
        for coin in accountValue?.coins ?? [] {
            if coin.denom == stakeDenom {
                assets.insert(coin, at: 0)
                self.amount = Double(coin.amount ?? "0.0") ?? 0.0
                self.denom = coin.denom ?? stakeDenom
            } else {
                assets.insert(coin, at: assets.count)
            }
        }
        
        self.noFeeToken = true
    }

    init(irisAccount: IrisAccount, gaiaKey: GaiaKey, seed: String? = nil, stakeDenom: String) {
        self.accNumber = irisAccount.value?.accountNumber ?? "0"
        self.accSequence = irisAccount.value?.sequence ?? "0"
        self.address = irisAccount.value?.address ?? "="
        self.pubKey = irisAccount.value?.publicKey?.value ?? "-"
        let amountString = irisAccount.value?.coins?.first?.amount ?? "0"
        self.amount = Double(amountString) ?? 0.0
        self.denom = irisAccount.value?.coins?.first?.denom ?? stakeDenom
        
        self.assets = []
        for coin in irisAccount.value?.coins ?? [] {
            if coin.denom == stakeDenom {
                self.assets.insert(coin, at: 0)
                self.amount = Double(coin.amount ?? "0.0") ?? 0.0
                self.denom = coin.denom ?? stakeDenom
            } else {
                self.assets.insert(coin, at: assets.count)
            }
        }

        self.gaiaKey = gaiaKey
        self.noFeeToken = true
    }
    
}

public class GaiaValidator {
    
    public let validator: String
    public let tokens: String
    public let shares: String
    public let moniker: String
    public let rate: String
    public let jailed: Bool
    public let votingPower: Double
    
    public init(validator: DelegatorValidator) {
        self.validator = validator.operatorAddress ?? "-"
        self.tokens = validator.tokens ?? "0"
        self.shares = validator.delegatorShares ?? "0"
        self.moniker = validator.description?.moniker ?? "-"
        self.rate = validator.commission?.rate ?? "0"
        self.jailed = validator.jailed ?? false
        self.votingPower = Double(self.tokens) ?? 0.0
    }
    
    public init(validator: DelegatorValidatorV2) {
        self.validator = validator.operatorAddress ?? "-"
        self.tokens = validator.tokens ?? "0"
        self.shares = validator.delegatorShares ?? "0"
        self.moniker = validator.description?.moniker ?? "-"
        self.rate = validator.commission?.commissionRates?.rate ?? "0"
        self.jailed = validator.jailed ?? false
        self.votingPower = Double(self.tokens) ?? 0.0
    }

    public func getValidatorDelegations(node: TDMNode, completion: @escaping ((_ delegations: [GaiaDelegation]?, _ message: String?) -> ())) {
        
        switch node.type {
        case .iris, .iris_fuxi:
            let irisApi = IrisRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
            irisApi.getStakeValidatorDelegations(for: self.validator) { result in
                switch result {
                case .success(let delegations):
                    var gaiaDelegations: [GaiaDelegation] = []
                    for delegation in delegations {
                        let gaiaDelegation = GaiaDelegation(delegation: delegation)
                        gaiaDelegations.append(gaiaDelegation)
                    }
                    DispatchQueue.main.async { completion(gaiaDelegations, nil) }
                case .failure(let error): DispatchQueue.main.async { completion(nil, error.localizedDescription) }
                }
            }
        default:
            let restApi = CosmosRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
            restApi.getStakeValidatorDelegationsV2(for: self.validator) { result in
                switch result {
                case .success(let delegations):
                    var gaiaDelegations: [GaiaDelegation] = []
                    for delegation in delegations.first?.result ?? [] {
                        let gaiaDelegation = GaiaDelegation(delegation: delegation)
                        gaiaDelegations.append(gaiaDelegation)
                    }
                    DispatchQueue.main.async { completion(gaiaDelegations, nil) }
                case .failure(let error): DispatchQueue.main.async { completion(nil, error.localizedDescription) }
                }
            }
            
        }
    }
    
    public func unjail(node: TDMNode, clientDelegate: KeysClientDelegate, key: GaiaKey, completion: ((_ data: TransferResponse?, _ errMsg: String?) -> ())?) {
        let restApi = CosmosRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
        key.getGaiaAccount(node: node, gaiaKey: key) { (gaiaAccount, errMsg) in
            if let gaiaAcc = gaiaAccount  {
                switch node.type {
                case .iris, .iris_fuxi:
                    let irisApi = IrisRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
                    let req = IrisBaseReq(chainId: node.network, gas: "20000", fee: "\(node.feeAmount)\(node.feeDenom)", memo: node.defaultMemo)
                    let data = IrisUnjailData(baseTx: req)
                    irisApi.unjail(validator: key.validator, transferData: data) { result in
                        
                        switch result {
                        case .success(let data):
                            GaiaLocalClient(delegate: clientDelegate).handleSignAndBroadcast(restApi: restApi, data: data, gaiaAcc: gaiaAcc, node: node, completion: completion)
                        case .failure(let error):
                            completion?(nil, error.localizedDescription)
                        }
                    }
                default:
                    let baseReq = UnjailPostData(name: key.address,
                                                 memo: node.defaultMemo,
                                                 chain: node.network,
                                                 accNum: gaiaAcc.accNumber,
                                                 sequence: gaiaAcc.accSequence,
                                                 fees: [TxFeeAmount(amount: node.feeAmount, denom: node.feeDenom)])
                    restApi.unjail(validator: self.validator, transferData: baseReq) { result in
                        switch result {
                        case .success(let data):
                            GaiaLocalClient(delegate: clientDelegate).handleSignAndBroadcast(restApi: restApi, data: data, gaiaAcc: gaiaAcc, node: node, completion: completion)
                        case .failure(let error):
                            completion?(nil, error.localizedDescription)
                        }
                    }
                }

            } else {
                DispatchQueue.main.async { completion?(nil, errMsg) }
            }
        }
    }
}

public class GaiaProposal {
    
    public let title: String
    public let description: String
    public let type: String
    public let status: String
    public var yes: String
    public var abstain: String
    public var no: String
    public var noWithVeto: String
    public let proposalId: String
    public let totalDepopsit: String
    public var votes: [ProposalVote] = []
    public var submitTime: String
    
    public init(proposal: Proposal) {
        self.title       = proposal.content?.value?.title ?? proposal.contentv1?.value?.title ?? "-"
        self.description = proposal.content?.value?.description ?? proposal.contentv1?.value?.description ?? "-"
        self.type        = proposal.content?.proposalType ?? ""
        self.status      = proposal.proposalStatus ?? ""
        self.yes         = proposal.tallyResult?.yes ?? "0"
        self.abstain     = proposal.tallyResult?.abstain ?? "0"
        self.no          = proposal.tallyResult?.no ?? "0"
        self.noWithVeto  = proposal.tallyResult?.noWithVeto ?? "0"
        self.proposalId  = proposal.proposalId ?? proposal.proposalIdv1 ?? "0"
        let depAmount = proposal.totalDeposit?.first?.amount ?? "0"
        let depDenom = proposal.totalDeposit?.first?.denom ?? "-"
        self.totalDepopsit = "\(depAmount) \(depDenom)"
        self.submitTime = proposal.submitTime ?? ""
    }
    
    public init(proposal: ProposalV2) {
        self.title       = proposal.content?.value?.title ?? "-"
        self.description = proposal.content?.value?.description ?? "-"
        self.type        = proposal.content?.proposalType ?? ""
        self.status      = proposal.proposalStatus ?? ""
        self.yes         = proposal.tallyResult?.yes ?? "0"
        self.abstain     = proposal.tallyResult?.abstain ?? "0"
        self.no          = proposal.tallyResult?.no ?? "0"
        self.noWithVeto  = proposal.tallyResult?.noWithVeto ?? "0"
        self.proposalId  = proposal.proposalId ?? "0"
        let depAmount = proposal.totalDeposit?.first?.amount ?? "0"
        let depDenom = proposal.totalDeposit?.first?.denom ?? "-"
        self.totalDepopsit = "\(depAmount) \(depDenom)"
        self.submitTime = proposal.submitTime ?? ""
    }

    public init(proposal: ProposalV3) {
        self.title       = proposal.content?.value?.title ?? "-"
        self.description = proposal.content?.value?.description ?? "-"
        self.type        = proposal.content?.proposalType ?? ""
        self.status      = proposal.base?.proposalStatus ?? ""
        self.yes         = proposal.base?.tallyResult?.yes ?? "0"
        self.abstain     = proposal.base?.tallyResult?.abstain ?? "0"
        self.no          = proposal.base?.tallyResult?.no ?? "0"
        self.noWithVeto  = proposal.base?.tallyResult?.noWithVeto ?? "0"
        self.proposalId  = proposal.base?.proposalId ?? "0"
        let depAmount = proposal.base?.totalDeposit?.first?.amount ?? "0"
        let depDenom = proposal.base?.totalDeposit?.first?.denom ?? "-"
        self.totalDepopsit = "\(depAmount) \(depDenom)"
        self.submitTime = proposal.base?.submitTime ?? ""
    }

    public init(proposal: IrisProposal) {
        let data = proposal.value?.basicProposal
        self.title       = data?.title ?? "-"
        self.description = data?.description ?? "-"
        self.type        = data?.proposaltype ?? ""
        self.status      = data?.proposalStatus ?? ""
        self.yes         = data?.tallyResult?.yes ?? "0"
        self.abstain     = data?.tallyResult?.abstain ?? "0"
        self.no          = data?.tallyResult?.no ?? "0"
        self.noWithVeto  = data?.tallyResult?.noWithVeto ?? "0"
        self.proposalId  = data?.proposalId ?? "0"
        let depAmount = data?.totalDeposit?.first?.amount ?? "0"
        let depDenom = data?.totalDeposit?.first?.denom ?? "-"
        self.totalDepopsit = "\(depAmount) \(depDenom)"
        self.submitTime = data?.submitTime ?? ""
    }

}

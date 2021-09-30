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
        case .regen, .stargate, .iris, .iris_fuxi, .agoric, .osmosis, .certik, .microtick, .emoney, .terra, .terra_118:
                let restApi = CosmosRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
                restApi.getAccountV5(address: self.address) { [weak self] result in
                    switch result {
                    case .success(let data):
                        if let item = data.first {
                            let type = item.result?.type ?? ""
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
                                        DispatchQueue.main.async {
                                            //let message = error.code == 204 ? nil : error.localizedDescription
                                            completion?(nil, error.localizedDescription)
                                        }
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

        case .kava, .kava_118:
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
    
    private func getVestedAccount(node: TDMNode, gaiaKey: GaiaKey, completion: ((_ data: GaiaAccount?, _ errMsg: String?) -> ())?) {
        switch node.type {
        case .regen, .certik:
            let restApi = CosmosRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
            restApi.getVestedAccountV4(address: self.address) { result in
                switch result {
                case .success(let data):
                    if let item = data.first?.result?.value?.baseVestingAccount {
                        let gaiaAcc = GaiaAccount(accountValue: item, gaiaKey: gaiaKey, stakeDenom: node.stakeDenom)
                        restApi.getBalanceV2(address: self.address) { result in
                            switch result {
                            case .success(let data):
                                let goodAmount = data.first?.result?.first?.amount ?? "0.0"
                                gaiaAcc.amount = Double(goodAmount) ?? 0.0
                                gaiaAcc.assets = data.first?.result ?? []
                                DispatchQueue.main.async {
                                    completion?(gaiaAcc, nil)
                                }

                            case .failure(let error):
                                DispatchQueue.main.async {
                                    completion?(nil, error.localizedDescription)
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
        let restApi = CosmosRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
        restApi.getUnbondingDelegations(for: self.address) { result in
            switch result {
            case .success(let data): DispatchQueue.main.async { completion(data.first?.result, nil) }
            case .failure(let error): DispatchQueue.main.async { completion(nil, error.localizedDescription) }
            }
        }
    }
    
    public func getDelegations(node: TDMNode, completion: @escaping ((_ delegations: [GaiaDelegation]?, _ message: String?) -> ())) {
        switch node.type {
        case .stargate, .regen, .iris, .iris_fuxi, .agoric, .osmosis, .microtick, .certik, .emoney, .terra, .terra_118:
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

    public func queryValidatorRewards(node: TDMNode, validator: String, completion: @escaping ((_ delegations: Int?, _ items: [TxFeeAmount]?, _ message: String?) -> ())) {

        switch node.type {
        case .stargate, .regen, .iris, .iris_fuxi, .agoric, .osmosis, .certik, .emoney, .terra, .terra_118:
            let restApi = CosmosRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
            restApi.getValidatorRewardsStargate(from: validator) { result in
                switch result {
                case .success(let rewards):
                    let items = rewards.first?.result?.valCommission?.commission
                    let stakeDenomItems = items?.filter({ (item) -> Bool in
                        item.denom == node.stakeDenom
                    })
                    let amount = stakeDenomItems?.first?.amount?.split(separator: ".").first
                    let val = Int(amount ?? "0") ?? 0
                    DispatchQueue.main.async { completion(val, items, nil) }
                case .failure(let error):
                    DispatchQueue.main.async { completion(nil, nil, error.localizedDescription) }
                }
            }
        default:
            let restApi = CosmosRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
            restApi.getValidatorRewardsV2(from: validator) { result in
                switch result {
                case .success(let rewards):
                    let items = rewards.first?.result?.valCommission
                    let stakeDenomItems = items?.filter({ (item) -> Bool in
                        item.denom == node.stakeDenom
                    })
                    let amount = stakeDenomItems?.first?.amount?.split(separator: ".").first
                    let val = Int(amount ?? "0") ?? 0
                    DispatchQueue.main.async { completion(val, items, nil) }
                case .failure(let error):
                    DispatchQueue.main.async { completion(nil, nil, error.localizedDescription) }
                }
            }
        }
    }
    
    public func queryDelegationRewards(node: TDMNode, validatorAddr: String, completion: @escaping ((_ delegations: Int?, _ allRewards: [TxFeeAmount]?, _ message: String?) -> ())) {
        switch node.type {
        default:
            let restApi = CosmosRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
            restApi.getDelegatorRewardV2(for: self.address, fromValidator: validatorAddr) { result in
                switch result {
                case .success(let rewards):
                    let items = rewards.first?.result
                    let stakeDenomItem = items?.filter({ (item) -> Bool in
                        item.denom == node.stakeDenom
                    })
                    let amount = stakeDenomItem?.first?.amount?.split(separator: ".").first
                    let val = Int(amount ?? "0") ?? 0
                    DispatchQueue.main.async { completion(val, items, nil) }
                case .failure(let error):
                    DispatchQueue.main.async { completion(nil, nil, error.localizedDescription) }
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
    public var allRewards: [TxFeeAmount]?
    
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
    
    public init(delegation: DelegationV3) {
        self.validatorAddr = delegation.delegation?.validatorAddr ?? "-"
        self.delegatorAddr = delegation.delegation?.delegatorAddr ?? "-"
        self.height = 0
        self.shares = delegation.delegation?.shares ?? "0"
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

    init(accountValue: BaseVestingAccountV4?, gaiaKey: GaiaKey, seed: String? = nil, stakeDenom: String) {
        self.accNumber = accountValue?.baseAccount?.accountNumber ?? "0"
        self.accSequence = accountValue?.baseAccount?.sequence ?? "0"
        self.address = accountValue?.baseAccount?.address ?? "="
        self.pubKey = accountValue?.baseAccount?.publicKey?.value ?? "-"
        self.amount = 0.0
        self.denom = stakeDenom
        self.gaiaKey = gaiaKey
        self.assets = []
        
        var originalAmount: Double = 0.0
        var delegatedAmount: Double = 0.0
        for coin in accountValue?.originalVesting ?? [] {
            if coin.denom == stakeDenom {
                self.amount = Double(coin.amount ?? "0.0") ?? 0.0
                originalAmount = self.amount
                self.denom = coin.denom ?? stakeDenom
            } else {
                assets.insert(coin, at: assets.count)
            }
        }
        for coin in accountValue?.delegatedVesting ?? [] {
            if coin.denom == stakeDenom {
                delegatedAmount = Double(coin.amount ?? "0.0") ?? 0.0
                self.amount = originalAmount - delegatedAmount
                self.denom = coin.denom ?? stakeDenom
                assets.insert(Coin(amount: "\(self.amount)", denom: self.denom), at: 0)
            }
        }

        self.noFeeToken = true
    }

    init(accountValue: VestedAccountValueV3?, gaiaKey: GaiaKey, seed: String? = nil, stakeDenom: String) {
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

    public init(validator: DelegatorValidatorStargate) {
        self.validator = validator.operatorAddress ?? "-"
        self.tokens = validator.tokens ?? "0"
        self.shares = validator.delegatorShares ?? "0"
        self.moniker = validator.description?.moniker ?? "-"
        self.rate = validator.commission?.commissionRates?.rate ?? "0"
        self.jailed = false
        self.votingPower = Double(self.tokens) ?? 0.0
    }

    public func getValidatorDelegations(node: TDMNode, completion: @escaping ((_ delegations: [GaiaDelegation]?, _ message: String?) -> ())) {
        
        switch node.type {
        case .regen:
            let restApi = CosmosRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
            restApi.getStakeValidatorDelegationsV3(for: self.validator) { result in
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

    public init(proposal: ProposalStargate) {
        var status = "-1"
        if let intStatus = proposal.proposalStatus {
            status = GaiaProposal.stringStatus(for: intStatus)
        }
        self.title       = proposal.content?.value?.title ?? "-"
        self.description = proposal.content?.value?.description ?? "-"
        self.type        = proposal.content?.proposalType ?? ""
        self.status      = status
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
    
    private static func stringStatus(for intStatus: Int) -> String {
        switch intStatus {
        case 1: return "DepositPeriod"
        case 2: return "VotingPeriod"
        case 3: return "Passed"
        case 4: return "Rejected"
        default: return "Pu"
        }
    }
}

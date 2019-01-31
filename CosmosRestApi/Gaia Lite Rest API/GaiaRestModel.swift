//
//  GaiaRestModel.swift
//  CosmosRestApi
//
//  Created by Calin Chitu on 11/01/2019.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import Foundation

public enum NodeState: String, Codable {
    case active
    case pending
    case unavailable
    case unknown
}

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
        return lhs.address == rhs.address
    }
    
    public var name: String
    public var address: String
    
    public init(name: String, address: String) {
        self.name = name
        self.address = address
    }
}


public class GaiaNode: Codable {
    
    public var state: NodeState = .unknown
    public var name: String
    public var scheme: String
    public var host: String
    public var rcpPort: Int
    public var tendermintPort: Int
    public var network: String = ""
    public var nodeID: String = ""
    
    public init(name: String = "Gaia Node", scheme: String = "https", host: String = "localhost", rcpPort: Int = 1317, tendrmintPort: Int = 26657) {
        self.name = name
        self.scheme = scheme
        self.host = host
        self.rcpPort = rcpPort
        self.tendermintPort = tendrmintPort
    }
    
    public func getStatus(completion: (() -> ())?) {
        let restApi = GaiaRestAPI(scheme: scheme, host: host, port: rcpPort)
        restApi.getSyncingInfo { result in
            switch result {
            case .success(let data):
                if let item = data.first, item == "true" {
                    self.state = .pending
                } else {
                    self.state = .active
                }
            case .failure(_):
                self.state = .unknown
            }
            DispatchQueue.main.async {
                completion?()
            }
        }
    }
    
    public func getNodeInfo(completion: (() -> ())?) {
        let restApi = GaiaRestAPI(scheme: scheme, host: host, port: rcpPort)
        restApi.getNodeInfo { result in
            switch result {
            case .success(let data):
                self.network = data.first?.network ?? ""
                self.nodeID = data.first?.id ?? ""
            case .failure(_):
                self.state = .unknown
            }
            DispatchQueue.main.async {
                completion?()
            }
        }
    }

}

public class GaiaKey: CustomStringConvertible {
    
    public let name: String
    public let type: String
    public let address: String
    public let pubKey: String
    public let nodeId: String
    public var isUnlocked: Bool {
        return KeychainWrapper.stringForKey(keyName: "GaiaKey-address-\(nodeId)-\(address)-\(name)") != nil
    }
    
    init(data: Key, seed: String? = nil, nodeId: String) {
        self.nodeId = nodeId
        self.name = data.name ?? "-"
        self.type = data.type ?? "-"
        self.address = data.address ?? "-"
        self.pubKey = data.pubKey ?? "-"
        if let validSeed = seed {
            saveSeedToKeychain(seed: validSeed)
        }
    }
    
    public func unlockKey(node: GaiaNode, password: String, completion: @escaping ((_ success: Bool, _ message: String?) -> ())) {
        let restApi = GaiaRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
        let data = KeyPasswordData(name: self.name, oldPass: password, newPass: password)
        restApi.changeKeyPassword(keyData: data) { result in
            switch result {
            case .success(_): DispatchQueue.main.async { completion(true, nil) }
            case .failure(let error): DispatchQueue.main.async { completion(false, error.localizedDescription) }
            }
        }
    }
    
    public func deleteKey(node: GaiaNode, password: String, completion: @escaping ((_ success: Bool, _ message: String?) -> ())) {
        let restApi = GaiaRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
        let kdata = KeyPostData(name: self.name, pass: password, seed: nil)

        restApi.deleteKey(keyData: kdata, completion: { result in
            switch result {
            case .success(_):
                let _ = self.forgetPassFromKeychain()
                let _ = self.forgetSeedFromKeychain()
                DispatchQueue.main.async { completion(true, nil) }
            case .failure(let error): DispatchQueue.main.async { completion(false, error.localizedDescription) }
            }
         })
    }

    public func getDelegations(node: GaiaNode, completion: @escaping ((_ delegations: [GaiaDelegation]?, _ message: String?) -> ())) {
        let restApi = GaiaRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
        restApi.getDelegations(for: self.address) { result in
            switch result {
            case .success(let delegations):
                var gaiaDelegations: [GaiaDelegation] = []
                for delegation in delegations {
                    let gaiaDelegation = GaiaDelegation(validator: delegation.validatorAddr ?? "cosmosval...", shares: delegation.shares ?? "0")
                    gaiaDelegations.append(gaiaDelegation)
                }
                DispatchQueue.main.async { completion(gaiaDelegations, nil) }
            case .failure(let error): DispatchQueue.main.async { completion(nil, error.localizedDescription) }
            }
        }
    }

    public func savePassToKeychain(pass: String) {
        KeychainWrapper.setString(value: pass, forKey: "GaiaKey-address-\(nodeId)-\(address)-\(name)")
    }
    
    public func getPassFromKeychain() -> String? {
        return KeychainWrapper.stringForKey(keyName: "GaiaKey-address-\(nodeId)-\(address)-\(name)")
    }

    public func forgetPassFromKeychain() -> Bool {
        return KeychainWrapper.removeObjectForKey(keyName: "GaiaKey-address-\(nodeId)-\(address)-\(name)")
    }

    public func saveSeedToKeychain(seed: String) {
        KeychainWrapper.setString(value: seed, forKey: "GaiaKey-seed-\(nodeId)-\(address)-\(name)")
    }
    
    public func getSeedFromKeychain() -> String? {
        return KeychainWrapper.stringForKey(keyName: "GaiaKey-seed-\(nodeId)-\(address)-\(name)")
    }
    
    public func forgetSeedFromKeychain() -> Bool {
        return KeychainWrapper.removeObjectForKey(keyName: "GaiaKey-seed-\(nodeId)-\(address)-\(name)")
    }

    public var description: String {
        return "[\(name), \(type), \(address), \(pubKey)\n]"
    }
    
}

public class GaiaDelegation {
    
    public let validatorAddr: String
    public let shares: String
    
    public init(validator: String, shares: String) {
        self.validatorAddr = validator
        self.shares = shares
    }
}

public class GaiaAccount: CustomStringConvertible {
    
    public let address: String
    public let pubKey: String
    public let amount: Double
    public let denom: String
    public let feeAmount: Double?
    public let feeDenom: String?
    public let assets: [Coin]
    public let accNumber: String
    public let accSequence: String
    
    init(account: Account, seed: String? = nil) {
        self.accNumber = account.value?.accountNumber ?? "0"
        self.accSequence = account.value?.sequence ?? "0"
        self.address = account.value?.address ?? "="
        self.pubKey = account.value?.publicKey?.value ?? "-"
        let amountString = account.value?.coins?.first?.amount ?? "0"
        self.amount = Double(amountString) ?? 0.0
        self.denom = account.value?.coins?.first?.denom ?? ""
        if account.value?.coins?.count ?? 0 > 1 {
            let feeAmountString = account.value?.coins?.last?.amount ?? "0"
            self.feeAmount = Double(feeAmountString) ?? 0.0
            self.feeDenom = account.value?.coins?.last?.denom ?? ""
        } else {
            self.feeAmount = 0.0
            self.feeDenom = nil
        }
         assets = account.value?.coins ?? []
    }
    
    public var description: String {
        return "\(address): \(amount) \(denom)"
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
        self.validator = validator.operator_address ?? "-"
        self.tokens = validator.tokens ?? "0"
        self.shares = validator.delegatorShares ?? "0"
        self.moniker = validator.description?.moniker ?? "-"
        self.rate = validator.commission?.rate ?? "0"
        self.jailed = validator.jailed ?? false
        self.votingPower = Double(self.shares) ?? 0.0
    }
    
    public func unjail(node: GaiaNode, key: GaiaKey, completion: ((_ data: String?, _ errMsg: String?) -> ())?) {
        let restApi = GaiaRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
        restApi.getAccount(address: key.address) { result in
            switch result {
            case .success(let data):
                if let item = data.first {
                    let gaiaAcc = GaiaAccount(account: item)
                    let baseReq = UnjailPostData(name: key.name,
                                                 pass: key.getPassFromKeychain() ?? "",
                                                 chain: node.network,
                                                 accNum: gaiaAcc.accNumber,
                                                 sequence: gaiaAcc.accSequence)
                    
                    restApi.unjail(validator: self.validator, transferData: baseReq) { result in
                        switch result {
                        case .success(_):
                            DispatchQueue.main.async { completion?("OK", nil) }
                        case .failure(let error):
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
                    completion?(nil, error.localizedDescription)
                }
            }
        }
        
    }
}

public class GaiaProposal {
    
    public let title: String
    public let description: String
    public let type: String
    public let status: String
    public let yes: String
    public let no: String
    
    public init(proposal: Proposal) {
        self.title = proposal.value?.title ?? "-"
        self.description = proposal.value?.description ?? "-"
        self.type = proposal.value?.proposalType ?? ""
        self.status = proposal.value?.proposalStatus ?? ""
        self.yes = proposal.value?.tallyResult?.yes ?? "0"
        self.no = proposal.value?.tallyResult?.no ?? "0"
    }
}

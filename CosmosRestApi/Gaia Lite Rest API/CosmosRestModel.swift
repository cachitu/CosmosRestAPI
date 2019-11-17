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
        return lhs.address == rhs.address
    }
    
    public var name: String
    public var address: String
    
    public init(name: String, address: String) {
        self.name = name
        self.address = address
    }
}


public class GaiaKey: CustomStringConvertible, Codable {
    
    public let name: String
    public let type: String
    public let address: String
    public let pubAddress: String
    public let validator: String
    public let pubValidator: String
    public let nodeId: String
    
    public var password: String {
        return getPassFromKeychain() ?? ""
    }
    public var mnemonic: String {
        return getMnemonicFromKeychain() ?? ""
    }

    public init(data: TDMKey, nodeId: String) {
        
        self.nodeId = nodeId
        self.name = data.name ?? "-"
        self.type = data.type?.rawValue ?? "-"
        self.address = data.address ?? "-"
        self.pubAddress = data.pubAddress ?? "-"
        self.validator = data.validator ?? "-"
        self.pubValidator = data.pubValidator ?? "-"
        
        if let pass = data.password {
            savePassToKeychain(pass: pass)
        }
        if let validMnemonic = data.mnemonic {
            saveMnemonicToKeychain(seed: validMnemonic)
        }
    }
    
    public func getGaiaAccount(node: TDMNode, gaiaKey: GaiaKey, completion: ((_ data: GaiaAccount?, _ errMsg: String?) -> ())?) {
        switch node.type {
        case .cosmos, .terra:
            let restApi = CosmosRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
            restApi.getAccount(address: self.address) { [weak self] result in
                switch result {
                case .success(let data):
                    if let item = data.first, let type = item.type {
                        if type.contains("VestingAccount") {
                            self?.getVestedAccount(node: node, gaiaKey: gaiaKey, completion: completion)
                        } else {
                            let gaiaAcc = GaiaAccount(accountValue: item.value, gaiaKey: gaiaKey, stakeDenom: node.stakeDenom)
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
        case .iris: getIrisAccount(node: node, gaiaKey: gaiaKey, completion: completion)
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

    private func getVestedAccount(node: TDMNode, gaiaKey: GaiaKey, completion: ((_ data: GaiaAccount?, _ errMsg: String?) -> ())?) {
        switch node.type {
        case .cosmos, .terra:
            let restApi = CosmosRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
            restApi.getVestedAccount(address: self.address) { result in
                switch result {
                case .success(let data):
                    if let item = data.first?.value?.baseVestingAccount?.baseAccount {
                        let gaiaAcc = GaiaAccount(accountValue: item, gaiaKey: gaiaKey, stakeDenom: node.stakeDenom)
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
    }
    
    public func unlockKey(node: TDMNode, password: String, completion: @escaping ((_ success: Bool, _ message: String?) -> ())) {
        if self.password == password {
            DispatchQueue.main.async { completion(true, nil) }
        } else {
            DispatchQueue.main.async { completion(false, "Wrong password") }
        }
    }
    
    public func deleteKey(node: TDMNode, clientDelegate: KeysClientDelegate, password: String, completion: @escaping ((_ success: Bool, _ message: String?) -> ())) {
        let kdata = KeyPostData(name: self.address, pass: password, seed: nil)
        
        GaiaLocalClient(delegate: clientDelegate).deleteKey(keyData: kdata, completion: { result in
            switch result {
            case .success(_):
                let _ = self.forgetPassFromKeychain()
                let _ = self.forgetMnemonicFromKeychain()
                DispatchQueue.main.async { completion(true, nil) }
            case .failure(let error): DispatchQueue.main.async { completion(false, error.localizedDescription) }
            }
        })
    }
    
    public func getTransactions(node: TDMNode, completion: @escaping ((_ delegations: [GaiaTransaction]?, _ message: String?) -> ())) {
        let restApi = CosmosRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
        restApi.getSentTransactions(by: self.address) { result in
            switch result {
            case .success(let outTransactions):
                var gaiaTransactions: [GaiaTransaction] = []
                for transaction in outTransactions {
                    var amount = ""
                    var denom = ""
                    if let amountData = transaction.tx?.value?.msg?.first?.value?.amount {
                        switch amountData {
                        case .amount(let single):
                            amount = single.amount ?? "-"
                            denom = single.denom ?? "-"
                        case .amounts(let multiple):
                            amount = multiple.first?.amount ?? "-"
                            denom  = multiple.first?.denom ?? "-"
                        }
                    }
                    let gaiaTransaction = GaiaTransaction(
                        sender: transaction.tx?.value?.msg?.first?.value?.fromAddr ?? "-",
                        receiver: transaction.tx?.value?.msg?.first?.value?.toAddr ?? "-",
                        height: transaction.height ?? "0",
                        hash: transaction.hash ?? "-",
                        amount: "\(amount) \(denom)")
                    gaiaTransactions.append(gaiaTransaction)
                }
                restApi.getReceivedTransactions(by: self.address) { result in
                    switch result {
                    case .success(let inTransactions):
                        for transaction in inTransactions {
                            var amount = ""
                            var denom = ""
                            if let amountData = transaction.tx?.value?.msg?.first?.value?.amount {
                                switch amountData {
                                case .amount(let single):
                                    amount = single.amount ?? "-"
                                    denom = single.denom ?? "-"
                                case .amounts(let multiple):
                                    amount = multiple.first?.amount ?? "-"
                                    denom  = multiple.first?.denom ?? "-"
                                }
                            }
                            let gaiaTransaction = GaiaTransaction(
                                sender: transaction.tx?.value?.msg?.first?.value?.fromAddr ?? "-",
                                receiver: transaction.tx?.value?.msg?.first?.value?.toAddr ?? "-",
                                height: transaction.height ?? "0",
                                hash: transaction.hash ?? "-",
                                amount: "\(amount) \(denom)")
                            gaiaTransactions.append(gaiaTransaction)
                        }
                        DispatchQueue.main.async {
                            completion(gaiaTransactions, nil)
                        }
                    case .failure(let error): DispatchQueue.main.async { completion(nil, error.localizedDescription) }
                    }
                }
            case .failure(let error): DispatchQueue.main.async { completion(nil, error.localizedDescription) }
            }
        }
    }

    public func getDelegations(node: TDMNode, completion: @escaping ((_ delegations: [GaiaDelegation]?, _ message: String?) -> ())) {
        switch node.type {
        case .cosmos, .terra:
            let restApi = CosmosRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
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
        case .iris: getIrisDelegations(node: node, completion: completion)
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

    public func queryValidatorRewards(node: TDMNode, validator: String, completion: @escaping ((_ delegations: ValidatorRewards?, _ message: String?) -> ())) {
        switch node.type {
        case .cosmos, .terra:
            let restApi = CosmosRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
            restApi.getValidatorRewards(from: validator) { result in
                switch result {
                case .success(let rewards):
                    DispatchQueue.main.async { completion(rewards.first, nil) }
                case .failure(let error): DispatchQueue.main.async { completion(nil, error.localizedDescription) }
                }
            }
        case .iris:
            let restApi = IrisRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
            restApi.getValidatorRewards(from: self.address) { result in
                switch result {
                case .success(let rewards):
                    let converted = ValidatorRewards(operatorAddress: self.address, selfBondRewards: rewards.first?.total, valCommission: nil)
                    DispatchQueue.main.async { completion(converted, nil) }
                case .failure(let error): DispatchQueue.main.async { completion(nil, error.localizedDescription) }
                }
            }
        default:
            let restApi = CosmosRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
            restApi.getValidatorRewardsV2(from: validator) { result in
                switch result {
                case .success(let rewards):
                    DispatchQueue.main.async { completion(rewards.first?.result, nil) }
                case .failure(let error): DispatchQueue.main.async { completion(nil, error.localizedDescription) }
                }
            }

        }
    }

    public func queryDelegationRewards(node: TDMNode, validator: String, completion: @escaping ((_ delegations: TxFeeAmount?, _ message: String?) -> ())) {
        switch node.type {
        case .cosmos, .terra:
            let restApi = CosmosRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
            restApi.getDelegatorReward(for: self.address, fromValidator: validator) { result in
                switch result {
                case .success(let rewards):
                    DispatchQueue.main.async { completion(rewards.first, nil) }
                case .failure(let error): DispatchQueue.main.async { completion(nil, error.localizedDescription) }
                }
            }
            
        default:
            let restApi = CosmosRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
            restApi.getDelegatorRewardV2(for: self.address, fromValidator: validator) { result in
                switch result {
                case .success(let rewards):
                    DispatchQueue.main.async { completion(rewards.first?.result?.first, nil) }
                case .failure(let error): DispatchQueue.main.async { completion(nil, error.localizedDescription) }
                }
            }
        }
    }

    public func savePassToKeychain(pass: String) {
        KeychainWrapper.setString(value: pass, forKey: "GaiaKey-password-\(address)-\(name)")
    }
    
    public func getPassFromKeychain() -> String? {
        return KeychainWrapper.stringForKey(keyName: "GaiaKey-password-\(address)-\(name)")
    }

    public func forgetPassFromKeychain() -> Bool {
        return KeychainWrapper.removeObjectForKey(keyName: "GaiaKey-password-\(address)-\(name)")
    }

    public func saveMnemonicToKeychain(seed: String) {
        KeychainWrapper.setString(value: seed, forKey: "GaiaKey-mnemonic-\(address)-\(name)")
    }
    
    public func getMnemonicFromKeychain() -> String? {
        return KeychainWrapper.stringForKey(keyName: "GaiaKey-mnemonic-\(address)-\(name)")
    }
    
    public func forgetMnemonicFromKeychain() -> Bool {
        return KeychainWrapper.removeObjectForKey(keyName: "GaiaKey-mnemonic-\(address)-\(name)")
    }

    public var description: String {
        return "[\(name), \(address), \(pubAddress)\n]"
    }
    
}

public class GaiaTransaction {
    
    public let sender: String
    public let receiver: String
    public let height: Int
    public let hash: String
    public let amount: String

    public init(sender: String, receiver: String, height: String, hash: String, amount: String) {
        self.sender = sender
        self.receiver = receiver
        self.height = Int(height) ?? 0
        self.hash = hash
        self.amount = amount
    }
}

public class GaiaDelegation {
    
    public let validatorAddr: String
    public let delegatorAddr: String
    public let shares: String
    public let height: Int
    public var availableReward = "...💰"
    
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
    public var feeAmount: Double?
    public var feeDenom: String?
    public var assets: [Coin]
    public let accNumber: String
    public let accSequence: String
    public let gaiaKey: GaiaKey
    public let noFeeToken: Bool
    public var isValidator: Bool = false

    init(accountValue: AccountValue?, gaiaKey: GaiaKey, seed: String? = nil, stakeDenom: String) {
        self.accNumber = accountValue?.accountNumber ?? "0"
        self.accSequence = accountValue?.sequence ?? "0"
        self.address = accountValue?.address ?? "="
        self.pubKey = accountValue?.publicKey?.value ?? "-"
        self.amount = 0.0
        self.denom = stakeDenom
        self.feeAmount = 0.0
        self.feeDenom = "fee token?"
        self.gaiaKey = gaiaKey
        self.assets = []
        
        for coin in accountValue?.coins ?? [] {
            if coin.denom == stakeDenom {
                assets.insert(coin, at: 0)
                self.amount = Double(coin.amount ?? "0.0") ?? 0.0
                self.denom = coin.denom ?? stakeDenom
            } else {
                assets.insert(coin, at: assets.count)
                self.feeAmount = Double(coin.amount ?? "0.0") ?? 0.0
                self.feeDenom = coin.denom ?? "photin"
            }
        }
        var noFeeToken = false
        //TODO: as multiple fees are possible, this should be refactored
        //if let coins = accountValue?.coins, coins.count == 1 {
            self.feeAmount = 0.0
            self.feeDenom = stakeDenom
            noFeeToken = true
        //}
        self.noFeeToken = noFeeToken
    }
    
    init(irisAccount: IrisAccount, gaiaKey: GaiaKey, seed: String? = nil, stakeDenom: String) {
        self.accNumber = irisAccount.value?.accountNumber ?? "0"
        self.accSequence = irisAccount.value?.sequence ?? "0"
        self.address = irisAccount.value?.address ?? "="
        self.pubKey = irisAccount.value?.publicKey?.value ?? "-"
        let amountString = irisAccount.value?.coins?.first?.amount ?? "0"
        self.amount = Double(amountString) ?? 0.0
        self.denom = irisAccount.value?.coins?.first?.denom ?? stakeDenom
        self.feeAmount = 0.0
        self.feeDenom = irisAccount.value?.coins?.first?.denom ?? "fee token?"
        self.gaiaKey = gaiaKey
        self.assets = irisAccount.value?.coins ?? [Coin(amount: amountString, denom: "iris-atto")]
        self.noFeeToken = true
    }
//    public var description: String {
//        return "\(address): \(amount) \(denom)"
//    }
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
    
    public func getValidatorDelegations(node: TDMNode, completion: @escaping ((_ delegations: [GaiaDelegation]?, _ message: String?) -> ())) {
        let restApi = CosmosRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
        restApi.getStakeValidatorDelegations(for: self.validator) { result in
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

    public func unjail(node: TDMNode, clientDelegate: KeysClientDelegate, key: GaiaKey, feeAmount: String, completion: ((_ data: TransferResponse?, _ errMsg: String?) -> ())?) {
        let restApi = CosmosRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
        key.getGaiaAccount(node: node, gaiaKey: key) { (gaiaAccount, errMsg) in
            if let gaiaAcc = gaiaAccount  {
                let baseReq = UnjailPostData(name: key.address,
                                             memo: node.defaultMemo,
                                             chain: node.network,
                                             accNum: gaiaAcc.accNumber,
                                             sequence: gaiaAcc.accSequence,
                                             fees: [TxFeeAmount(amount: feeAmount, denom: gaiaAcc.feeDenom)])
                restApi.unjail(validator: self.validator, transferData: baseReq) { result in
                    switch result {
                    case .success(let data):
                        GaiaLocalClient(delegate: clientDelegate).handleSignAndBroadcast(restApi: restApi, data: data, gaiaAcc: gaiaAcc, node: node, completion: completion)
                    case .failure(let error):
                        completion?(nil, error.localizedDescription)
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
    
    public init(proposal: Proposal) {
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
    }

}
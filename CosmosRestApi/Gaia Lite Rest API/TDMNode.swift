//
//  TendermintNode.swift
//  CosmosRestApi
//
//  Created by Calin Chitu on 16/11/2019.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import Foundation

public enum TDMNodeState: String, Codable {
    case active
    case pending
    case unavailable
    case unknown
}

public enum TDMNodeType: String, Codable, CaseIterable {
    case cosmos = "Cosmos Hub"
    case iris = "Iris Network"
    case terra = "Terra Money"
    case kava = "Kava Network"
    case cosmosTestnet = "Cosmos Testnet"
    case bitsong = "Bitsong Testnet"
}

public class TDMNode: Codable {
    
    public var state: TDMNodeState = .unknown
    public var type: TDMNodeType = .cosmos
    public var name: String
    public var scheme: String
    public var host: String
    public var rcpPort: Int
    public var network: String = ""
    public var nodeID: String = ""
    public var version: String = ""
    public var stakeDenom: String = "stake"
    public var knownValidators: [String : String] = [:]
    public var defaultTxFee: String = "0"
    public var defaultMemo: String = "IPSX iOS Wallet"

    public init(name: String = "Gaia Node", type: TDMNodeType = .cosmos, scheme: String = "https", host: String = "localhost", rcpPort: Int = 1317) {
        self.type = type
        self.name = name
        self.scheme = scheme
        self.host = host
        self.rcpPort = rcpPort
    }
    
    public func getStatus(completion: (() -> ())?) {
        let restApi = CosmosRestAPI(scheme: scheme, host: host, port: rcpPort)
        restApi.getSyncingInfo { [weak self] result in
            switch result {
            case .success(let data):
                if let item = data.first, item.contains("true") {
                    self?.state = .pending
                } else {
                    self?.state = .active
                }
            case .failure(_):
                self?.state = .unknown
            }
            DispatchQueue.main.async {
                completion?()
            }
        }
    }
    
    public func getNodeInfo(completion: (() -> ())?) {
        switch type {
        case .cosmos, .terra:
            CosmosRestAPI(scheme: scheme, host: host, port: rcpPort).getNodeInfo { [weak self] result in
                switch result {
                case .success(let data):
                    self?.network = data.first?.network ?? ""
                    self?.nodeID = data.first?.id ?? ""
                    self?.version = data.first?.version ?? ""
                case .failure(_):
                    self?.state = .unknown
                }
                DispatchQueue.main.async {
                    completion?()
                }
            }
        case .iris:
            IrisRestAPI(scheme: scheme, host: host, port: rcpPort).getNodeInfo { [weak self] result in
                switch result {
                case .success(let data):
                    self?.network = data.first?.network ?? ""
                    self?.nodeID = data.first?.id ?? ""
                    self?.version = data.first?.version ?? ""
                case .failure(_):
                    self?.state = .unknown
                }
                DispatchQueue.main.async {
                    completion?()
                }
            }
        default:
            KavaRestAPI(scheme: scheme, host: host, port: rcpPort).getNodeInfo { [weak self] result in
                switch result {
                case .success(let data):
                    self?.network = data.first?.nodeInfo?.network ?? ""
                    self?.nodeID = data.first?.nodeInfo?.id ?? ""
                    self?.version = data.first?.nodeInfo?.version ?? ""
                case .failure(_):
                    self?.state = .unknown
                }
                DispatchQueue.main.async {
                    completion?()
                }
            }
            
        }
    }
    
    public func getStakingInfo(completion: ((_ satkeDenom: String?) -> ())?) {
        switch self.type {
        case .cosmos, .terra:
            let restApi = CosmosRestAPI(scheme: scheme, host: host, port: rcpPort)
            restApi.getStakeParameters() { [weak self] result in
                var denom: String? = nil
                switch result {
                case .success(let data):
                    denom = data.first?.bondDenom
                    self?.stakeDenom = denom ?? "stake"
                case .failure(_): break
                }
                DispatchQueue.main.async {
                    completion?(denom)
                }
            }
            
        default:
            let restApi = CosmosRestAPI(scheme: scheme, host: host, port: rcpPort)
            restApi.getStakeParametersV2() { [weak self] result in
                var denom: String? = nil
                switch result {
                case .success(let data):
                    denom = data.first?.result?.bondDenom
                    self?.stakeDenom = denom ?? "stake"
                case .failure(_): break
                }
                DispatchQueue.main.async {
                    completion?(denom)
                }
            }
            
        }
    }
}


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
    case iris_fuxi = "Iris Fuxi & Nyan"
    case terra = "Terra Money"
    case terra_118 = "Terra Old HD"
    case kava = "Kava Network"
    case bitsong = "Bitsong Testnet"
    case emoney = "E-money Testnet"
}

public enum BroadcastMode: String, Codable {
    case block
    case sync
    case async
}

public enum CoinLogos {
    static let atom: UIImage? = UIImage(named: "atom")
    static let atomWhite: UIImage? = UIImage(named: "atom-2")
    static let iris: UIImage? = UIImage(named: "iris")
    static let kava: UIImage? = UIImage(named: "kava")
    static let luna: UIImage? = UIImage(named: "luna")
    static let bitsong: UIImage? = UIImage(named: "bitsong")
    static let emoney: UIImage? = UIImage(named: "e-money")
}

public class TDMNode: Codable {
    
    public init(
        name: String = "Gaia Node",
        type: TDMNodeType = .cosmos,
        scheme: String = "https",
        host: String = "localhost",
        rcpPort: Int? = 1317,
        secured: Bool) {
        self.type = type
        self.name = name
        self.scheme = scheme
        self.host = host
        self.rcpPort = rcpPort
        self.securedNodeAccess = secured
        if type == .iris || type == .iris_fuxi {
            self.feeAmount = "300000000000000000"
        }
        if type == .emoney {
            self.feeAmount = "400000"
        }
    }
    
    public var state: TDMNodeState = .unknown
    public var type: TDMNodeType = .cosmos
    public var name: String
    public var scheme: String
    public var host: String
    public var rcpPort: Int?
    public var network: String = ""
    public var nodeID: String = ""
    public var version: String = ""
    public var stakeDenom: String = "stake"
    public var knownValidators: [String : String] = [:]
    public var feeAmount: String = "0"
    public var feeDenom: String = ""
    public var defaultMemo: String = ""
    public var broadcastMode: BroadcastMode = .sync
    public var appleKeyCreated: Bool = false
    public var securedNodeAccess: Bool
    public var securedSigning: Bool = false

    public var isReadOnly: Bool {
        return false//type == .iris || type == .iris_fuxi
    }
    
    public var nodeLogo: UIImage? {
        switch type {
        case .cosmos:    return CoinLogos.atom
        case .iris:      return CoinLogos.iris
        case .iris_fuxi: return CoinLogos.iris
        case .kava:      return CoinLogos.kava
        case .terra, .terra_118: return CoinLogos.luna
        case .bitsong:   return CoinLogos.bitsong
        case .emoney:    return CoinLogos.emoney
        }
    }
    
    public var nodeLogoWhite: UIImage? {
        switch type {
        case .cosmos:    return CoinLogos.atomWhite
        default: return nodeLogo
        }
    }

    public var adddressPrefix: String {
        switch type {
        case .cosmos: return "cosmos"
        case .iris: return "iaa"
        case .iris_fuxi: return "faa"
        case .kava: return "kava"
        case .terra, .terra_118: return "terra"
        case .bitsong: return "bitsong"
        case .emoney: return "emoney"
        }
    }
    
    public var decimals: Double {
        switch type {
        case .cosmos: return 6
        case .iris: return 18
        case .iris_fuxi: return 18
        case .kava: return 6
        case .terra, .terra_118: return 6
        case .bitsong: return 6
        case .emoney: return 6
        }
    }

    public var uniqueID: String {
        return "\(nodeID)-\(name)-\(type.rawValue)"
    }

    
    public func deletePinFromKeychain() {
        let _ = KeychainWrapper.removeObjectForKey(keyName: "TDMNode-pin-\(uniqueID)")
    }

    public func savePinToKeychain(pin: String) {
        KeychainWrapper.setString(value: pin, forKey: "TDMNode-pin-\(uniqueID)")
    }
    
    public func getPinFromKeychain() -> String? {
        return KeychainWrapper.stringForKey(keyName: "TDMNode-pin-\(uniqueID)")
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
        case .iris, .iris_fuxi:
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
            CosmosRestAPI(scheme: scheme, host: host, port: rcpPort).getNodeInfoV2 { [weak self] result in
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
        case .iris, .iris_fuxi:
            stakeDenom = "iris-atto"
            DispatchQueue.main.async {
                completion?("iris-atto")
            }
        default:
            let restApi = CosmosRestAPI(scheme: scheme, host: host, port: rcpPort)
            restApi.getStakeParametersV2() { [weak self] result in
                var denom: String? = nil
                switch result {
                case .success(let data):
                    denom = data.first?.result?.bondDenom
                    self?.stakeDenom = denom ?? "stake"
                    if self?.feeDenom == "" {
                        self?.feeDenom = denom ?? ""
                    }
                case .failure(_): break
                }
                DispatchQueue.main.async {
                    completion?(denom)
                }
            }
        }
    }
}


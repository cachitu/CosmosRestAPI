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
    case stargate = "Cosmos Stargate"
    case iris = "Iris Network"
    case iris_fuxi = "Iris Fuxi & Nyan"
    case terra = "Terra Money"
    case terra_118 = "Terra Old HD"
    case kava = "Kava Network"
    case kava_118 = "Kava Old HD"
    case bitsong = "Bitsong"
    case emoney = "E-money"
    case regen = "Regen Network"
    case certik = "Certik"
    case microtick = "Microtick"
    case agoric = "Agoric"
    case osmosis = "Osmosis"
    case juno = "Juno"
    case evmos = "Evmos"
}

public enum BroadcastMode: String, Codable {
    case blockMode = "block"
    case syncMode  = "sync"
    case asyncMode = "async"
}

public enum CoinLogos {
    static let atom: UIImage? = UIImage(named: "atom")
    static let atomWhite: UIImage? = UIImage(named: "atom-2")
    static let iris: UIImage? = UIImage(named: "iris")
    static let kava: UIImage? = UIImage(named: "kava")
    static let luna: UIImage? = UIImage(named: "luna")
    static let bitsong: UIImage? = UIImage(named: "bitsong")
    static let emoney: UIImage? = UIImage(named: "e-money")
    static let regen: UIImage? = UIImage(named: "regen")
    static let certik: UIImage? = UIImage(named: "certik")
    static let microtick: UIImage? = UIImage(named: "microtick")
    static let agoric: UIImage? = UIImage(named: "agoric")
    static let osmosis: UIImage? = UIImage(named: "osmosis")
    static let juno: UIImage? = UIImage(named: "juno")
    static let evmos: UIImage? = UIImage(named: "evmos")
}

public class TDMNode: Codable {
    
    public init(
        name: String = "Gaia Node",
        type: TDMNodeType = .stargate,
        scheme: String = "https",
        host: String = "localhost",
        rcpPort: Int? = nil,
        secured: Bool = false) {
            self.type = type
            self.name = name
            self.scheme = scheme
            self.host = host
            self.rcpPort = rcpPort
            self.securedNodeAccess = secured
            self.broadcastMode = .asyncMode
            self.feeAmount = "10000"
            if type == .iris || type == .iris_fuxi {
                self.feeAmount = "300000"
            }
            if type == .terra || type == .terra_118 {
                self.feeAmount = "10000"
                self.feeDenom  = "uluna"
            }
            if type == .emoney {
                self.feeAmount = "400000"
            }
            if type == .stargate {
                self.feeAmount = "100000"
            }
            if type == .osmosis {
                self.feeAmount = "100000"
            }
            if type == .juno {
                self.feeAmount = "10000"
            }
            if type == .emoney {
                self.feeAmount = "500000"
            }
            if type == .kava {
                self.feeAmount = "10000"
            }
            if type == .bitsong {
                self.feeAmount = "100000"
            }
            if type == .certik {
                self.feeAmount = "100000"
            }
            if type == .agoric {
                self.feeAmount = "0"
            }
        }
    
    public var state: TDMNodeState = .unknown
    public var type: TDMNodeType = .stargate
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
    public var broadcastMode: BroadcastMode = .asyncMode
    public var appleKeyCreated: Bool = false
    public var securedNodeAccess: Bool
    public var securedSigning: Bool = false

    public var isReadOnly: Bool {
        return false
    }
    
    public var nodeLogo: UIImage? {
        switch type {
        case .stargate:    return CoinLogos.atom
        case .iris:      return CoinLogos.iris
        case .iris_fuxi: return CoinLogos.iris
        case .kava, .kava_118:      return CoinLogos.kava
        case .terra, .terra_118: return CoinLogos.luna
        case .bitsong:   return CoinLogos.bitsong
        case .emoney:    return CoinLogos.emoney
        case .regen:     return CoinLogos.regen
        case .certik:    return CoinLogos.certik
        case .microtick: return CoinLogos.microtick
        case .agoric: return CoinLogos.agoric
        case .osmosis: return CoinLogos.osmosis
        case .juno: return CoinLogos.juno
        case .evmos: return CoinLogos.evmos
        }
    }
    
    public var nodeLogoWhite: UIImage? {
        switch type {
        case .stargate:
            return CoinLogos.atomWhite
        default: return nodeLogo
        }
    }

    public var adddressPrefix: String {
        switch type {
        case .stargate: return "cosmos"
        case .iris: return "iaa"
        case .iris_fuxi: return "faa"
        case .kava, .kava_118: return "kava"
        case .terra, .terra_118: return "terra"
        case .bitsong: return "bitsong"
        case .emoney: return "emoney"
        case .regen: return "regen"
        case .certik: return "certik"
        case .microtick: return "micro"
        case .agoric: return "agoric"
        case .osmosis: return "osmos"
        case .juno: return "juno"
        case .evmos: return "evmos"
        }
    }
    
    public var decimals: Double {
        switch type {
        default: return 6
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
    
    public func getMarkets(completion: ((_ markets: [EmoneyInstruments]?) -> ())?) {
        let restApi = CosmosRestAPI(scheme: scheme, host: host, port: rcpPort)
        restApi.getEmoneyInstruments { result in
            switch result {
            case .success(let data):
                completion?(data.first?.result?.instruments)
            case .failure(_):
                completion?(nil)
            }
        }
    }
    
    public func getStakingInfo(completion: ((_ satkeDenom: String?) -> ())?) {
        switch self.type {
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


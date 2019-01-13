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

public class GaiaNode: Codable {
    
    public var state: NodeState = .unknown
    public var name: String
    public var scheme: String
    public var host: String
    public var rcpPort: Int
    public var tendermintPort: Int
    public var network: String = ""
    
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
    public var isUnlocked: Bool {
        return KeychainWrapper.stringForKey(keyName: "GaiaKey-address-\(address)") != nil
    }
    
    init(data: Key) {
        self.name = data.name ?? "-"
        self.type = data.type ?? "-"
        self.address = data.address ?? "-"
        self.pubKey = data.pubKey ?? "-"
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
    
    public func savePassToKeychain(pass: String) {
        KeychainWrapper.setString(value: pass, forKey: "GaiaKey-address-\(address)")
    }
    
    public func getPassFromKeychain() -> String? {
        return KeychainWrapper.stringForKey(keyName: "GaiaKey-address-\(address)")
    }

    public func forgetPassFromKeychain() -> Bool {
        return KeychainWrapper.removeObjectForKey(keyName: "GaiaKey-address-\(address)")
    }

    public var description: String {
        return "[\(name), \(type), \(address), \(pubKey)\n]"
    }
    
}

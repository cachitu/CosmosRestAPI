//
//  GaiaRestModel.swift
//  CosmosRestApi
//
//  Created by Calin Chitu on 11/01/2019.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import Foundation

public class GaiaNode {
    
    public enum NodeState: String {
        case active
        case pending
        case unavailable
        case unknown
    }
    
    public var state: NodeState = .unknown
    public var name: String
    public var scheme: String
    public var host: String
    public var rcpPort: Int
    public var tendermintPort: Int

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
                self.state = .unavailable
            }
            completion?()
        }
    }
}

public class GaiaKey: CustomStringConvertible, GaiaKeyDisplayable {
    
    public let name: String
    public let type: String
    public let address: String
    public let pubKey: String
    
    init(data: Key) {
        self.name = data.name ?? "-"
        self.type = data.type ?? "-"
        self.address = data.address ?? "-"
        self.pubKey = data.pubKey ?? "-"
    }
    
    public var description: String {
        return "[\(name), \(type), \(address), \(pubKey)\n]"
    }
    
}

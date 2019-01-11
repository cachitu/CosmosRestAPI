//
//  GaiaRestModel.swift
//  CosmosRestApi
//
//  Created by Calin Chitu on 11/01/2019.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import Foundation

public class GaiaNode {
    
    public var scheme: String
    public var host: String
    public var port: Int
    
    public init(scheme: String, host: String, port: Int) {
        self.scheme = scheme
        self.host = host
        self.port = port
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

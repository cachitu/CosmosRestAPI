//
//  KavaRestApi.swift
//  CosmosRestApi
//
//  Created by Calin Chitu on 16/11/2019.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import Foundation

public class KavaRestAPI: NSObject, RestNetworking, URLSessionDelegate {
    
    static let minVersion = "0.32.7"
    
    let connectData: ConnectData
    
    public init(scheme: String = "http", host: String = "localhost", port: Int? = nil) {
        connectData = ConnectData(scheme: scheme, host: host, port: port)
        super.init()
    }
    
    public func getNodeInfo(completion: ((RestResult<[KavaNodeInfo]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/node_info", delegate: self, singleItemResponse: true, timeout: 3, completion: completion)
    }
}

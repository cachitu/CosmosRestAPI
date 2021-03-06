//
//  TerraRestApi.swift
//  CosmosRestApi
//
//  Created by Calin Chitu on 5/22/19.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import Foundation

public class TerraRestAPI: NSObject, RestNetworking, URLSessionDelegate {
    
    static let minVersion = "0.31.9"
    
    let connectData: ConnectData
    
    public init(scheme: String = "http", host: String = "localhost", port: Int? = nil) {
        connectData = ConnectData(scheme: scheme, host: host, port: port)
        super.init()
    }
    
    public func getNodeInfo(completion: ((RestResult<[NodeInfo]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/node_info", delegate: self, singleItemResponse: true, timeout: 3, completion: completion)
    }

    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(URLSession.AuthChallengeDisposition.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
    
    public func getActives(completion: ((RestResult<[Actives]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/oracle/denoms/actives", delegate: self, singleItemResponse: true, completion: completion)
    }
    
    public func getPrice(for denom:String, completion: ((RestResult<[Price]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/oracle/denoms/\(denom)/exchange_rate", delegate: self, singleItemResponse: true, completion: completion)
    }

    public func swapActive(transferData: SwapPostData, completion:((RestResult<[TransactionTx]>) -> Void)?) {
        genericRequest(bodyData: transferData, connData: connectData, path: "/market/swap", delegate: self, reqMethod: "POST", singleItemResponse: true, completion: completion)
    }
    
}

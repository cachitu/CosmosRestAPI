//
//  TerraRestApi.swift
//  CosmosRestApi
//
//  Created by Calin Chitu on 5/22/19.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import Foundation

public class TerraRestAPI: NSObject, RestNetworking, URLSessionDelegate {
    
    static let minVersion = "0.1.1"
    
    let connectData: ConnectData
    
    public init(scheme: String = "http", host: String = "localhost", port: Int = 1337) {
        connectData = ConnectData(scheme: scheme, host: host, port: port)
        super.init()
    }
    
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(URLSession.AuthChallengeDisposition.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
    
    public func getActives(completion: ((RestResult<[[String]]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/oracle/denoms/actives", delegate: self, singleItemResponse: true, completion: completion)
    }
    
    public func getPrice(for denom:String, completion: ((RestResult<[String]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/oracle/denoms/\(denom)/price", delegate: self, singleItemResponse: true, completion: completion)
    }

    public func swapActive(transferData: SwapPostData, completion:((RestResult<[TransactionTx]>) -> Void)?) {
        genericRequest(bodyData: transferData, connData: connectData, path: "/market/swap", delegate: self, reqMethod: "POST", singleItemResponse: true, completion: completion)
    }
}
//
//  IrisRestApi.swift
//  CosmosRestApi
//
//  Created by kytzu on 18/05/2019.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import Foundation

public class IrisRestAPI: NSObject, RestNetworking, URLSessionDelegate {
    
    static let minVersion = "0.13.1"
    
    let connectData: ConnectData
    
    public init(scheme: String = "http", host: String = "localhost", port: Int = 1327) {
        connectData = ConnectData(scheme: scheme, host: host, port: port)
        super.init()
    }
    
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(URLSession.AuthChallengeDisposition.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
    
    public func getAccount(address: String, completion: ((RestResult<[IrisAccount]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/auth/accounts/\(address)", delegate: self, singleItemResponse: true, completion: completion)
    }

    public func getStakeValidators(completion: ((RestResult<[DelegatorValidator]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/stake/validators", delegate: self, singleItemResponse: false, completion: completion)
    }

}

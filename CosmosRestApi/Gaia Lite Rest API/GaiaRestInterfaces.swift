//
//  GaiaRestInterfaces.swift
//  CosmosRestApi
//
//  Created by Calin Chitu on 11/01/2019.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import Foundation


// Keys management

public protocol GaiaKeysManagementCapable {
    
    var node: GaiaNode { get set }
    func retrieveAllKeys(node: GaiaNode, completion: @escaping (_ data: [GaiaKeyDisplayable]?, _ errMsg: String?)->())
}

public protocol GaiaKeyDisplayable {
    
    var name: String { get }
    var address: String { get }
}

extension GaiaKeysManagementCapable {
    
    public func retrieveAllKeys(node: GaiaNode, completion: @escaping (_ data: [GaiaKeyDisplayable]?, _ errMsg: String?)->()) {
        let restApi = GaiaRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
        
        restApi.getKeys { result in
            switch result {
            case .success(let data):
                var gaiaKeys: [GaiaKeyDisplayable] = []
                for key in data {
                    gaiaKeys.append(GaiaKey(data: key))
                }
                completion(gaiaKeys, nil)
            case .failure(let error): completion(nil, error.localizedDescription)
             }
        }
    }
}

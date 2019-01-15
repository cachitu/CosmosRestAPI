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
    func retrieveAllKeys(node: GaiaNode, completion: @escaping (_ data: [GaiaKey]?, _ errMsg: String?)->())
    func createKey(node: GaiaNode, name: String, pass: String, seed: String?, completion: @escaping (_ data: GaiaKey?, _ errMsg: String?)->())
}

extension GaiaKeysManagementCapable {
    
    public func retrieveAllKeys(node: GaiaNode, completion: @escaping (_ data: [GaiaKey]?, _ errMsg: String?)->()) {
        let restApi = GaiaRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
        
        restApi.getKeys { result in
            switch result {
            case .success(let data):
                var gaiaKeys: [GaiaKey] = []
                for key in data {
                    gaiaKeys.append(GaiaKey(data: key))
                }
                completion(gaiaKeys, nil)
            case .failure(let error): completion(nil, error.localizedDescription)
             }
        }
    }
    
    public func createKey(node: GaiaNode, name: String, pass: String, seed: String? = nil, completion: @escaping (_ data: GaiaKey?, _ errMsg: String?)->()) {
        let restApi = GaiaRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
        if let validSeed = seed {
            self.createGaiaKey(restApi: restApi, name: name, pass: pass, seed: validSeed) { rawkey, errMessage in
                if let error = errMessage {
                    completion(nil, error)
                } else if let validKey = rawkey {
                    let gaiaKey = GaiaKey(data: validKey)
                    completion(gaiaKey, nil)
                }
           }
        } else {
            createSeed(restApi: restApi, name: name, pass: pass) { rawkey, errMessage in
                if let error = errMessage {
                    completion(nil, error)
                } else if let validKey = rawkey {
                    let gaiaKey = GaiaKey(data: validKey)
                    completion(gaiaKey, nil)
                }
            }
        }
    }
    
    func createSeed(restApi: GaiaRestAPI, name: String, pass: String, completion: @escaping (_ data: Key?, _ errMsg: String?)->()) {
        restApi.createSeed { result in
            print("\n... Get seed ...")
            switch result {
            case .success(let data):
                if let seed = data.first {
                    print(" -> [OK] - ", seed)
                    self.createGaiaKey(restApi: restApi, name: name, pass: pass, seed: seed, completion: completion)
                } else {
                    completion(nil, "Failed to generate a seed")
                }
            case .failure(let error):
                print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                completion(nil, error.localizedDescription)
            }
        }
    }
    
    func createGaiaKey(restApi: GaiaRestAPI, name: String, pass: String, seed: String, completion: @escaping (_ data: Key?, _ errMsg: String?)->()) {
        let kdata = KeyPostData(name: name, pass: pass, seed: seed)
        restApi.recoverKey(keyData: kdata, completion: { result in
            print("\n... Recover testRecover with seed [\(seed)] ...")
            switch result {
            case .success(let data):
                if let item = data.first, let field = item.address {
                    print(" -> [OK] - ", field)
                    completion(item, nil)
                }
            case .failure(let error):
                print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                completion(nil, error.localizedDescription)
            }
        })
    }
}

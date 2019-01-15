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
    func getAccount(node: GaiaNode, key: GaiaKey)
}

extension GaiaKeysManagementCapable {
    
    public func getAccount(node: GaiaNode, key: GaiaKey) {
        let restApi = GaiaRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
        restApi.getAccount(address: key.address) { result in
            print("\n... Get account for \(key.address) - context transfer ...")
            switch result {
            case .success(let data):
                if let item = data.first, let field = item.type {
                    print(" -> [OK] - ", field)
                    
//                    let data = TransferPostData(name: key1name, pass: acc1Pass, chain: chainID, amount: "1", denom: "photinos", accNum: item.value?.accountNumber ?? "0", sequence: item.value?.sequence ?? "0")
//                    restApi.bankTransfer(to: addr2, transferData: data) { result in
//                        print("\n... Transfer 1 photino ...")
//                        switch result {
//                        case .success(let data):
//                            print(" -> [OK] - ", data.first?.hash ?? "")
//                        case .failure(let error):
//                            print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
//                        }
//                    }
                    
                }
            case .failure(let error):
                print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
            }
        }

    }
    
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
            self.createGaiaKey(restApi: restApi, name: name, pass: pass, seed: validSeed) { rawkey, seed, errMessage in
                if let error = errMessage {
                    completion(nil, error)
                } else if let validKey = rawkey {
                    let gaiaKey = GaiaKey(data: validKey, seed: validSeed)
                    gaiaKey.savePassToKeychain(pass: pass)
                    completion(gaiaKey, nil)
                }
           }
        } else {
            createSeed(restApi: restApi, name: name, pass: pass) { rawkey, seed, errMessage in
                if let error = errMessage {
                    completion(nil, error)
                } else if let validKey = rawkey {
                    let gaiaKey = GaiaKey(data: validKey, seed: seed)
                    completion(gaiaKey, nil)
                }
            }
        }
    }
    
    func createSeed(restApi: GaiaRestAPI, name: String, pass: String, completion: @escaping (_ data: Key?, _ seed: String?, _ errMsg: String?)->()) {
        restApi.createSeed { result in
            print("\n... Get seed ...")
            switch result {
            case .success(let data):
                if let seed = data.first {
                    print(" -> [OK] - ", seed)
                    self.createGaiaKey(restApi: restApi, name: name, pass: pass, seed: seed, completion: completion)
                } else {
                    completion(nil, nil, "Failed to generate a seed")
                }
            case .failure(let error):
                print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                completion(nil, nil, error.localizedDescription)
            }
        }
    }
    
    func createGaiaKey(restApi: GaiaRestAPI, name: String, pass: String, seed: String, completion: @escaping (_ data: Key?, _ seed: String?, _ errMsg: String?)->()) {
        let kdata = KeyPostData(name: name, pass: pass, seed: seed)
        restApi.recoverKey(keyData: kdata, completion: { result in
            print("\n... Recover testRecover with seed [\(seed)] ...")
            switch result {
            case .success(let data):
                if let item = data.first, let field = item.address {
                    print(" -> [OK] - ", field)
                    completion(item, seed, nil)
                }
            case .failure(let error):
                print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                completion(nil, nil, error.localizedDescription)
            }
        })
    }
}

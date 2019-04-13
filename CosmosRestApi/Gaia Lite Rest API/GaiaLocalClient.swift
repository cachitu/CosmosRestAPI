//
//  GaiaLocalClient.swift
//  CosmosRestApi
//
//  Created by kytzu on 09/03/2019.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import Foundation


public struct SignedTx: Codable {
    
    public var tx: TxValue?
    public let returnType: String = "block"

    public init(tx: TransactionTx?) {
        self.tx = tx?.value
    }
    
    enum CodingKeys : String, CodingKey {
        case tx
        case returnType = "mode"
    }
}

public protocol KeysClientDelegate: AnyObject {
    func getSavedKeys() -> [GaiaKey]
    func generateMnemonic() -> String
    func recoverKey(from mnemonic: String, name: String, password: String) -> Key
    func createKey(with name: String, password: String) -> Key
    func deleteKey(with name: String, password: String) -> NSError?
    func sign(transferData: TransactionTx?, account: GaiaAccount, node: GaiaNode, completion:((RestResult<[TransactionTx]>) -> Void)?)
}

public class GaiaLocalClient {
    
    public weak var delegate: KeysClientDelegate?
    
    public init(delegate: KeysClientDelegate) {
        self.delegate = delegate
    }
    
    public func getKeys(completion: ((RestResult<[GaiaKey]>) -> Void)?) {
        let keys: [GaiaKey] = delegate?.getSavedKeys() ?? []
        completion?(.success(keys))
    }
    
    public func recoverKey(keyData: KeyPostData, completion:((RestResult<[Any]>) -> Void)?) {
        guard let key = delegate?.recoverKey(from: keyData.mnemonic ?? "", name: keyData.name, password: keyData.password ?? "") else {
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "Recover failed"])
            completion?(.failure(error))
            return
        }
        completion?(.success([key]))
    }
    
    public func createSeed(completion: ((RestResult<[String]>) -> Void)?) {
        let seed = delegate?.generateMnemonic() ?? ""
        completion?(.success([seed]))
    }
    
    public func deleteKey(keyData: KeyPostData, completion:((RestResult<[String]>) -> Void)?) {
        if let error = delegate?.deleteKey(with: keyData.name, password: keyData.password ?? "") {
            completion?(.failure(error))
        } else {
            completion?(.success(["Key \(keyData.name) deleted"]))
        }
    }
    
    public class func changeKeyPassword(keyData: KeyPasswordData, completion:((RestResult<[String]>) -> Void)?) {
        completion?(.success(["OK"]))
    }
    
    public func createKey(keyData: KeyPostData, completion:((RestResult<[Any]>) -> Void)?) {
        guard let key = delegate?.createKey(with: keyData.name , password: keyData.password ?? "") else {
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "Create key failed"])
            completion?(.failure(error))
            return
        }
        completion?(.success([key]))
    }
    
    public func generateBroadcatsData(tx: TransactionTx?, account: GaiaAccount, node: GaiaNode, completion: ((SignedTx?, String?) -> ())?) {
        
        delegate?.sign(transferData: tx, account: account, node: node) { response in
            switch response {
            case .success(let data):
                completion?(SignedTx(tx: data.first), nil)
            case .failure(let error):
                print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                completion?(nil, error.localizedDescription)
            }
        }
    }
    
    public func handleSignAndBroadcast(restApi: GaiaRestAPI, data: [TransactionTx], gaiaAcc: GaiaAccount, node: GaiaNode, completion: ((_ data: TransferResponse?, _ errMsg: String?) -> ())?) {
        
        generateBroadcatsData(tx: data.first, account: gaiaAcc, node: node) { signed, err in
            
            //DispatchQueue.main.async { completion?(nil, "Broadcast blocked") }
            if let bcData = signed {
                restApi.broadcast(transferData: bcData) { result in
                    switch result {
                    case .success(let data): DispatchQueue.main.async { completion?(data.first, nil) }
                    case .failure(let error):
                        print(" -> [FAIL] - Broadcast", error.localizedDescription, ", code: ", error.code)
                        DispatchQueue.main.async { completion?(nil, error.localizedDescription) }
                    }
                }
            } else {
                DispatchQueue.main.async { completion?(nil, "Sign failed") }
            }
        }
    }
}

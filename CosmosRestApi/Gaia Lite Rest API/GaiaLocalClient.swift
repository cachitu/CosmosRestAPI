//
//  GaiaLocalClient.swift
//  CosmosRestApi
//
//  Created by kytzu on 09/03/2019.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import Foundation


public struct PersitsableHash: Codable, Equatable {
    public let hash: String
    public let date: Date
    public let height: String
}

public struct SignedTxV2: Codable {
    
    public var tx: TxValueV2?
    public let returnType: String

    public init(tx: TransactionTxV2?, mode: String) {
        self.tx = tx?.value
        self.returnType = mode
    }
    
    enum CodingKeys : String, CodingKey {
        case tx
        case returnType = "mode"
    }
}

public struct SignedTx: Codable {
    
    public var tx: TxValue?
    public let returnType: String

    public init(tx: TransactionTx?, mode: String) {
        self.tx = tx?.value
        self.returnType = mode
    }
    
    enum CodingKeys : String, CodingKey {
        case tx
        case returnType = "mode"
    }
}

public protocol KeysClientDelegate: AnyObject {
    func storeHash(_ hash: PersitsableHash)
    func generateMnemonic() -> String
    func recoverKey(from mnemonic: String, name: String, password: String) -> TDMKey
    func signV2(transferData: TransactionTx?, account: GaiaAccount, node: TDMNode, completion:((RestResult<TxValueSignatureV2>) -> Void)?)
    func sign(transferData: TransactionTx?, account: GaiaAccount, node: TDMNode, completion:((RestResult<[TransactionTx]>) -> Void)?)
}

public class GaiaLocalClient {
    
    public weak var delegate: KeysClientDelegate?
    
    public init(delegate: KeysClientDelegate) {
        self.delegate = delegate
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
    
    public class func changeKeyPassword(keyData: KeyPasswordData, completion:((RestResult<[String]>) -> Void)?) {
        completion?(.success(["OK"]))
    }
    
    public func generateBroadcatsData(tx: TransactionTx?, account: GaiaAccount, node: TDMNode, completion: ((SignedTx?, SignedTxV2?, String?) -> ())?) {
        delegate?.sign(transferData: tx, account: account, node: node) { response in
            switch response {
            case .success(let data):
                completion?(SignedTx(tx: data.first, mode: node.broadcastMode.rawValue), nil, nil)
            case .failure(let error):
                print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                completion?(nil, nil, error.localizedDescription)
            }
        }
    }
    
    public func handleSignAndBroadcast(restApi: CosmosRestAPI, data: [TransactionTx], gaiaAcc: GaiaAccount, node: TDMNode, completion: ((_ data: TransferResponse?, _ errMsg: String?) -> ())?) {
        
        guard let kdelegate = delegate else { return }
        
        generateBroadcatsData(tx: data.first, account: gaiaAcc, node: node) { signed, signedV2, err in
            
            if let bcData = signed {
                restApi.broadcastV3(transferData: bcData) { result in
                    switch result {
                    case .success(let data):
                        let resp = TransferResponse(v3: data.first!)
                        if let hash = resp.hash {
                            let persistable = PersitsableHash(hash: hash, date: Date(), height: resp.height ?? "0")
                            kdelegate.storeHash(persistable)
                        }
                        DispatchQueue.main.async { completion?(resp, data.first?.hash) }
                    case .failure(let error):
                        print(" -> [FAIL] - Broadcast", error.localizedDescription, ", code: ", error.code)
                        DispatchQueue.main.async { completion?(nil, error.localizedDescription) }
                    }
                }
            } else if let bcData = signedV2 {
                switch node.type {
                case .microtick, .certik:
                    restApi.broadcastV4(transferData: bcData) { result in
                        switch result {
                        case .success(let data):
                            let resp = TransferResponse(v3: data.first!)
                            if let hash = resp.hash {
                                let persistable = PersitsableHash(hash: hash, date: Date(), height: resp.height ?? "0")
                                kdelegate.storeHash(persistable)
                            }
                            DispatchQueue.main.async { completion?(resp, resp.hash) }
                        case .failure(let error):
                            print(" -> [FAIL] - Broadcast", error.localizedDescription, ", code: ", error.code)
                            DispatchQueue.main.async { completion?(nil, error.localizedDescription) }
                        }
                    }
                default: break
                    
                }
            } else {
                DispatchQueue.main.async { completion?(nil, "Sign failed") }
            }
        }
    }
}

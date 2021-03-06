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
        
        switch node.type {
        case .microtick:
            delegate?.signV2(transferData: tx, account: account, node: node) { response in
                switch response {
                case .success(let data):
                    let txV2 = TransactionTxV2(type: tx?.type, value: TxValueV2(msg: tx?.value?.msg, fee: tx?.value?.fee, signatures: [data], memo: tx?.value?.memo))
                    let txV2Signed = SignedTxV2(tx: txV2, mode: node.broadcastMode.rawValue)
                    completion?(nil, txV2Signed, nil)
                case .failure(let error):
                    print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                    completion?(nil, nil, error.localizedDescription)
                }
            }
        default:
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
    }
    
    public func handleSignAndBroadcast(restApi: CosmosRestAPI, data: [TransactionTx], gaiaAcc: GaiaAccount, node: TDMNode, completion: ((_ data: TransferResponse?, _ errMsg: String?) -> ())?) {
        
        guard let kdelegate = delegate else { return }
        
        generateBroadcatsData(tx: data.first, account: gaiaAcc, node: node) { signed, signedV2, err in
            
            if let bcData = signed {
                switch node.type {
                case .regen, .kava, .kava_118, .certik, .stargate, .terra, .terra_118, .bitsong, .microtick, .iris, .iris_fuxi, .agoric, .osmosis:
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
                default:
                    restApi.broadcastV2(transferData: bcData) { result in
                        switch result {
                        case .success(let data):
                            if data.first?.hash != nil {
                                let resp = TransferResponse(v2: data.first!)
                                if let hash = data.first?.hash {
                                    let persistable = PersitsableHash(hash: hash, date: Date(), height: "0")
                                    kdelegate.storeHash(persistable)
                                }
                                DispatchQueue.main.async { completion?(resp, data.first?.hash) }
                            } else {
                                print(" -> [FAIL] - Broadcast", data.first?.logs?.first?.log ?? "", ", code: ", -1)
                                DispatchQueue.main.async { completion?(nil, data.first?.logs?.first?.log ?? data.first?.rawLog ?? "Unknown") }

                            }
                        case .failure(let error):
                            print(" -> [FAIL] - Broadcast", error.localizedDescription, ", code: ", error.code)
                            DispatchQueue.main.async { completion?(nil, error.localizedDescription) }
                        }
                    }
                }
            } else if let bcData = signedV2 {
                switch node.type {
                case .microtick:
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

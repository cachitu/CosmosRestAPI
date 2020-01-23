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
    func sign(transferData: TransactionTx?, account: GaiaAccount, node: TDMNode, completion:((RestResult<[TransactionTx]>) -> Void)?)
    func signIris(transferData: TransactionTx?, account: GaiaAccount, node: TDMNode, renameShares: Bool, completion:((RestResult<[TransactionTx]>) -> Void)?)

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
    
    public func generateBroadcatsData(tx: TransactionTx?, account: GaiaAccount, node: TDMNode, irisSpaghetti: Bool, irisRenameShares: Bool = false, completion: ((SignedTx?, String?) -> ())?) {
        
        switch node.type {
        case .iris, .iris_fuxi:
            if irisSpaghetti {
               delegate?.signIris(transferData: tx, account: account, node: node, renameShares: irisRenameShares) { response in
                   switch response {
                   case .success(let data):
                    completion?(SignedTx(tx: data.first, mode: node.broadcastMode.rawValue), nil)
                   case .failure(let error):
                       print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                       completion?(nil, error.localizedDescription)
                   }
               }
            } else {
                delegate?.sign(transferData: tx, account: account, node: node) { response in
                    switch response {
                    case .success(let data):
                        completion?(SignedTx(tx: data.first, mode: node.broadcastMode.rawValue), nil)
                    case .failure(let error):
                        print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                        completion?(nil, error.localizedDescription)
                    }
                }
            }
        default:
            delegate?.sign(transferData: tx, account: account, node: node) { response in
                switch response {
                case .success(let data):
                    completion?(SignedTx(tx: data.first, mode: node.broadcastMode.rawValue), nil)
                case .failure(let error):
                    print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                    completion?(nil, error.localizedDescription)
                }
            }
        }
    }
    
    public func handleSignAndBroadcast(restApi: CosmosRestAPI, data: [TransactionTx], gaiaAcc: GaiaAccount, node: TDMNode, irisSpaghetti: Bool = false, irisRenameShares: Bool = false, completion: ((_ data: TransferResponse?, _ errMsg: String?) -> ())?) {
        
        guard let kdelegate = delegate else { return }
        
        generateBroadcatsData(tx: data.first, account: gaiaAcc, node: node, irisSpaghetti: irisSpaghetti, irisRenameShares: irisRenameShares) { signed, err in
            
            if let bcData = signed {
                switch node.type {
                case .iris, .iris_fuxi:
                    restApi.broadcastIris(transferData: bcData) { result in
                        switch result {
                        case .success(let data):
                            if let hash = data.first?.irisHash {
                                let persistable = PersitsableHash(hash: hash, date: Date(), height: "0")
                                kdelegate.storeHash(persistable)
                            }
                            DispatchQueue.main.async { completion?(data.first, data.first?.irisHash) }
                        case .failure(let error):
                            print(" -> [FAIL] - Broadcast", error.localizedDescription, ", code: ", error.code)
                            DispatchQueue.main.async { completion?(nil, error.localizedDescription) }
                        }
                    }
                case .regen:
                    restApi.broadcast(transferData: bcData) { result in
                        switch result {
                        case .success(let data):
                            if let hash = data.first?.hash {
                                let resp = data.first
                                let persistable = PersitsableHash(hash: hash, date: Date(), height: "0")
                                kdelegate.storeHash(persistable)
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
                default:
                    restApi.broadcastV2(transferData: bcData) { result in
                        switch result {
                        case .success(let data):
                            if data.first?.logs?.first?.success == true {
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
            } else {
                DispatchQueue.main.async { completion?(nil, "Sign failed") }
            }
        }
    }
}

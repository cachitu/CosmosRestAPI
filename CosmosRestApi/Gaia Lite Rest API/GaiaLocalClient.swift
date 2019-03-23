//
//  GaiaLocalClient.swift
//  CosmosRestApi
//
//  Created by kytzu on 09/03/2019.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import Foundation

/*
 
 {
 "tx": {
 "msg": [
 {
 "type": "cosmos-sdk/MsgWithdrawDelegationReward",
 "value": {
 "delegator_address": "cosmos1wtv0kp6ydt03edd8kyr5arr4f3yc52vp5g7na0",
 "validator_address": "cosmosvaloper1wtv0kp6ydt03edd8kyr5arr4f3yc52vp3u2x3u"
 }
 }
 ],
 "fee": {
 "amount": [
 {
 "denom": "photino",
 "amount": "0"
 }
 ],
 "gas": "90422"
 },
 "memo": "KytzuIOS",
 "signatures": [
 {
 "pub_key": {
 "type": "tendermint/PubKeySecp256k1",
 "value": "A2Jl4SgkOkb8cD3D0GQjaDndOCbTftt9ziWQ0oQFwV7O"
 },
 "signature": "tlk2a9+eeHMXRW71hGa+BRJaIahmHFVacEFg4dvMO5ZbFW5F15Ca/IDFZXvTcCm9iVpgrtt9l5FEOTegxKc9lw==",
 "account_number": "391",
 "sequence": "13"
 }
 ]
 },
 "return": "block"
 }
 
 {
 "height": "24617",
 "txhash": "197F30097BE23991FEA7972472F74EC5E34F6A93F96CED2D2191DAD96F389689",
 "logs": [
 {
 "msg_index": "0",
 "success": true,
 "log": ""
 }
 ],
 "gas_wanted": "90422",
 "gas_used": "69659",
 "tags": [
 {
 "key": "action",
 "value": "withdraw_delegator_reward"
 },
 {
 "key": "delegator",
 "value": "cosmos1wtv0kp6ydt03edd8kyr5arr4f3yc52vp5g7na0"
 },
 {
 "key": "source-validator",
 "value": "cosmosvaloper1wtv0kp6ydt03edd8kyr5arr4f3yc52vp3u2x3u"
 }
 ]
 }
 */

public struct SignedTx: Codable {
    
    public let returnType: String = "block"
    public var tx: TxValue?
    
    public init(tx: TransactionTx?) {
        self.tx = tx?.value
    }
    
    enum CodingKeys : String, CodingKey {
        case returnType = "return"
        case tx
    }
}

public protocol KeysClientDelegate: AnyObject {
    func getSavedKeys() -> [GaiaKey]
    func generateMnemonic() -> String
    func recoverKey(from mnemonic: String, name: String, password: String) -> Key
    func createKey(with name: String, password: String) -> Key
    func deleteKey(with name: String, password: String) -> NSError?
}

public class GaiaLocalClient {
    
    public static let signingImplemented = true
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
    
    public class func generateBroadcatsData(tx: TransactionTx?, accNum: String, sequence: String) -> SignedTx {
        
        //TODO - get those with a client, replace hardcoded
        let sig = TxValueSignature(
            sig: "BzoXNlt/GwvvMX/ed+egz4WAUPmseBQpn+AZt4sVF3E2zUvZsAQ/D0wbQfeOwItqONGyzKZjsE6OX2j6mYcz+Q==",
            type: "tendermint/PubKeySecp256k1",
            value: "A2Jl4SgkOkb8cD3D0GQjaDndOCbTftt9ziWQ0oQFwV7O",
            accNum: accNum,
            seq: sequence)
        var signed = tx
        signed?.value?.signatures = [sig]
        
        return SignedTx(tx: signed)
    }
    
    class func handleSignAndBroadcast(restApi: GaiaRestAPI, data: [TransactionTx], gaiaAcc: GaiaAccount, completion: ((_ data: TransferResponse?, _ errMsg: String?) -> ())?) {
        
        print(" -> [OK] - genrated", data.first ?? "")
        guard GaiaLocalClient.signingImplemented else {
            DispatchQueue.main.async { completion?(nil, "Tx Generated. Sign and broadcast not yet implemented") }
            return
        }
        let bcData = generateBroadcatsData(tx: data.first, accNum: gaiaAcc.accNumber, sequence: gaiaAcc.accSequence)
        restApi.broadcast(transferData: bcData) { result in
            switch result {
            case .success(let data): DispatchQueue.main.async { completion?(data.first, nil) }
            case .failure(let error):
                print(" -> [FAIL] - Broadcast", error.localizedDescription, ", code: ", error.code)
                DispatchQueue.main.async { completion?(nil, error.localizedDescription) }
            }
        }
    }
}

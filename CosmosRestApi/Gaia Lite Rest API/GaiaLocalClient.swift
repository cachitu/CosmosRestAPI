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

public class GaiaLocalClient {
    
    public static let signingImplemented = false
    
    public class func getKeys(completion: ((RestResult<[Key]>) -> Void)?) {
        var keys: [Key] = []
        if let gaiaAddress = GaiaAddressBook.loadFromDisk() as? GaiaAddressBook {
            for item in gaiaAddress.items {
                let key = Key(name: item.name, addres: item.address)
                keys.append(key)
            }
        }

        completion?(.success(keys))
    }
    
    public class func recoverKey(keyData: KeyPostData, completion:((RestResult<[Key]>) -> Void)?) {
        let key = Key(name: "KytzuHC", addres: "cosmos1yhm8yfckgre4xepqsecy6v8tnez3nk30ts5cpw")
        completion?(.success([key]))
    }
    
    public class func createSeed(completion: ((RestResult<[String]>) -> Void)?) {
        completion?(.success(["impose travel confirm oppose arctic artwork vapor develop hollow file salt spend oven result shove olympic captain snow multiply stuff health plastic cart mistake"]))
    }
    
    public class func deleteKey(keyData: KeyPostData, completion:((RestResult<[String]>) -> Void)?) {
        completion?(.success(["OK"]))
    }
    
    public class func changeKeyPassword(keyData: KeyPasswordData, completion:((RestResult<[String]>) -> Void)?) {
        completion?(.success(["OK"]))
    }
    
    public class func createKey(keyData: KeyPostData, completion:((RestResult<[Key]>) -> Void)?) {
        let key = Key(name: "KytzuHC", addres: "cosmos1yhm8yfckgre4xepqsecy6v8tnez3nk30ts5cpw")
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

//
//  TerraRestInterfaces.swift
//  CosmosRestApi
//
//  Created by Calin Chitu on 5/22/19.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import Foundation

public protocol TerraOraclesCapable {
    func retrieveAllActives(node: TDMNode, completion: @escaping (_ data: [String]?, _ errMsg: String?)->())
    func retrievePrice(node: TDMNode, active: String, completion: @escaping (_ data: String?, _ errMsg: String?)->())
}

extension TerraOraclesCapable {
    
    public func retrieveAllActives(node: TDMNode, completion: @escaping (_ data: [String]?, _ errMsg: String?)->()) {
        
        let restApi = TerraRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
        
        restApi.getActives { result in
            switch result {
            case .success(let actives): DispatchQueue.main.async {
                completion(actives.first?.result, nil)
                }
            case .failure(let error): DispatchQueue.main.async { completion(nil, error.localizedDescription) }
            }
        }
    }
    
    public func retrievePrice(node: TDMNode, active: String, completion: @escaping (_ data: String?, _ errMsg: String?)->()) {
        
        let restApi = TerraRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
        
        restApi.getPrice(for: active) { result in
            switch result {
            case .success(let price): DispatchQueue.main.async {
                completion(price.first?.result, nil)
                }
            case .failure(let error): DispatchQueue.main.async { completion(nil, error.localizedDescription) }
            }
        }
    }
    
    public func swapActives(node: TDMNode, clientDelegate: KeysClientDelegate, key: GaiaKey, offerAmount: String, offerDenom: String, askDenom: String, feeAmount: String, completion: ((_ data: TransferResponse?, _ errMsg: String?) -> ())?) {
        
        let restApi = TerraRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
        
        let gaiaRestApi = CosmosRestAPI(scheme: node.scheme, host: node.host, port: node.rcpPort)
        key.getGaiaAccount(node: node, gaiaKey: key) { (gaiaAccount, errMsg) in
            if let gaiaAcc = gaiaAccount  {
                let swData = SwapPostData(name: key.address,
                                          memo: node.defaultMemo,
                                          chain: node.network,
                                          offeredAmount: offerAmount,
                                          offeredDenom: offerDenom,
                                          askDenom: askDenom,
                                          accNum: gaiaAcc.accNumber,
                                          sequence: gaiaAcc.accSequence,
                                          fees: [TxFeeAmount(amount: feeAmount, denom: gaiaAcc.feeDenom)])
                restApi.swapActive(transferData: swData) { result in
                    switch result {
                    case .success(let data):
                        print("\n... Swapped \(offerAmount) \(offerDenom) to \(askDenom) ...")
                        GaiaLocalClient(delegate: clientDelegate).handleSignAndBroadcast(restApi: gaiaRestApi, data: data, gaiaAcc: gaiaAcc, node: node, completion: completion)
                    case .failure(let error):
                        print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                        DispatchQueue.main.async { completion?(nil, error.localizedDescription) }
                    }
                }
            } else {
                DispatchQueue.main.async { completion?(nil, errMsg) }
            }
        }
    }

}

public struct SwapPostData: Codable {
    
    public let baseReq: TransferBaseReq?
    public let offeredAmount: TxFeeAmount?
    public let askDenom: String?
    
    public init(name: String, memo: String, chain: String, offeredAmount: String?, offeredDenom: String?, askDenom: String, accNum: String, sequence: String, fees: [TxFeeAmount]?) {
        self.offeredAmount = TxFeeAmount(amount: offeredAmount, denom: offeredDenom)
        self.baseReq = TransferBaseReq(name: name, memo: memo, chainId: chain, accountNumber: accNum, sequence: sequence, fees: fees)
        self.askDenom = askDenom
    }
    
    enum CodingKeys : String, CodingKey {
        case baseReq       = "base_req"
        case offeredAmount = "offer_coin"
        case askDenom      = "ask_denom"
    }
}

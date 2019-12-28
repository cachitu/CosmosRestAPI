//
//  IrisRestApi.swift
//  CosmosRestApi
//
//  Created by kytzu on 18/05/2019.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import Foundation

public class IrisRestAPI: NSObject, RestNetworking, URLSessionDelegate {
    
    static let minVersion = "0.31.1"
    
    let connectData: ConnectData
    
    public init(scheme: String = "http", host: String = "localhost", port: Int? = nil) {
        connectData = ConnectData(scheme: scheme, host: host, port: port)
        super.init()
    }
    
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(URLSession.AuthChallengeDisposition.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
    
    public func getNodeInfo(completion: ((RestResult<[NodeInfoData]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/node-info", delegate: self, singleItemResponse: true, timeout: 3, completion: completion)
    }
    
    public func getSyncingInfo(completion: ((RestResult<[String]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/syncing", delegate: self, singleItemResponse: true, timeout: 3, completion: completion)
    }

    public func getTransactionBy(hash: String, completion: ((RestResult<[String]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/txs/\(hash)", delegate: self, singleItemResponse: true, completion: completion)
    }

    public func getAccount(address: String, completion: ((RestResult<[IrisAccount]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/bank/accounts/\(address)", delegate: self, singleItemResponse: true, completion: completion)
    }

    public func getStakeValidators(completion: ((RestResult<[DelegatorValidator]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/stake/validators", delegate: self, singleItemResponse: false, completion: completion)
    }

    public func getDelegations(for address: String, completion: ((RestResult<[IrisDelegation]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/stake/delegators/\(address)/delegations", delegate: self, completion: completion)
    }

    public func getRewards(from validator: String, completion:((RestResult<[IrisRewards]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/distribution/\(validator)/rewards", delegate: self, reqMethod: "GET", singleItemResponse: true, completion: completion)
    }
    
    public func delegation(from address: String, transferData: IrisDelegateData, completion:((RestResult<[TransactionTx]>) -> Void)?) {
        genericRequest(bodyData: transferData, connData: connectData, path: "/stake/delegators/\(address)/delegations", delegate: self, reqMethod: "POST", singleItemResponse: true, completion: completion)
    }

    public func redelegation(from address: String, transferData: IrisRedelegateData, completion:((RestResult<[TransactionTx]>) -> Void)?) {
        genericRequest(bodyData: transferData, connData: connectData, path: "/stake/delegators/\(address)/redelegations", delegate: self, reqMethod: "POST", singleItemResponse: true, completion: completion)
    }

    public func getStakeValidatorDelegations(for valAddress: String, completion: ((RestResult<[IrisDelegation]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/stake/validators/\(valAddress)/delegations", delegate: self, singleItemResponse: false, completion: completion)
    }

    public func unbonding(from address: String, transferData: IrisUnbondData, completion:((RestResult<[TransactionTx]>) -> Void)?) {
        genericRequest(bodyData: transferData, connData: connectData, path: "/stake/delegators/\(address)/unbonding-delegations", delegate: self, reqMethod: "POST", singleItemResponse: true, completion: completion)
    }

    public func withdrawReward(to address: String, transferData: IrisWithdrawData, completion:((RestResult<[TransactionTx]>) -> Void)?) {
        genericRequest(bodyData: transferData, connData: connectData, path: "/distribution/\(address)/rewards/withdraw", delegate: self, reqMethod: "POST", singleItemResponse: true, completion: completion)
    }

    public func bankTransfer(from address: String, transferData: IrisBankSendData, completion:((RestResult<[TransactionTx]>) -> Void)?) {
        genericRequest(bodyData: transferData, connData: connectData, path: "/bank/accounts/\(address)/send", delegate: self, reqMethod: "POST", singleItemResponse: true, completion: completion)
    }

    public func getPorposals(completion: ((RestResult<[IrisProposal]>) -> Void)?) {
        genericRequest(bodyData: EmptyBody(), connData: connectData, path: "/gov/proposals", delegate: self, singleItemResponse: false, completion: completion)
    }

    public func submitProposal(transferData: IrisProposeData, completion:((RestResult<[TransactionTx]>) -> Void)?) {
        genericRequest(bodyData: transferData, connData: connectData, path: "/gov/proposals", delegate: self, reqMethod: "POST", singleItemResponse: true, completion: completion)
    }

    public func depositToProposal(id: String, transferData: IrisProposalDepositData, completion:((RestResult<[TransactionTx]>) -> Void)?) {
        genericRequest(bodyData: transferData, connData: connectData, path: "/gov/proposals/\(id)/deposits", delegate: self, reqMethod: "POST", singleItemResponse: true, completion: completion)
    }

    public func unjail(validator valAddr: String, transferData: IrisUnjailData, completion:((RestResult<[TransactionTx]>) -> Void)?) {
        genericRequest(bodyData: transferData, connData: connectData, path: "/slashing/validators/\(valAddr)/unjail", delegate: self, reqMethod: "POST", singleItemResponse: true, completion: completion)
    }

    public func broadcast(transferData: SignedTx, completion:((RestResult<[TransferResponse]>) -> Void)?) {
        genericRequest(bodyData: transferData, connData: connectData, path: "/tx/broadcast", delegate: self, reqMethod: "POST", singleItemResponse: true, completion: completion)
    }

}

//
//  GaiaRestTester.swift
//  CosmosRestApi
//
//  Created by Calin Chitu on 11/01/2019.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import Foundation

public class GaiaRestTester {
  
    public static func selfTesting(
        chainID: String = "kytzu-001",
        key1name: String = "validator",
        key2name: String = "lupus",
        addr1: String = "cosmos1r627wlvrhkk637d4zarv2jpkuwuwurj9mnyskt",
        addr2: String = "cosmos1f7lf8w6kw6pwutpknyawvhvtkmkneg4932jdpv",
        val1: String  = "cosmosvaloper1r627wlvrhkk637d4zarv2jpkuwuwurj978s96c",
        val2: String  = "cosmosvaloper1f7lf8w6kw6pwutpknyawvhvtkmkneg4957xcdl",
        val2PubKey: String  = "cosmosvalconspub1zcjduepqfs7a0uysc9n07f64aups5vl5j82lsz53znevtrwn0hh2cg74g70se77crv",
        acc1Pass: String = "test1234",
        acc2Pass: String = "test1234",
        validHash: String = "0DAE0C1FC7368BEAC8E7BA4CDE8ECF4209303072F0484A7632473631F060BC49",
        recoverSeed: String = "survey man plate calm myth giggle ahead park creek marble arrest verb indicate brother donor know hedgehog armed total mechanic job caught alert breeze"
        )
    {
        
        let restApi = GaiaRestAPI()
        let dispatchGroup = DispatchGroup()
        
        
        print("... Starting ...")
        
        //ICS0
        
        dispatchGroup.enter()
        restApi.getNodeInfo { result in
            print("\n... Get Node info ...")
            switch result {
            case .success(let data):
                if let item = data.first, let field = item.network {
                    print(" -> [OK] - ", field)
                }
            case .failure(let error):
                print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        restApi.getSyncingInfo { result in
            print("\n... Get Sync info ...")
            switch result {
            case .success(let data):
                if let item = data.first {
                    print(" -> [OK] - ", item)
                }
            case .failure(let error):
                print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
            }
            dispatchGroup.leave()
        }
        
        
        dispatchGroup.enter()
        restApi.getLatestBlock { result in
            print("\n... Get Lates block ...")
            switch result {
            case .success(let data):
                if let item = data.first, let field = item.blockMeta?.blockId?.hash {
                    print(" -> [OK] - ", field)
                }
            case .failure(let error):
                print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        restApi.getBlock(at: 1) { result in
            print("\n... Get block at 1 ...")
            switch result {
            case .success(let data):
                if let item = data.first, let field = item.blockMeta?.blockId?.hash {
                    print(" -> [OK] - ", field)
                }
            case .failure(let error):
                print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        restApi.getLatestValidators() { result in
            print("\n... Get latest validators ...")
            switch result {
            case .success(let data):
                if let item = data.first, let field = item.validators?.count {
                    print(" -> [OK] - ", field)
                }
            case .failure(let error):
                print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        restApi.getValidators(at: 1000) { result in
            print("\n... Get validators at 1000 ...")
            switch result {
            case .success(let data):
                if let item = data.first, let field = item.validators?.count {
                    print(" -> [OK] - ", field)
                }
            case .failure(let error):
                print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        restApi.getTransaction(by: validHash) { result in
            print("\n... Get tx by hash:  \(validHash) ...")
            switch result {
            case .success(let data):
                if let item = data.first, let field = item.hash {
                    print(" -> [OK] - ", field)
                }
            case .failure(let error):
                print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
            }
            dispatchGroup.leave()
        }
        
        
        //ICS1
        
        dispatchGroup.enter()
        restApi.getKeys { result in
            print("\n... Get all keys on this node ...")
            switch result {
            case .success(let data):
                print(" -> [OK] - ", data.count)
            case .failure(let error):
                print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        let kdata = KeyPostData(name: "testCreate", pass: "test1234", seed: recoverSeed)
        restApi.createKey(keyData: kdata) { result in
            print("\n... Create a test key ...")
            switch result {
            case .success(let data):
                if let item = data.first, let field = item.address {
                    print(" -> [OK] - ", field)
                }
            case .failure(let error):
                print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
            }
            
            restApi.deleteKey(keyData: kdata, completion: { result in
                print("\n... Delete acc <testCreate> ...")
                switch result {
                case .success(let data):
                    if let item = data.first {
                        print(" -> [OK] - ", item)
                    }
                case .failure(let error):
                    print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                }
                dispatchGroup.leave()
            })
        }
        
        dispatchGroup.enter()
        restApi.createSeed { result in
            print("\n... Get seed ...")
            switch result {
            case .success(let data):
                if let item = data.first {
                    print(" -> [OK] - ", item)
                    
                    let kdata = KeyPostData(name: "testRecover", pass: "test1234", seed: recoverSeed)
                    restApi.recoverKey(keyData: kdata, completion: { result in
                        print("\n... Recover testRecover with seed [\(recoverSeed)] ...")
                        switch result {
                        case .success(let data):
                            if let item = data.first, let field = item.address {
                                print(" -> [OK] - ", field)
                            }
                        case .failure(let error):
                            print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                        }
                        
                        restApi.deleteKey(keyData: kdata, completion: { result in
                            print("\n... Delete acc <testRecover> ...")
                            switch result {
                            case .success(let data):
                                if let item = data.first {
                                    print(" -> [OK] - ", item)
                                }
                            case .failure(let error):
                                print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                            }
                            dispatchGroup.leave()
                        })
                    })
                }
            case .failure(let error):
                print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
            }
        }
        
        dispatchGroup.enter()
        let data = KeyPasswordData(name: key1name, oldPass: acc1Pass, newPass: "newpass123")
        restApi.changeKeyPassword(keyData: data) { result in
            print("\n... Change pass for [\(key1name)] ...")
            switch result {
            case .success(let data):
                print(" -> [OK] - ", data.count)
            case .failure(let error):
                print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
            }
            
            let data1 = KeyPasswordData(name: key1name, oldPass: "newpass123", newPass: acc1Pass)
            restApi.changeKeyPassword(keyData: data1) { result in
                print("\n... Change pass back for [\(key1name)] ...")
                switch result {
                case .success(let data):
                    print(" -> [OK] - ", data.count)
                case .failure(let error):
                    print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                }
                dispatchGroup.leave()
            }
        }
        
        
        //ICS20
        
        dispatchGroup.enter()
        restApi.getAccount(address: addr1) { result in
            print("\n... Get account for \(addr1) - context transfer ...")
            switch result {
            case .success(let data):
                if let item = data.first, let field = item.type {
                    print(" -> [OK] - ", field)
                    
                    let data = TransferPostData(name: key1name, pass: acc1Pass, chain: chainID, amount: "1", denom: "photinos", accNum: item.value?.accountNumber ?? "0", sequence: item.value?.sequence ?? "0")
                    restApi.bankTransfer(to: addr2, transferData: data) { result in
                        print("\n... Transfer 1 photino ...")
                        switch result {
                        case .success(let data):
                            print(" -> [OK] - ", data.first?.hash ?? "")
                        case .failure(let error):
                            print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                        }
                        dispatchGroup.leave()
                        
                    }
                    
                }
            case .failure(let error):
                print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.enter()
        restApi.getBalance(address: addr1) { result in
            print("\n... Get balance of \(addr1) ...")
            switch result {
            case .success(let data):
                print(" -> [OK] - ", data.first?.amount ?? "")
            case .failure(let error):
                print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
            }
            dispatchGroup.leave()
        }
        
        //ICS 21
        
        //TODO: Implement themwhen get there
        
        
        
        //ICS 22
        
        dispatchGroup.enter()
        restApi.getPorposals() { result in
            print("\n... Get Proposals ...")
            switch result {
            case .success(let data):
                print(" -> [OK] - ", data.first?.value?.title ?? "")
            case .failure(let error):
                print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        restApi.getPorposal(forId: "1") { result in
            print("\n... Get Proposal 1 ...")
            switch result {
            case .success(let data):
                print(" -> [OK] - ", data.first?.value?.title ?? "")
            case .failure(let error):
                print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        restApi.getPorposalDeposits(forId: "1") { result in
            print("\n... Get Proposal deposits for 1 ...")
            switch result {
            case .success(let data):
                print(" -> [OK] - ", data.first?.depositor ?? "")
            case .failure(let error):
                print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        restApi.getPorposalDeposit(forId: "1", by: addr1) { result in
            print("\n... Get Proposal deposit for 1 by addr1 ...")
            switch result {
            case .success(let data):
                print(" -> [OK] - ", data.first?.depositor ?? "")
            case .failure(let error):
                print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        restApi.getPorposalVotes(forId: "1") { result in
            print("\n... Get Proposal votes for 1 ...")
            switch result {
            case .success(let data):
                print(" -> [OK] - ", data.first?.voter ?? "")
            case .failure(let error):
                print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        restApi.getPorposalVote(forId: "1", by: addr1) { result in
            print("\n... Get Proposal vote for 1 by addr 1 ...")
            switch result {
            case .success(let data):
                print(" -> [OK] - ", data.first?.voter ?? "")
            case .failure(let error):
                print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        restApi.getPorposalTally(forId: "1") { result in
            print("\n... Get Proposal deposit for 1 by addr1 ...")
            switch result {
            case .success(let data):
                print(" -> [OK] - ", data.first?.no ?? "")
            case .failure(let error):
                print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        restApi.getGovDepositParameters { result in
            print("\n... Get gov deposits parameters ...")
            switch result {
            case .success(let data):
                print(" -> [OK] - ", data.first?.maxDepositPeriod ?? "")
            case .failure(let error):
                print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        restApi.getGovTallyingParameters { result in
            print("\n... Get gov tallying parameters ...")
            switch result {
            case .success(let data):
                print(" -> [OK] - ", data.first?.quorum ?? "")
            case .failure(let error):
                print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        restApi.getGovVotingParameters { result in
            print("\n... Get gov voting parameters ...")
            switch result {
            case .success(let data):
                print(" -> [OK] - ", data.first?.voting_period ?? "")
            case .failure(let error):
                print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        restApi.getAccount(address: addr1) { result in
            print("\n... Get account for \(addr1) - context create proposal ...")
            switch result {
            case .success(let data):
                if let item = data.first, let field = item.type {
                    print(" -> [OK] - ", field)
                    
                    let data = ProposalPostData(keyName: key1name, pass: acc1Pass, chain: chainID, deposit: "1", denom: "photinos", accNum: item.value?.accountNumber ?? "0", sequence: item.value?.sequence ?? "0", title: "Third", description: "Upgrade the net", proposalType: ProposalType.software_upgrade, proposer: addr1)
                    restApi.submitProposal(transferData: data) { result in
                        print("\n... Submit proposal ...")
                        switch result {
                        case .success(let data):
                            print(" -> [OK] - ", data.first?.hash ?? "")
                        case .failure(let error):
                            print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                        }
                        dispatchGroup.leave()
                        
                    }
                }
            case .failure(let error):
                print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.enter()
        restApi.getAccount(address: addr2) { result in
            print("\n... Get account for \(addr2) - context deposit to proposal ...")
            switch result {
            case .success(let data):
                if let item = data.first, let field = item.type {
                    print(" -> [OK] - ", field)
                    
                    let data = ProposalDepositPostData(keyName: key2name, pass: acc2Pass, chain: chainID, deposit: "25", denom: "STAKE", accNum: item.value?.accountNumber ?? "0", sequence: item.value?.sequence ?? "0", depositor: addr2)
                    restApi.depositToProposal(id: "2", transferData: data) { result in
                        print("\n... Submit deposit proposal id 1 ...")
                        switch result {
                        case .success(let data):
                            print(" -> [OK] - ", data.first?.hash ?? "")
                        case .failure(let error):
                            print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                        }
                        dispatchGroup.leave()
                        
                    }
                }
            case .failure(let error):
                print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.enter()
        restApi.getAccount(address: addr2) { result in
            print("\n... Get account for \(addr2) - context vote to proposal ...")
            switch result {
            case .success(let data):
                if let item = data.first, let field = item.type {
                    print(" -> [OK] - ", field)
                    
                    let data = ProposalVotePostData(keyName: key2name, pass: acc2Pass, chain: chainID, accNum: item.value?.accountNumber ?? "0", sequence: item.value?.sequence ?? "0", voter: addr2, option: .no)
                    restApi.voteProposal(id: "1", transferData: data) { result in
                        print("\n... Submit vote id 1 ...")
                        switch result {
                        case .success(let data):
                            print(" -> [OK] - ", data.first?.hash ?? "")
                        case .failure(let error):
                            print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                        }
                        dispatchGroup.leave()
                        
                    }
                }
            case .failure(let error):
                print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                dispatchGroup.leave()
            }
        }
        
        
        //ICS 23
        
        dispatchGroup.enter()
        restApi.getSlashingSigningInfo(of: val2PubKey) { result in
            print("\n... Get Slashing signing info \(val2PubKey) ...")
            switch result {
            case .success(let data):
                print(" -> [OK] - ", data.first?.missedBlocksCounter ?? "")
            case .failure(let error):
                print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        restApi.getSlashingParameters { result in
            print("\n... Get Slashing parameters ...")
            switch result {
            case .success(let data):
                print(" -> [OK] - ", data.first?.maxEvidenceAge ?? "")
            case .failure(let error):
                print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        restApi.getAccount(address: addr1) { result in
            print("\n... Get account for \(addr1) - scope unjail ...")
            switch result {
            case .success(let data):
                if let item = data.first, let field = item.type {
                    print(" -> [OK] - ", field)
                    
                    let baseReq = UnjailPostData(name: key1name, pass: acc1Pass, chain: chainID, accNum: item.value?.accountNumber ?? "0", sequence: item.value?.sequence ?? "0")
                    restApi.unjail(validator: val1, transferData: baseReq) { result in
                        print("\n... Unjail \(val1) ...")
                        switch result {
                        case .success(let data):
                            print(" -> [OK] - ", data.first?.hash ?? "")
                        case .failure(let error):
                            if error.code == 500 {
                                print(" -> [OK] - Not jailed")
                            } else {
                                print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                            }
                        }
                        dispatchGroup.leave()
                    }
                    
                }
            case .failure(let error):
                print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
                dispatchGroup.leave()
            }
        }
        
        //ICS23
        
        //Version
        
        dispatchGroup.enter()
        restApi.getGaiaVersion { result in
            print("\n... Get Gaia version ...")
            switch result {
            case .success(let data):
                print(" -> [OK] - ", data.first ?? "0")
            case .failure(let error):
                print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        restApi.getNodeVersion { result in
            print("\n... Get Node version ...")
            switch result {
            case .success(let data):
                print(" -> [OK] - ", data.first ?? "0")
            case .failure(let error):
                print(" -> [FAIL] - ", error.localizedDescription, ", code: ", error.code)
            }
            dispatchGroup.leave()
        }
        
        
        //End of tests
        
        dispatchGroup.notify(queue: DispatchQueue.main) {
            print("\n... Test Completed ...")
        }
    }
}

//
//  GaiaSimpleApi.swift
//  CosmosClient
//
//  Created by Calin Chitu on 02/01/2019.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import Foundation


/* Comes by default when gaiad is started
 
 http://localhost:26657/
 
 Available endpoints:
 //localhost:26657/abci_info
 //localhost:26657/consensus_state
 //localhost:26657/dump_consensus_state
 //localhost:26657/genesis
 //localhost:26657/health
 //localhost:26657/net_info
 //localhost:26657/num_unconfirmed_txs
 //localhost:26657/status
 
 Endpoints that require arguments:
 //localhost:26657/abci_query?path=_&data=_&height=_&prove=_
 //localhost:26657/block?height=_
 //localhost:26657/block_results?height=_
 //localhost:26657/blockchain?minHeight=_&maxHeight=_
 //localhost:26657/broadcast_tx_async?tx=_
 //localhost:26657/broadcast_tx_commit?tx=_
 //localhost:26657/broadcast_tx_sync?tx=_
 //localhost:26657/commit?height=_
 //localhost:26657/consensus_params?height=_
 //localhost:26657/subscribe?query=_
 //localhost:26657/tx?hash=_&prove=_
 //localhost:26657/tx_search?query=_&prove=_&page=_&per_page=_
 //localhost:26657/unconfirmed_txs?limit=_
 //localhost:26657/unsubscribe?query=_
 //localhost:26657/unsubscribe_all?
 //localhost:26657/validators?height=_
 
 */

public class GaiaSimpleAPI: RestNetworking {
    
    public let scheme: String
    public let host: String
    public let port: Int
    
    public init(scheme: String = "http", host: String = "localhost", port: Int = 26657) {
        self.scheme = scheme
        self.host   = host
        self.port   = port
    }
    
    public func getAbciInfo(completion: ((RestResult<AbciInfo>) -> Void)?) {
        genericGet(scheme: scheme, host: host, port: port, path: "/abci_info", completion: completion)
    }
    
    public func submitAbciInfo(info: AbciInfo, completion:((Error?) -> Void)?) {
        genericPost(info: info, scheme: scheme, host: host, port: port, path: "/abci_info", completion: completion)
    }
    
}

//
//  KavaRestModel.swift
//  CosmosRestApi
//
//  Created by Calin Chitu on 16/11/2019.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import Foundation


public struct KavaNodeInfo: Codable {
    
    public let nodeInfo: NodeInfo?
    
    enum CodingKeys : String, CodingKey {
        case nodeInfo = "node_info"
    }
}

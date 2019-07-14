//
//  TerraRestModel.swift
//  CosmosRestApi
//
//  Created by kytzu on 14/07/2019.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import Foundation

public struct Actives: Codable {
    
    public let actives: [String]?
    
    enum CodingKeys : String, CodingKey {
        case actives
    }
}

public struct Price: Codable {
    
    public let price: String?
    
    enum CodingKeys : String, CodingKey {
        case price
    }
}

//
//  TerraRestModel.swift
//  CosmosRestApi
//
//  Created by kytzu on 14/07/2019.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import Foundation

public struct Actives: Codable {
    
    public let height: String?
    public let result: [String]?
    
    enum CodingKeys : String, CodingKey {
        case height
        case result
    }
}

public struct Price: Codable {
    
    public let height: String?
    public let result: String?
    
    enum CodingKeys : String, CodingKey {
        case height
        case result
    }
}

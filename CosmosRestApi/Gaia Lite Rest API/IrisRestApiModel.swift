//
//  IrisRestModel.swift
//  CosmosRestApi
//
//  Created by kytzu on 18/05/2019.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import Foundation

public struct IrisAccount: Codable {
    
    public let address: String?
    public let coins: [String]?
    public let accountNumber: String?
    public let sequence: String?
    public let publicKey: PublicKey?

    enum CodingKeys : String, CodingKey {
        case address
        case coins
        case accountNumber = "account_number"
        case sequence
        case publicKey = "public_key"
   }
}

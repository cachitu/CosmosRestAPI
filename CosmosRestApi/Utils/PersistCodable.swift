//
//  PersistCodable.swift
//  CosmosClient
//
//  Created by Calin Chitu on 02/01/2019.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import Foundation

public protocol PersistCodable: Codable {
    
    func savetoDisk()
    func savetoDisk(withUID uid: String)
    static func loadFromDisk() -> Codable?
    static func loadFromDisk(withUID uid: String) -> Codable?
}

extension PersistCodable {
    
    public func savetoDisk() {
        let fileName = String(describing: type(of: self)) + ".json"
        guard let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(fileName) else { return }
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(self)
            try data.write(to: url, options: [])
        } catch {
            print(error.localizedDescription)
        }
    }
    
    public func savetoDisk(withUID uid: String) {
        let fileName = String(describing: type(of: self)) + "_" + uid + ".json"
        guard let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(fileName) else { return }
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(self)
            try data.write(to: url, options: [])
        } catch {
            print(error.localizedDescription)
        }
    }
    
    public static func loadFromDisk() -> Codable? {
        let fileName = String(describing: self) + ".json"
        guard let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(fileName) else { return nil }
        let decoder = JSONDecoder()
        do {
            let data = try Data(contentsOf: url, options: [])
            let decoded = try decoder.decode(self, from: data)
            return decoded
        } catch {
            return nil
        }
    }
    
    public static func loadFromDisk(withUID uid: String) -> Codable? {
        let fileName = String(describing: self) + "_" + uid + ".json"
        guard let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(fileName) else { return nil }
        let decoder = JSONDecoder()
        do {
            let data = try Data(contentsOf: url, options: [])
            let decoded = try decoder.decode(self, from: data)
            return decoded
        } catch {
            return nil
        }
    }
}

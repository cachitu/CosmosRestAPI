//
//  KeychainWrapper.swift
//  IPSX
//
//  Created by Cristina Virlan on 02/05/2018.
//  Copyright (c) 2014 Jason Rendel. All rights reserved.
//
//  The MIT License (MIT)

import Foundation
import LocalAuthentication

let SecMatchLimit: String! = kSecMatchLimit as String
let SecReturnData: String! = kSecReturnData as String
let SecValueData: String! = kSecValueData as String
let SecAttrAccessible: String! = kSecAttrAccessible as String
let SecClass: String! = kSecClass as String
let SecAttrService: String! = kSecAttrService as String
let SecAttrGeneric: String! = kSecAttrGeneric as String
let SecAttrAccount: String! = kSecAttrAccount as String
let SecAttrAccessGroup: String! = kSecAttrAccessGroup as String

/// KeychainWrapper is a class to help make Keychain access in Swift more straightforward. It is designed to make accessing the Keychain services more like using NSUserDefaults, which is much more familiar to people.
public class KeychainWrapper {
    
    // MARK: Private static Properties
    private struct internalVars {
        static var serviceName: String = ""
        static var accessGroup: String = ""
    }
    
    // MARK: Public Properties
    
    /// ServiceName is used for the kSecAttrService property to uniquely identify this keychain accessor. If no service name is specified, KeychainWrapper will default to using the bundleIdentifier.
    ///
    ///This is a static property and only needs to be set once
    public class var serviceName: String {
        get {
            if internalVars.serviceName.isEmpty {
                internalVars.serviceName = Bundle.main.bundleIdentifier ?? "SwiftKeychainWrapper"
            }
            return internalVars.serviceName
        }
        set(newServiceName) {
            internalVars.serviceName = newServiceName
        }
    }
    
    public class var deviceHasPasscode: Bool {
        return LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
    }
    
    /// AccessGroup is used for the kSecAttrAccessGroup property to identify which Keychain Access Group this entry belongs to. This allows you to use the KeychainWrapper with shared keychain access between different applications.
    ///
    /// Access Group defaults to an empty string and is not used until a valid value is set.
    ///
    /// This is a static property and only needs to be set once. To remove the access group property after one has been set, set this to an empty string.
    public class var accessGroup: String {
        get {
            return internalVars.accessGroup
        }
        set(newAccessGroup){
            internalVars.accessGroup = newAccessGroup
        }
    }
    
    // MARK: Public Methods
    
    /// Checks if keychain data exists for a specified key.
    ///
    /// - parameter keyName: The key to check for.
    /// - returns: True if a value exists for the key. False otherwise.
    public class func hasValueForKey(keyName: String) -> Bool {
        let keychainData: NSData? = self.dataForKey(keyName: keyName)
        if keychainData != nil {
            return true
        } else {
            return false
        }
    }
    
    /// Returns a string value for a specified key.
    ///
    /// - parameter keyName: The key to lookup data for.
    /// - returns: The String associated with the key if it exists. If no data exists, or the data found cannot be encoded as a string, returns nil.
    public class func stringForKey(keyName: String) -> String? {
        let keychainData: NSData? = self.dataForKey(keyName: keyName)
        var stringValue: String?
        if let data = keychainData {
            stringValue = NSString(data: data as Data, encoding: String.Encoding.utf8.rawValue) as String?
        }
        
        return stringValue
    }
    
    
    /// Returns an object that conforms to NSCoding for a specified key.
    ///
    /// - parameter keyName: The key to lookup data for.
    /// - returns: The decoded object associated with the key if it exists. If no data exists, or the data found cannot be decoded, returns nil.
    public class func objectForKey(keyName: String) -> NSCoding? {
        let dataValue: NSData? = self.dataForKey(keyName: keyName)
        
        var objectValue: NSCoding?
        
        if let data = dataValue {
            objectValue = NSKeyedUnarchiver.unarchiveObject(with: data as Data) as? NSCoding
        }
        
        return objectValue;
    }
    
    
    /// Returns a NSData object for a specified key.
    ///
    /// - parameter keyName: The key to lookup data for.
    /// - returns: The NSData object associated with the key if it exists. If no data exists, returns nil.
    public class func dataForKey(keyName: String) -> NSData? {
        var keychainQueryDictionary = self.setupKeychainQueryDictionaryForKey(keyName: keyName)
        var result: AnyObject?
        
        // Limit search results to one
        keychainQueryDictionary[SecMatchLimit] = kSecMatchLimitOne
        
        // Specify we want NSData/CFData returned
        keychainQueryDictionary[SecReturnData] = kCFBooleanTrue
        
        // Search
        let status = withUnsafeMutablePointer(to: &result) {
            SecItemCopyMatching(keychainQueryDictionary as CFDictionary, UnsafeMutablePointer($0))
        }
        
        return status == noErr ? result as? NSData : nil
    }
    
    /// Save a String value to the keychain associated with a specified key. If a String value already exists for the given keyname, the string will be overwritten with the new value.
    ///
    /// - parameter value: The String value to save.
    /// - parameter forKey: The key to save the String under.
    /// - returns: True if the save was successful, false otherwise.
    @discardableResult
    public class func setString(value: String, forKey keyName: String) -> Bool {
        if let data = value.data(using: String.Encoding.utf8) {
            return self.setData(value: data as NSData, forKey: keyName)
        } else {
            return false
        }
    }
    
    
    /// Save an NSCoding compliant object to the keychain associated with a specified key. If an object already exists for the given keyname, the object will be overwritten with the new value.
    ///
    /// - parameter value: The NSCoding compliant object to save.
    /// - parameter forKey: The key to save the object under.
    /// - returns: True if the save was successful, false otherwise.
    public class func setObject(value: NSCoding, forKey keyName: String) -> Bool {
        let data = NSKeyedArchiver.archivedData(withRootObject: value)
        
        return self.setData(value: data as NSData, forKey: keyName)
    }
    
    /// Save a NSData object to the keychain associated with a specified key. If data already exists for the given keyname, the data will be overwritten with the new value.
    ///
    /// - parameter value: The NSData object to save.
    /// - parameter forKey: The key to save the object under.
    /// - returns: True if the save was successful, false otherwise.
    public class func setData(value: NSData, forKey keyName: String) -> Bool {
        var keychainQueryDictionary: [String:AnyObject] = self.setupKeychainQueryDictionaryForKey(keyName: keyName)
        
        keychainQueryDictionary[SecValueData] = value
        
        // Protect the keychain entry so it's only valid when the device is unlocked
        keychainQueryDictionary[SecAttrAccessible] = kSecAttrAccessibleWhenUnlocked
        
        let status: OSStatus = SecItemAdd(keychainQueryDictionary as CFDictionary, nil)
        
        if status == errSecSuccess {
            return true
        } else if status == errSecDuplicateItem {
            return self.updateData(value: value, forKey: keyName)
        } else {
            return false
        }
    }
    
    /// Remove an object associated with a specified key.
    ///
    /// - parameter keyName: The key value to remove data for.
    /// - returns: True if successful, false otherwise.
    public class func removeObjectForKey(keyName: String) -> Bool {
        let keychainQueryDictionary: [String:AnyObject] = self.setupKeychainQueryDictionaryForKey(keyName: keyName)
        
        // Delete
        let status: OSStatus =  SecItemDelete(keychainQueryDictionary as CFDictionary);
        
        if status == errSecSuccess {
            return true
        } else {
            return false
        }
    }
    
    // MARK: Private Methods
    
    /// Update existing data associated with a specified key name. The existing data will be overwritten by the new data
    private class func updateData(value: NSData, forKey keyName: String) -> Bool {
        let keychainQueryDictionary: [String:AnyObject] = self.setupKeychainQueryDictionaryForKey(keyName: keyName)
        let updateDictionary = [SecValueData:value]
        
        // Update
        let status: OSStatus = SecItemUpdate(keychainQueryDictionary as CFDictionary, updateDictionary as CFDictionary)
        
        if status == errSecSuccess {
            return true
        } else {
            return false
        }
    }
    
    /// Setup the keychain query dictionary used to access the keychain on iOS for a specified key name. Takes into account the Service Name and Access Group if one is set.
    ///
    /// - parameter keyName: The key this query is for
    /// - returns: A dictionary with all the needed properties setup to access the keychain on iOS
    private class func setupKeychainQueryDictionaryForKey(keyName: String) -> [String:AnyObject] {
        // Setup dictionary to access keychain and specify we are using a generic password (rather than a certificate, internet password, etc)
        var keychainQueryDictionary: [String:AnyObject] = [SecClass:kSecClassGenericPassword]
        
        // Uniquely identify this keychain accessor
        keychainQueryDictionary[SecAttrService] = KeychainWrapper.serviceName as AnyObject?
        
        // Set the keychain access group if defined
        if !KeychainWrapper.accessGroup.isEmpty {
            keychainQueryDictionary[SecAttrAccessGroup] = KeychainWrapper.accessGroup as AnyObject?
        }
        
        // Uniquely identify the account who will be accessing the keychain
        let encodedIdentifier: NSData? = keyName.data(using: String.Encoding.utf8) as NSData?
        
        keychainQueryDictionary[SecAttrGeneric] = encodedIdentifier
        
        keychainQueryDictionary[SecAttrAccount] = encodedIdentifier
        
        return keychainQueryDictionary
    }
}

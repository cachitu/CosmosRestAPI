//
//  RestNetowking.swift
//  CosmosClient
//
//  Created by Calin Chitu on 02/01/2019.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import Foundation


public struct ConnectData {
    public var scheme: String
    public var host: String
    public var port: Int
}

public enum RestResult<Value> {
    case success(Value)
    case failure(Error)
}


public protocol RestNetworking {
    
    func genericGet<T: Codable>(connData: ConnectData, path: String, delegate: URLSessionDelegate?, completion: ((RestResult<[T]>) -> Void)?)
    func genericGet<T: Codable>(connData: ConnectData, path: String, delegate: URLSessionDelegate?, completion: ((RestResult<T>) -> Void)?)
    func genericBodyData<T: Codable, TResp: Codable>(data: T, connData: ConnectData, path: String, delegate: URLSessionDelegate?, reqMethod: String, completion:((RestResult<TResp>) -> Void)?)
}

extension RestNetworking {
    
    public func genericGet<T: Codable>(connData: ConnectData, path: String, delegate: URLSessionDelegate? = nil, completion: ((RestResult<[T]>) -> Void)?) {
        
        var urlComponents = URLComponents()
        urlComponents.scheme = connData.scheme
        urlComponents.host = connData.host
        urlComponents.port = connData.port
        urlComponents.path = path
        
        guard let url = urlComponents.url else {
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "Could not create URL from components"]) as Error
            completion?(.failure(error))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
        
        let task = session.dataTask(with: request) { (responseData, response, responseError) in
            DispatchQueue.main.async {
                
                if let error = responseError {
                    completion?(.failure(error))
                } else if let jsonData = responseData {
                    
                    let rsData = String(data: jsonData, encoding: String.Encoding.utf8)
                    let httpResponse = response as! HTTPURLResponse
                    if httpResponse.statusCode == 200 {
                        
                        let decoder = JSONDecoder()
                        decoder.dateDecodingStrategy = .iso8601

                        do {
                            let decoded = try decoder.decode([T].self, from: jsonData)
                            completion?(.success(decoded))
                        } catch {
                            completion?(.failure(error))
                        }
                    } else {
                        let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : rsData ?? "Unknown error"]) as Error
                        completion?(.failure(error))
                    }
                    
                } else {
                    let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "Data was not retrieved from request"]) as Error
                    completion?(.failure(error))
                }
            }        }
        
        task.resume()
        
    }
    
    public func genericGet<T: Codable>(connData: ConnectData, path: String, delegate: URLSessionDelegate? = nil, completion: ((RestResult<T>) -> Void)?) {
        
        var urlComponents = URLComponents()
        urlComponents.scheme = connData.scheme
        urlComponents.host = connData.host
        urlComponents.port = connData.port
        urlComponents.path = path
        
        guard let url = urlComponents.url else {
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "Could not create URL from components"]) as Error
            completion?(.failure(error))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
        
        let task = session.dataTask(with: request) { (responseData, response, responseError) in
            DispatchQueue.main.async {
                
                if let error = responseError {
                    completion?(.failure(error))
                } else if let jsonData = responseData {
                    
                    let rsData = String(data: jsonData, encoding: String.Encoding.utf8)
                    let httpResponse = response as! HTTPURLResponse
                    if httpResponse.statusCode == 200 {
                        
                        if T.self is String.Type, let data = rsData as? T {
                         
                            completion?(.success(data))
                            return
                        }
                        
                        let decoder = JSONDecoder()
                        decoder.dateDecodingStrategy = .iso8601

                        do {
                            let decoded = try decoder.decode(T.self, from: jsonData)
                            completion?(.success(decoded))
                        } catch {
                            completion?(.failure(error))
                        }
                    } else {
                        let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : rsData ?? "Unknown error"]) as Error
                        completion?(.failure(error))
                    }
                    
                } else {
                    let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "Data was not retrieved from request"]) as Error
                    completion?(.failure(error))
                }
            }
        }
        
        task.resume()
        
    }
    
    public func genericBodyData<T: Codable, TResp: Codable>(data: T, connData: ConnectData, path: String, delegate: URLSessionDelegate? = nil, reqMethod: String, completion:((RestResult<TResp>) -> Void)?) {
        
        var urlComponents = URLComponents()
        urlComponents.scheme = connData.scheme
        urlComponents.host = connData.host
        urlComponents.port = connData.port
        urlComponents.path = path
        guard let url = urlComponents.url else {
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "Could not create URL from components"]) as Error
            completion?(.failure(error))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = reqMethod
        
        var headers = request.allHTTPHeaderFields ?? [:]
        headers["Content-Type"] = "application/json"
        request.allHTTPHeaderFields = headers
        
        let encoder = JSONEncoder()
        do {
            let jsonData = try encoder.encode(data)
            request.httpBody = jsonData
        } catch {
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "Could not encode data"]) as Error
            completion?(.failure(error))
        }
        
        let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)

        let task = session.dataTask(with: request) { (responseData, response, responseError) in
            if let error = responseError {
                completion?(.failure(error))
            } else if let jsonData = responseData {
                let rsData = String(data: jsonData, encoding: String.Encoding.utf8)
                let httpResponse = response as! HTTPURLResponse
                if httpResponse.statusCode == 200 {

                    if TResp.self is String.Type, let data = rsData as? TResp {
                        completion?(.success(data))
                        return
                    }

                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    
                    do {
                        let decoded = try decoder.decode(TResp.self, from: jsonData)
                        completion?(.success(decoded))
                    } catch {
                        completion?(.failure(error))
                    }
                } else {
                    let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : rsData ?? "Unknown error"]) as Error
                    completion?(.failure(error))
                }
            } else {
                let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "Data was not retrieved from request"]) as Error
                completion?(.failure(error))
            }
        }
        
        task.resume()
    }

}

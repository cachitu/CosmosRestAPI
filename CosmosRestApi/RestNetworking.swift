//
//  RestNetowking.swift
//  CosmosClient
//
//  Created by Calin Chitu on 02/01/2019.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import Foundation

public enum RestResult<Value> {
    case success(Value)
    case failure(Error)
}

public protocol RestNetworking {
    
    func genericGet<T: Codable>(scheme: String, host: String, port: Int, path: String, delegate: URLSessionDelegate?, completion: ((RestResult<[T]>) -> Void)?)
    func genericGet<T: Codable>(scheme: String, host: String, port: Int, path: String, delegate: URLSessionDelegate?, completion: ((RestResult<T>) -> Void)?)
    func genericPost<T: Codable>(info: T, scheme: String, host: String, port: Int, path: String, delegate: URLSessionDelegate?, completion:((Error?) -> Void)?)
}

extension RestNetworking {
    
    public func genericGet<T: Codable>(scheme: String = "https", host: String = "localhost", port: Int = 1317, path: String, delegate: URLSessionDelegate? = nil, completion: ((RestResult<[T]>) -> Void)?) {
        
        var urlComponents = URLComponents()
        urlComponents.scheme = scheme
        urlComponents.host = host
        urlComponents.port = port
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
                    
                    let decoder = JSONDecoder()
                    
                    do {
                        let decoded = try decoder.decode([T].self, from: jsonData)
                        completion?(.success(decoded))
                    } catch {
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
    
    public func genericGet<T: Codable>(scheme: String = "https", host: String = "localhost", port: Int = 1317, path: String, delegate: URLSessionDelegate? = nil, completion: ((RestResult<T>) -> Void)?) {
        
        var urlComponents = URLComponents()
        urlComponents.scheme = scheme
        urlComponents.host = host
        urlComponents.port = port
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
                    
                    let decoder = JSONDecoder()
                    
                    do {
                        let decoded = try decoder.decode(T.self, from: jsonData)
                        completion?(.success(decoded))
                    } catch {
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
    
    public func genericPost<T: Codable>(info: T, scheme: String, host: String, port: Int, path: String, delegate: URLSessionDelegate? = nil, completion:((Error?) -> Void)?) {
        
        var urlComponents = URLComponents()
        urlComponents.scheme = scheme
        urlComponents.host = host
        urlComponents.port = port
        urlComponents.path = path
        guard let url = urlComponents.url else {
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "Could not create URL from components"]) as Error
            completion?(error)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        var headers = request.allHTTPHeaderFields ?? [:]
        headers["Content-Type"] = "application/json"
        request.allHTTPHeaderFields = headers
        
        let encoder = JSONEncoder()
        do {
            let jsonData = try encoder.encode(info)
            request.httpBody = jsonData
            print("jsonData: ", String(data: request.httpBody!, encoding: .utf8) ?? "no body data")
        } catch {
            completion?(error)
        }
        
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        let task = session.dataTask(with: request) { (responseData, response, responseError) in
            guard responseError == nil else {
                completion?(responseError!)
                return
            }
            
            if let data = responseData, let utf8Representation = String(data: data, encoding: .utf8) {
                print("response: ", utf8Representation)
            } else {
                print("no readable data received in response")
            }
        }
        
        task.resume()
    }
    
}

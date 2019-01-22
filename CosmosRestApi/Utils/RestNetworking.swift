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
    case failure(NSError)
}

public struct EmptyBody: Codable {}

public protocol RestNetworking {
    
    func genericRequest<Body: Codable, Resp: Codable>(
        bodyData: Body,
        connData: ConnectData,
        path: String,
        delegate: URLSessionDelegate?,
        reqMethod: String,
        singleItemResponse: Bool,
        timeout: Double,
        completion: ((RestResult<[Resp]>) -> Void)?)
}

extension RestNetworking {
 
    //Default protocol implementation
    public func genericRequest<Body: Codable, Resp: Codable>(
        bodyData: Body,
        connData: ConnectData,
        path: String,
        delegate: URLSessionDelegate? = nil,
        reqMethod: String = "GET",
        singleItemResponse: Bool = false,
        timeout: Double = 20,
        completion: ((RestResult<[Resp]>) -> Void)?)
    {
        
        var urlComponents = URLComponents()
        urlComponents.scheme = connData.scheme
        urlComponents.host = connData.host
        urlComponents.port = connData.port
        urlComponents.path = path

        guard let url = urlComponents.url else {
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "Could not create URL from components"])
            completion?(.failure(error))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = reqMethod
        
        if !(Body.self is EmptyBody.Type) {
            
            var headers = request.allHTTPHeaderFields ?? [:]
            headers["Content-Type"] = "application/json"
            request.allHTTPHeaderFields = headers
            
            let encoder = JSONEncoder()
            do {
                let jsonData = try encoder.encode(bodyData)
                request.httpBody = jsonData
            } catch {
                let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "Could not encode data"])
                completion?(.failure(error))
            }
        }
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest  = timeout
        configuration.timeoutIntervalForResource = timeout
        
        let session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
        
        let task = session.dataTask(with: request) { (responseData, response, responseError) in
            DispatchQueue.main.async {
                
                if let error = responseError as NSError? {
                    completion?(.failure(error))
                } else if let jsonData = responseData {
                    
                    let rsData = String(data: jsonData, encoding: String.Encoding.utf8)
                    let httpResponse = response as! HTTPURLResponse
                    if httpResponse.statusCode == 200 {
                        
                        if Resp.self is String.Type, let data = rsData as? Resp {
                            completion?(.success([data]))
                            return
                        }
                        
                        let decoder = JSONDecoder()
                        decoder.dateDecodingStrategy = .iso8601
                        
                        do {
                            if singleItemResponse {
                                let decoded = try decoder.decode(Resp.self, from: jsonData)
                                completion?(.success([decoded]))
                            } else {
                                let decoded = try decoder.decode([Resp].self, from: jsonData)
                                completion?(.success(decoded))
                            }
                        } catch {
                            let derror = NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey : "Resp 200 but no data.Assuming OK"])
                            completion?(.failure(derror))
                        }
                    } else {
                        let error = NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey : rsData ?? "Unknown error"])
                        completion?(.failure(error))
                    }
                    
                } else {
                    let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "Data was not retrieved from request"])
                    completion?(.failure(error))
                }
            }        }
        
        task.resume()
    }
    
}

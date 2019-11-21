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
    
    public init(scheme: String, host: String, port: Int) {
        self.scheme = scheme
        self.host = host
        self.port = port
    }
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
        queryItems: [URLQueryItem]?,
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
        queryItems: [URLQueryItem]? = nil,
        completion: ((RestResult<[Resp]>) -> Void)?)
    {
        
        let debug = true
        
        var urlComponents = URLComponents()
        urlComponents.scheme = connData.scheme
        urlComponents.host = connData.host
        urlComponents.port = connData.port
        urlComponents.path = path
        
        if let validQuery = queryItems {
            urlComponents.queryItems = validQuery
        }
        
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
        
        if debug {
            print("Req will start: \(url.absoluteString)")
            print("Req post body ------->")
            let body = String(data: request.httpBody ?? Data(), encoding: String.Encoding.utf8)
            print(body ?? "-")
            print("Req post body <-------")
        }

        let task = session.dataTask(with: request) { (responseData, response, responseError) in
            DispatchQueue.main.async {
                if let error = responseError as NSError? {
                    completion?(.failure(error))
                } else if let jsonData = responseData {
                    
                    let rsData = String(data: jsonData, encoding: String.Encoding.utf8)
                    if debug {
                        print("Req completed \(response?.url?.path ?? "/"): ", Resp.self)
                        print("Resp body ------->")
                        print(rsData ?? "")
                        print("Resp body <-------")

                    }
                    if rsData == "null" {
                        completion?(.success([]))
                        return
                    }
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
            }
        }
        
        task.resume()
        session.finishTasksAndInvalidate()
    }
    
}


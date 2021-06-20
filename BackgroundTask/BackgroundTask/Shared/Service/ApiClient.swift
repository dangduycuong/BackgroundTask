

import Foundation
import Moya
import Alamofire

func JSONResponseDataFormatter(_ data: Data) -> Data {
    do {
        let dataAsJSON = try JSONSerialization.jsonObject(with: data)
        let prettyData =  try JSONSerialization.data(withJSONObject: dataAsJSON, options: .prettyPrinted)
        return prettyData
    } catch {
        return data // fallback to original data if it can't be serialized.
    }
}

class DefaultAlamofireManager: Alamofire.Session {
    static let sharedManager: DefaultAlamofireManager = {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = Alamofire.SessionManager.defaultHTTPHeaders
        configuration.timeoutIntervalForRequest = 600 // as seconds, you can set your request timeout
        configuration.timeoutIntervalForResource = 600 // as seconds, you can set your resource timeout
        configuration.requestCachePolicy = .useProtocolCachePolicy
        return DefaultAlamofireManager(configuration: configuration)
    }()
}

public class ApiClient {
    
    static let shared = ApiClient()
    
    var urlRequests: [URLRequest] = []
    
    func callApi<T: TargetType>(_ target: T,_ completionHandler: @escaping ((ApiResponse?) -> Void)) -> Cancellable {
        // for adding headers
        let endpointClosure = { (target: T) -> Endpoint in
            var headers = target.headers ?? [:]
            if Session.shared.token.count > 0 {
                headers["Authorization"] = "Bearer \(Session.shared.token)"
            }
            headers["platform"] = "ios"
            headers["appVersion"] = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            var defaultEndpoint = MoyaProvider.defaultEndpointMapping(for: target)
            defaultEndpoint = defaultEndpoint.adding(newHTTPHeaderFields: headers)
            
            // cancel all previous requests same
            //            if let newUrlRequest = try? defaultEndpoint.urlRequest() {
            //                DefaultAlamofireManager.sharedManager.session.getAllTasks(completionHandler: { (tasks) in
            //                    tasks.forEach({ (task) in
            //                        let originalRequest = task.originalRequest
            //                        if originalRequest == newUrlRequest
            //                            && originalRequest?.httpBody == newUrlRequest.httpBody {
            //                            task.cancel()
            //                        }
            //                    })
            //                })
            //            }
            //
            return defaultEndpoint
        }
        
        var plugins: [PluginType] = []
        #if DEBUG
        plugins.append(NetworkLoggerPlugin(verbose: true, responseDataFormatter: JSONResponseDataFormatter))
        #endif
        let provider = MoyaProvider<T>(endpointClosure: endpointClosure,
                                       manager: DefaultAlamofireManager.sharedManager,
                                       plugins: plugins)
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        let cancellable = provider.request(target, completion: { result in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            switch result {
            case let .success(moyaResponse):
                let resp = ApiResponse.init(response: moyaResponse)
                completionHandler(resp)
            case let .failure(error):
                completionHandler(ApiResponse.init(error: error))
            }
        })
        
        return cancellable
    }
    
    func callApi<T: TargetType>(_ target: T) -> Promise<ApiResponse> {
        
        // for adding headers
        let endpointClosure = { (target: T) -> Endpoint in
            var headers = target.headers ?? [:]
            headers["platform"] = "ios"
            if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
                headers["appVersion"] = version
            }
            if Session.shared.token.count > 0 {
                headers["Authorization"] = "Bearer \(Session.shared.token)"
            }
            // authorization
            //            if Session.shared.token.count > 0 {
            //                headers["Authorization"] = "Bearer \(Session.shared.token)"
            //            }
            
            var defaultEndpoint = MoyaProvider.defaultEndpointMapping(for: target)
            defaultEndpoint = defaultEndpoint.adding(newHTTPHeaderFields: headers)
            
            // cancel all previous requests same
            //            if let newUrlRequest = try? defaultEndpoint.urlRequest() {
            //                DefaultAlamofireManager.sharedManager.session.getAllTasks(completionHandler: { (tasks) in
            //                    tasks.forEach({ (task) in
            //                        let originalRequest = task.originalRequest
            //                        if originalRequest == newUrlRequest
            //                            && originalRequest?.httpBody == newUrlRequest.httpBody {
            //                            task.cancel()
            //                        }
            //                    })
            //                })
            //            }
            
            return defaultEndpoint
        }
        var plugins: [PluginType] = []
        #if DEBUG
        plugins.append(NetworkLoggerPlugin(verbose: true, responseDataFormatter: JSONResponseDataFormatter))
        #endif
        let provider = MoyaProvider<T>(endpointClosure: endpointClosure,
                                       manager: DefaultAlamofireManager.sharedManager,
                                       plugins: plugins)
        
        return Promise<ApiResponse> { [weak self](resoler) in
            guard let `self` = self else {return}
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            }
            provider.request(target, completion: { result in
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
                switch result {
                case let .success(moyaResponse):
                    let resp = ApiResponse(response: moyaResponse)
                    if moyaResponse.isUnauthenticated {
                        self.cancelAllRequests()
                        Session.shared.clearUserSession()
                        EventBus.post(.sessionInvalid, userInfo: ["errorCode": JSON(moyaResponse.data)["errorCode"].string ?? "", "messages": JSON(moyaResponse.data)["messages"].string ?? ""])
                        return
                    }
                    if let nsError = resp.error {
                        resoler.reject(nsError)
                    } else {
                        resoler.fulfill(resp)
                    }
                case let .failure(moyaError):
                    switch moyaError {
                    case .underlying(let error, _):
                        let resp = ApiResponse.init(error: error)
                        if let nsError = resp.error {
                            resoler.reject(nsError)
                        } else {
                            resoler.reject(moyaError)
                        }
                    default:
                        resoler.reject(moyaError)
                    }
                }
            })
        }
    }
    
    func suspendAllRequests() {
        DefaultAlamofireManager.sharedManager.session.getAllTasks { tasks in
            tasks.forEach({ (task) in
                task.suspend()
            })
        }
    }
    
    func cancelAllRequests() {
        DefaultAlamofireManager.sharedManager.session.getAllTasks { tasks in
            tasks.forEach({ (task) in
                task.cancel()
            })
        }
    }
    
    func resumeAllRequests() {
        DefaultAlamofireManager.sharedManager.session.getAllTasks { tasks in
            tasks.forEach({ (task) in
                task.resume()
            })
        }
    }
}

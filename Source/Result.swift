//
//  Result.swift
//  RestEssentials
//
//  Created by Sean Kosanovich on 6/7/15.
//  Copyright © 2015 Sean Kosanovich. All rights reserved.
//

import Foundation

public enum Result<T> : BooleanType {
    
    case Success(T)
    case Failure(ErrorType)
    
    public var boolValue: Bool {
        switch(self) {
        case .Success:
            return true
        case .Failure:
            return false
        }
    }
    
    public func value() throws -> T {
        switch(self) {
        case .Success(let value):
            return value
        case .Failure(let error):
            throw error
        }
    }
    
    public func consumeResultForSuccessCallback(successCallback: (data: T) -> (), forErrorCallback errorCallback: (error: ErrorType) -> (), andAlwaysAfter afterCallback: () -> ()) {
        switch self {
        case .Success(let value):
            successCallback(data: value)
        case .Failure(let error):
            errorCallback(error: error)
        }
        afterCallback()
    }
}
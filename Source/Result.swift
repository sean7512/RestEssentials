//
//  Result.swift
//  RestEssentials
//
//  Created by Sean Kosanovich on 6/7/15.
//  Copyright © 2015 Sean Kosanovich. All rights reserved.
//

import Foundation

/// A typed Result with 2 cases: Success or Failure. If an operation was successful, then the resulting data will be encapsulated. If the operation was a failure, then an `ErrorType` will be encapsulated.
public enum Result<T> {

    /// Indicates a successful operation.
    /// - parameter T: The resulting data from the operation.
    case Success(T)

    /// Indicates a failed operation.
    /// - parameter ErrorType: The error from the operation.
    case Failure(ErrorType)

    /// Gets the encapsulated value from the operation.
    ///
    /// - returns: The succesful `T` parameter this result is encapsulating.
    /// - throws: Throws the error if the operation was a failure.
    public func value() throws -> T {
        switch(self) {
        case .Success(let value):
            return value
        case .Failure(let error):
            throw error
        }
    }
}
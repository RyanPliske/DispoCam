//
//  Result.swift
//  CameraApp
//
//  Created by Ryan Pliske on 4/22/15.
//  Copyright (c) 2015 Photojojo. All rights reserved.
//

// import Foundation

/*
final class Box<T> {
    let value: T
    
    init(value: T) {
        self.value = value
    }
}

enum Result<T> {
    case Success(Box<T>)
    case Failure(String)
    
    /*
    func map<P>(f: T -> P) -> Result<P> {
        switch self {
        case Success(let value):
            return .Success(f(value))
        case Failure(let errString):
            return .Failure(errString)
        }
    }
    */
}
*/

enum Result {
    case Success()
    case Failure(String)
    case NetworkFailure()
}
//
//  Result.swift
//  FileBrowser
//
//  Created by Carl Julius Gödecken on 01/01/2017.
//  Copyright © 2017 Carl Julius Gödecken.
//

import Foundation

public enum Result<T> {
    case success(T)
    case error(Error)
}

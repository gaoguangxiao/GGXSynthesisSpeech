//
//  PTLogger.swift
//  PTDebugView
//
//  Created by 高广校 on 2024/7/9.
//

import Foundation
import GGXSwiftExtension

@propertyWrapper
public struct PTLogger {
    
    private let logger: Logger
    
    public init(subsystem: String = kAppBundleId ?? "", category: String = "defaultCategory") {
        self.logger = Logger(subsystem: subsystem, category: category)
    }
    
    public var wrappedValue: Logger {
        return logger
    }
    
}


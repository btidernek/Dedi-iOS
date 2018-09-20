//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

import Foundation

/**
 * We synchronize access to state in this class using this queue.
 */
public func assertOnQueue(_ queue: DispatchQueue) {
    if #available(iOS 10.0, *) {
        dispatchPrecondition(condition: .onQueue(queue))
    } else {
        // Skipping check on <iOS10, since syntax is different and it's just a development convenience.
    }
}

public func owsFail(_ message: String) {
    Logger.error(message)
    Logger.flush()
    assertionFailure(message)
}

public struct Units {
    
    public let bytes: Int64
    
    public var kilobytes: Double {
        return Double(bytes) / 1_024
    }
    
    public var megabytes: Double {
        return kilobytes / 1_024
    }
    
    public var gigabytes: Double {
        return megabytes / 1_024
    }
    
    public init(bytes: Int64) {
        self.bytes = bytes
    }
    
    public func getReadableUnit() -> String {
        
        switch bytes {
        case 0..<1_024:
            return "\(bytes) bytes"
        case 1_024..<(1_024 * 1_024):
            return "\(String(format: "%.2f", kilobytes))KB"
        case 1_024..<(1_024 * 1_024 * 1_024):
            return "\(String(format: "%.2f", megabytes))MB"
        case (1_024 * 1_024 * 1_024)...Int64.max:
            return "\(String(format: "%.2f", gigabytes))GB"
        default:
            return "\(bytes) bytes"
        }
    }
}

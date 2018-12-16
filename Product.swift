//
//  Product.swift
//  SignalServiceKit
//
//  Created by BTK Apple on 16.12.2018.
//

import Foundation

@objcMembers public class Product: NSObject, Codable, NSCoding{
    public let name:String
    public let color:String
    
    override init() {
        self.name = ""
        self.color = ""
        super.init()
    }
    
    init(name:String, color:String) {
        self.name = name
        self.color = color
    }
    
    @objc public func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: "name")
        aCoder.encode(color, forKey: "color")
    }
    
    @objc public required init(coder aDecoder: NSCoder) {
        self.name = aDecoder.decodeObject(forKey: "name") as? String ?? ""
        self.color = aDecoder.decodeObject(forKey: "color") as? String ?? ""
    }
}

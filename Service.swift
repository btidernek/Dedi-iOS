//
//  Service.swift
//  SignalServiceKit
//
//  Created by BTK Apple on 16.12.2018.
//

import Foundation

@objcMembers public class Service: NSObject, Codable{
    @objc public let number:String
    @objc public let product:Product
    
    init(number:String, product:Product) {
        self.number = number
        self.product = product
    }
    
    class public func saveToDefaults(services:[Service]){
        let numbers = services.map({$0.number})
        let names = services.map({$0.product.name})
        UserDefaults.standard.set(numbers, forKey: "serviceNumbers")
        UserDefaults.standard.set(names, forKey: "serviceNames")
        UserDefaults.standard.synchronize()
    }
    
    @objc public static func getServicesFromDefaults() -> [Service]{
        var services = [Service]()
        guard let nums = UserDefaults.standard.stringArray(forKey: "serviceNumbers") else{ return [Service]() }
        guard let names = UserDefaults.standard.stringArray(forKey: "serviceNames") else{ return [Service]() }
        for (num, name) in zip(nums, names) {
            print("\(num) - \(name)")
            let service = Service(number: num, product: Product(name: name, color: ""))
            services.append(service)
        }
        return services
    }
}

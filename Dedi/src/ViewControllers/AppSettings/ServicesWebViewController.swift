//
//  ServicesWebViewController.swift
//  Dedi
//
//  Created by BTK Apple on 12.12.2018.
//  Copyright © 2018 Open Whisper Systems. All rights reserved.
//

import UIKit
import WebKit
import SignalServiceKit

let servicesApiAddress = "http://test.dedi.com.tr/DediServiceWeb/rest/getRemoteProduct"
let servicesWebpageAddress = "http://test.dedi.com.tr/DediServiceWeb/dashboard?phone="

class ServicesWebViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {
    
    var webView: WKWebView!
    fileprivate let staticHTTPHeaderKey = "879+zqw&e134*M00O08552BTider*&a"
    fileprivate lazy var staticApiBody = "{\"data\":\"\(staticHTTPHeaderKey)\"}"
    
    override func loadView() {
        webView = WKWebView()
        webView.navigationDelegate = self
        webView.uiDelegate = self
        view = webView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        loadRequest()
    }
    
    func loadRequest(){
        guard let localNumber = TSAccountManager.localNumber() else{ return }
        getServices()
        let url = URL(string: servicesWebpageAddress + localNumber)!
        var urlRequest = URLRequest(url: url)
        urlRequest.timeoutInterval = 5
        urlRequest.addValue(staticHTTPHeaderKey, forHTTPHeaderField: "code")
        webView.load(urlRequest)
    }
    
    private func addToolbar(){
        let refresh = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(handleRefresh))
        toolbarItems = [refresh]
        navigationController?.isToolbarHidden = false
    }
    
    func setupWebView(){
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        webView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        webView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        webView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
    }
    
    private func getServices(){
        var request = URLRequest(url: URL(string: servicesApiAddress)!)
        request.httpMethod = "POST"
        request.httpBody = staticApiBody.data(using: .utf8)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let safeData = data else { return }
            do{
                let services = try JSONDecoder().decode([Service].self, from: safeData)
                Service.saveToDefaults(services: services)
            }catch let error{
                print("Json parse failed:", error.localizedDescription)
            }
        }.resume()
    }
    
    @objc func handleRefresh(){
        let services = Service.getServicesFromDefaults()
        services.forEach { (service) in
            print(service.number)
            print(service.product.name)
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        title = webView.title
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("didFailProvisionalNavigation")
        showPageLoadFailedError(withRetry: true)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("Web page failed with error:", error.localizedDescription)
        showPageLoadFailedError(withRetry: true)
    }
    
    private func showPageLoadFailedError(withRetry isWithRetry:Bool){
        let retryAction = UIAlertAction(title: NSLocalizedString("RETRY_BUTTON_TEXT", comment: ""), style: .default, handler: { action in self.loadRequest() })
        showAlert(with: NSLocalizedString("ALERT_TITLE_WARNING", comment: ""), and: NSLocalizedString("ERROR_DESCRIPTION_NO_INTERNET", comment: ""), mainAction: isWithRetry ? retryAction : nil)
    }
    
    private func showAlert(with title:String, and body:String, mainAction: UIAlertAction?){
        let alertController = UIAlertController(title: title, message: body, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("TXT_CANCEL_TITLE", comment:
                                                                          ""), style: .cancel, handler: nil))
        if let mainAction = mainAction{
            alertController.addAction(mainAction)
        }
        guard let topMostVC = UIApplication.topMostController() else{ return }
        topMostVC.present(alertController, animated: true, completion: nil)
    }
}

extension UIApplication {
    class func topMostController(controller: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let navigationController = controller as? UINavigationController {
            return topMostController(controller: navigationController.visibleViewController)
        }
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topMostController(controller: selected)
            }
        }
        if let presented = controller?.presentedViewController {
            return topMostController(controller: presented)
        }
        return controller
    }
}

extension UIColor{
    static func rgb(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat) -> UIColor{
        return UIColor(red: red/255, green: green/255, blue: blue/255, alpha: 1.0)
    }
    
    convenience init(rgb: Int) {
        let color = UIColor.rgb(CGFloat((rgb >> 16) & 0xFF), CGFloat((rgb >> 8) & 0xFF), CGFloat(rgb & 0xFF))
        self.init(cgColor: color.cgColor)
    }
}

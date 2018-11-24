//
//  SKActivityIndicator.swift
//  Dedi
//
//  Created by BTK Apple on 17.11.2018.
//  Copyright © 2018 Open Whisper Systems. All rights reserved.
//

import UIKit

class SKActivityIndicator: UIView {
    
    private let activityIndicator: UIActivityIndicatorView = {
        let aiView = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        aiView.startAnimating()
        aiView.translatesAutoresizingMaskIntoConstraints = false
        return aiView
    }()
    
    private let activityIndicatorWrapper:UIView = {
        let view = UIView()
        view.layer.cornerRadius = 16
        view.clipsToBounds = true
        view.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let bottomHalf: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("TXT_CANCEL_TITLE", comment: ""), for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        button.layer.cornerRadius = 8
        button.clipsToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.black.withAlphaComponent(0.25)
        translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(activityIndicatorWrapper)
        setupWrapper()
        
        addSubview(bottomHalf)
        setupBottomHalf()
        
        isHidden = true
        
    }
    
    private func setupBottomHalf(){
        [bottomHalf.topAnchor.constraint(equalTo: centerYAnchor),
        bottomHalf.bottomAnchor.constraint(equalTo: bottomAnchor),
        bottomHalf.leadingAnchor.constraint(equalTo: leadingAnchor),
        bottomHalf.trailingAnchor.constraint(equalTo: trailingAnchor)].forEach({$0.isActive = true})
        
        bottomHalf.addSubview(cancelButton)
        
        [cancelButton.centerXAnchor.constraint(equalTo: bottomHalf.centerXAnchor),
        cancelButton.centerYAnchor.constraint(equalTo: bottomHalf.centerYAnchor),
        cancelButton.widthAnchor.constraint(equalToConstant: 120),
        cancelButton.heightAnchor.constraint(equalToConstant: 45)].forEach({$0.isActive = true})
    }
    
    private func setupWrapper(){
        [activityIndicatorWrapper.centerXAnchor.constraint(equalTo: centerXAnchor),
        activityIndicatorWrapper.centerYAnchor.constraint(equalTo: centerYAnchor),
        activityIndicatorWrapper.widthAnchor.constraint(equalToConstant: 80),
        activityIndicatorWrapper.heightAnchor.constraint(equalToConstant: 80)].forEach({$0.isActive = true})
        
        activityIndicatorWrapper.addSubview(activityIndicator)
        setupActivityIndicator()
    }
    
    private func setupActivityIndicator(){
        [activityIndicator.centerXAnchor.constraint(equalTo: activityIndicatorWrapper.centerXAnchor),
         activityIndicator.centerYAnchor.constraint(equalTo: activityIndicatorWrapper.centerYAnchor),
         activityIndicator.widthAnchor.constraint(equalToConstant: 40),
         activityIndicator.heightAnchor.constraint(equalToConstant: 40)].forEach({$0.isActive = true})
    }
    
    public func startAnimating(){
        guard let mainWindow = UIApplication.shared.keyWindow else { return }
        mainWindow.addSubview(self)
        
        [centerXAnchor.constraint(equalTo: mainWindow.centerXAnchor),
         centerYAnchor.constraint(equalTo: mainWindow.centerYAnchor),
         widthAnchor.constraint(equalTo: mainWindow.widthAnchor),
         heightAnchor.constraint(equalTo: mainWindow.heightAnchor)].forEach({$0.isActive = true})
        
        isHidden = false
        activityIndicator.startAnimating()
    }
    
    public func stopAnimating(){
        isHidden = true
        activityIndicator.stopAnimating()
        removeFromSuperview()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

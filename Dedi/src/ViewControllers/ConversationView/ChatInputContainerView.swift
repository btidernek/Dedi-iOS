//
//  ChatInputContainerView.swift
//  GameOfChats
//
//  Created by btider-salih on 3.11.2018.
//  Copyright © 2018 btider-salih. All rights reserved.
//

import UIKit

class ChatInputContainerView: UIView, UITextViewDelegate {
    
    static let maximumContainerHeight:CGFloat = 100.0
    
    let sendButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(
            NSLocalizedString("SEND_BUTTON_TITLE", comment: "Label for the send button in the conversation view."),
            for: .normal)
        button.setTitleColor(UIColor(r: 60, g: 140, b: 230), for: .normal)
        button.setTitleColor(UIColor.lightGray, for: .disabled)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        button.isEnabled = false
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    lazy var messageTextView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isScrollEnabled = false
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.delegate = self
        return textView
    }()
    
    let uploadImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "btnAttachments--blue")
        imageView.isUserInteractionEnabled = true
        imageView.contentMode = .center
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    fileprivate let placeholder = NSLocalizedString("new_message", comment: "")
    
    fileprivate var messageViewHeightAnchor: NSLayoutConstraint?
    
    override var intrinsicContentSize: CGSize {
        // Calculate intrinsicContentSize that will fit all the text
        
        guard let heightAnchor = messageViewHeightAnchor else{ return CGSize(width: bounds.width, height: 50) }
        return CGSize(width: bounds.width, height: heightAnchor.constant + 6)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.white
        
        setupInputContainerTopSeperator()
        setupSendButton()
        setupUploadImageView()
        setupMessageTextField()
        self.textViewDidChange(messageTextView)
    }
    
    func setupSendButton(){
        addSubview(sendButton)
        sendButton.rightAnchor.constraint(equalTo: rightAnchor, constant: -8).isActive = true
        sendButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        sendButton.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.2).isActive = true
        sendButton.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
    }
    
    func setupMessageTextField(){
        addSubview(messageTextView)
        messageTextView.rightAnchor.constraint(equalTo: sendButton.leftAnchor, constant: 4).isActive = true
        //messageTextView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        //messageTextView.topAnchor.constraint(equalTo: topAnchor, constant: 6).isActive = true
        messageTextView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor, constant: -6).isActive = true
        messageTextView.leftAnchor.constraint(equalTo: uploadImageView.rightAnchor, constant: 8).isActive = true
        messageViewHeightAnchor = messageTextView.heightAnchor.constraint(equalToConstant: 50)
        messageViewHeightAnchor?.isActive = true
    }
    
    func setupUploadImageView(){
        addSubview(uploadImageView)
        uploadImageView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        uploadImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        uploadImageView.widthAnchor.constraint(equalToConstant: 44).isActive = true
        uploadImageView.heightAnchor.constraint(equalToConstant: 44).isActive = true
    }
    
    func setupInputContainerTopSeperator(){
        // Top Seperator View
        let seperator = UIView()
        seperator.translatesAutoresizingMaskIntoConstraints = false
        seperator.backgroundColor = UIColor(r: 235, g: 235, b: 235)
        
        addSubview(seperator)
        seperator.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        seperator.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        seperator.topAnchor.constraint(equalTo: topAnchor).isActive = true
        seperator.heightAnchor.constraint(equalToConstant: 1).isActive = true
    }
    
    func adjustHeight(of textView:UITextView){
        let size = CGSize(width: textView.frame.width, height: .infinity)
        let estimatedSize = textView.sizeThatFits(size)
        guard let heightAnchor = messageViewHeightAnchor else{ return }
        if estimatedSize.height < ChatInputContainerView.maximumContainerHeight{
            textView.isScrollEnabled = false
            heightAnchor.constant = estimatedSize.height
        }else{
            heightAnchor.constant = ChatInputContainerView.maximumContainerHeight
            textView.isScrollEnabled = true
        }
    }

    
    func textViewDidChange(_ textView: UITextView) {
        
        adjustHeight(of: textView)
        
        guard let messageBody = messageTextView.text?.stripped else {
            animateEnable(of: sendButton, with:{self.sendButton.isEnabled = false})
            return
        }
        if messageBody == "" || messageBody == placeholder{
            animateEnable(of: sendButton, with:{self.sendButton.isEnabled = false})
            return
        }
        animateEnable(of: sendButton, with: {self.sendButton.isEnabled = true})
    }
    
    func animateEnable(of button: UIButton, with block:(() -> Void)?){
        UIView.transition(with: button,
                          duration: 0.25,
                          options: .transitionCrossDissolve,
                          animations: block,
                          completion: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension UIColor{
    convenience init(r:CGFloat, g:CGFloat, b:CGFloat){
        self.init(red: r/255, green: g/255, blue: b/255, alpha: 1.0)
    }
}

extension String {
    
    func frameSize(maxWidth: CGFloat, font: UIFont) -> CGRect {
        
        let textStorage = NSTextStorage(string: self)
        let textContainer = NSTextContainer(size: CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude))
        let layoutManager = NSLayoutManager()
        
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        
        textStorage.addAttribute(.font, value: font, range: NSMakeRange(0, textStorage.length))
        textContainer.lineFragmentPadding = 0.0
        
        layoutManager.glyphRange(for: textContainer)
        let size = layoutManager.usedRect(for: textContainer)
        return CGRect(x: size.origin.x, y: size.origin.y, width: ceil(size.width), height: ceil(size.height))
    }
}

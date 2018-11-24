//
//  BulkConversationViewController.swift
//  Dedi
//
//  Created by BTK Apple on 6.11.2018.
//  Copyright © 2018 Open Whisper Systems. All rights reserved.
//

import UIKit
import SignalServiceKit
import PromiseKit

class BulkConversationViewController: UIViewController {
    
    @objc var recipientIdsForBulkMessage: [String]?
    @objc var messageSender: MessageSender?
    
    var isPickingMediaAsDocument = false
    var locationManager = ShareLocationManager()
    let hud = SKActivityIndicator()
    var contactsManager: OWSContactsManager?
    
    lazy var inputContainerView: ChatInputContainerView = {
        let containerView = ChatInputContainerView()
        //frame: CGRect(x: 0, y: 0, width: 100, height: 50)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.sendButton.addTarget(self, action: #selector(sendTextMessage), for: .touchUpInside)
        containerView.uploadImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleMediaTapped)))
        return containerView
    }()
    
    lazy var bannerView: UIView = {
        let bView = UIView()
        bView.layer.cornerRadius = 8
        bView.backgroundColor = UIColor(r: 27, g: 120, b: 210)
        
        //Shadow properties
        bView.layer.shadowColor = UIColor.black.cgColor
        bView.layer.shadowOpacity = 0.4
        bView.layer.shadowOffset = CGSize.zero
        bView.layer.shadowRadius = 2

        
        bView.translatesAutoresizingMaskIntoConstraints = false
        return bView
    }()
    
    lazy var bannerDescLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 15)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let bannerHeaderLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.textAlignment = .center
        label.text = NSLocalizedString("BULK_MESSAGE_SELECTED_CONTACTS", comment: "").uppercased(with: Locale.current)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = NSLocalizedString("NEW_BULK_MESSAGE_TITLE", comment: "")
        self.view.backgroundColor = .white
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard)))
        
        inputContainerView.topAnchor.constraint(equalTo: inputContainerView.messageTextView.topAnchor, constant: -6).isActive = true
        hud.cancelButton.addTarget(self, action: #selector(handleHudCancelTapped), for: .touchUpInside)
        
        contactsManager = Environment.current()?.contactsManager
        contactsManager?.requestSystemContactsOnce()
        setupBannerView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        inputContainerView.messageTextView.becomeFirstResponder()
    }
    
    func setupBannerView(){
        view.addSubview(bannerView)
        view.addSubview(bannerHeaderLabel)
        view.addSubview(bannerDescLabel)
        
        [bannerHeaderLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 30),
         bannerHeaderLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0),
         bannerHeaderLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
         bannerHeaderLabel.heightAnchor.constraint(equalToConstant: 24),
         bannerDescLabel.topAnchor.constraint(equalTo: bannerHeaderLabel.bottomAnchor, constant: 4),
         bannerDescLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0),
         bannerDescLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
         bannerDescLabel.heightAnchor.constraint(lessThanOrEqualTo: view.heightAnchor, multiplier: 0.6),
         bannerView.topAnchor.constraint(equalTo: bannerHeaderLabel.topAnchor, constant: -8),
         bannerView.bottomAnchor.constraint(equalTo: bannerDescLabel.bottomAnchor, constant: 8),
         bannerView.leadingAnchor.constraint(equalTo: bannerDescLabel.leadingAnchor, constant: -8),
         bannerView.trailingAnchor.constraint(equalTo: bannerDescLabel.trailingAnchor, constant: 8)].forEach({$0.isActive = true})
        
        var allNamesCombined = ""
        guard let idList = self.recipientIdsForBulkMessage else{ return }
        idList.forEach({
            if let name = self.contactsManager?.displayName(forPhoneIdentifier: $0){
                allNamesCombined.append(name)
            }else{
                allNamesCombined.append($0)
            }
            if $0 != idList.last{
                allNamesCombined.append(", ")
            }
        })
        bannerDescLabel.text = allNamesCombined
    }
    
    override var inputAccessoryView: UIView? {
        get {
            return inputContainerView
        }
    }
    
    override var canBecomeFirstResponder: Bool{
        return true
    }
    
    @objc func sendTextMessage(){
        sendTextMessageWith(messageString: nil)
    }
    
    @objc func handleHudCancelTapped(){
        finishSendingBulkMessage()
    }
    
    @objc func sendTextMessageWith(messageString:String?){
        var messageBody = ""
        if let string = messageString{
            messageBody = string
        }else{
            guard let string = inputContainerView.messageTextView.text?.stripped else { return }
            messageBody = string
        }
        
        if messageBody == ""{
            return
        }
        
        Timer.scheduledTimer(timeInterval: 0.1,
                                   target: self,
                                 selector: #selector(startSendingToRecipients(timer:)),
                                 userInfo: messageBody,
                                  repeats: true)
    }
    
    @objc func startSendingToRecipients(timer:Timer){
        dismissKeyboardOnBackground()
        inputAccessoryView?.isHidden = true
        hud.startAnimating()
        
        guard var recipientIds = self.recipientIdsForBulkMessage else{
            finishSendingBulkMessage()
            return
        }
        if recipientIds.count > 0 {
            guard let recipientId = recipientIds.last else{ return }
            
            if let messageBody = timer.userInfo as? String{
                messageBody.lengthOfBytes(using: .utf8) >= kOversizeTextMessageSizeThreshold ?
                    self.sendOversizeText(to: recipientId, with: messageBody) : self.sendRegularTextMessage(to: recipientId, with: messageBody)
            }else if let attachment = timer.userInfo as? SignalAttachment{
                self.sendAttachmentMessage(to: recipientId, with: attachment)
               print("=====Attachment has sent=====")
            }else if let contact = timer.userInfo as? OWSContact{
                self.sendContactMessage(to: recipientId, with: contact)
                print("=====Contact has sent=====")
            }else{
                recipientIds.removeAll()
                timer.invalidate()
                finishSendingBulkMessage()
            }
            
            self.recipientIdsForBulkMessage?.removeLast()
        }else{
            timer.invalidate()
            self.finishSendingBulkMessage()
        }
        
    }
    
    func sendContactMessage(to recipientId:String, with contact:OWSContact){
        guard let sender = self.messageSender else{ return }
        let contactThread = TSContactThread.getOrCreateThread(contactId: recipientId)
        ThreadUtil.sendMessage(withContactShare: contact, in: contactThread, messageSender: sender) { (error) in
            if let err = error{
                print(err.localizedDescription)
                return
            }
        }
    }
    
    func sendAttachmentMessage(to recipientId:String, with attachment:SignalAttachment){
        guard let sender = self.messageSender else{ return }
        let contactThread = TSContactThread.getOrCreateThread(contactId: recipientId)
        ThreadUtil.sendMessage(with: attachment, in: contactThread, quotedReplyModel: nil, messageSender: sender) { (error) in
            if let err = error{
                print(err.localizedDescription)
                return
            }
        }
    }
    
    func sendOversizeText(to recipientId:String, with messageBody:String){
        guard let sender = self.messageSender else{ return }
        let dataSource = DataSourceValue.dataSource(withOversizeText: messageBody)
        let attachment = SignalAttachment.attachment(dataSource: dataSource, dataUTI: kOversizeTextAttachmentUTI)
        let contactThread = TSContactThread.getOrCreateThread(contactId: recipientId)
        ThreadUtil.sendMessage(with: attachment, in: contactThread, quotedReplyModel: nil, messageSender: sender) { (error) in
            if let err = error{
                print(err.localizedDescription)
                return
            }
            
        }
    }
    
    func sendRegularTextMessage(to recipientId:String, with messageBody:String){
        guard let sender = self.messageSender else{ return }
        let contactThread = TSContactThread.getOrCreateThread(contactId: recipientId)
        ThreadUtil.sendMessage(withText: messageBody, in: contactThread, quotedReplyModel: nil, messageSender: sender, success: {
            print("Sending bulk message resulted successfully")
            
        }) { (error) in
            print("Sending bulk text message failed:", error.localizedDescription)
        }
    }
    
    func finishSendingBulkMessage(){
        self.dismissKeyboard()
        self.hud.stopAnimating()
//        self.inputAccessoryView?.isHidden = false
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func dismissKeyboard(){
        DispatchQueue.main.async {
            self.inputContainerView.messageTextView.resignFirstResponder()
        }
    }
    
    @objc func dismissKeyboardOnBackground(){
        self.inputContainerView.messageTextView.resignFirstResponder()
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("imagePickerControllerDidCancel")
        dismiss(animated: true, completion: nil)
    }
    
    class func delay(_ delay:Double, closure:@escaping ()->()) {
        DispatchQueue.main.asyncAfter(
            deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
    }
}

// MARK: Media operations and callback
extension BulkConversationViewController: UIDocumentPickerDelegate, UIDocumentMenuDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    @objc func handleMediaTapped(){
        
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.addAction(OWSAlerts.cancelAction)
        
        
        let takeMediaTitle = NSLocalizedString("MEDIA_FROM_CAMERA_BUTTON", comment: "media picker option to take photo or video")
        let takeMediaAction = UIAlertAction(title: takeMediaTitle,
                                            style: .default, handler: { (action) in
                                                self.chooseMediaTapped(sourceType: .camera)
        })
        takeMediaAction.setValue(UIImage(named: "actionsheet_camera_black"), forKey: "image")
        actionSheet.addAction(takeMediaAction)
        
        
        let chooseMediaTitle = NSLocalizedString("MEDIA_FROM_LIBRARY_BUTTON", comment: "media picker option to choose from library")
        let chooseMediaAction = UIAlertAction(title: chooseMediaTitle,
                                              style: .default, handler: { (action) in
                                                self.chooseMediaTapped(sourceType: .photoLibrary)
        })
        chooseMediaAction.setValue(UIImage(named: "actionsheet_camera_roll_black"), forKey: "image")
        actionSheet.addAction(chooseMediaAction)
        
        
//        let chooseDocumentTitle = NSLocalizedString("MEDIA_FROM_DOCUMENT_PICKER_BUTTON", comment: "action sheet button title when choosing attachment type")
//        let chooseDocumentAction = UIAlertAction(title: chooseDocumentTitle,
//                                                 style: .default, handler: { (action) in
//                                                    self.showAttachmentDocumentPickerMenu()
//        })
//        chooseDocumentAction.setValue(UIImage(named: "actionsheet_document_black"), forKey: "image")
//        actionSheet.addAction(chooseDocumentAction)
        
        
        let chooseContactTitle = NSLocalizedString("ATTACHMENT_MENU_CONTACT_BUTTON", comment: "attachment menu option to send contact")
        let chooseContactAction = UIAlertAction(title: chooseContactTitle,
                                                style: .default, handler: { (action) in
                                                    self.chooseContactForSending()
        })
        chooseContactAction.setValue(UIImage(named: "actionsheet_contact"), forKey: "image")
        actionSheet.addAction(chooseContactAction)
        
        
        let sendLocationTitle = NSLocalizedString("MEDIA_CURRENT_LOCATION_BUTTON", comment: "share location option to send current location")
        let sendLocationAction = UIAlertAction(title: sendLocationTitle,
                                               style: .default, handler: { (action) in
                                                self.checkForLatestLocationSentDate()
        })
        sendLocationAction.setValue(UIImage(named: "actionsheet_location"), forKey: "image")
        actionSheet.addAction(sendLocationAction)
        
        
        
        self.dismissKeyboardOnBackground()
        present(actionSheet, animated: true, completion: nil)
    }
    
    // MARK: Actionsheet Media Actions
    func showAttachmentDocumentPickerMenu(){
        let menuController = UIDocumentMenuViewController(documentTypes: [kUTTypeItem] as [String], in: .import)
        menuController.delegate = self
        
        let title = NSLocalizedString("MEDIA_FROM_LIBRARY_BUTTON", comment: "media picker option to choose from library")
        menuController.addOption(withTitle: title, image: UIImage(named: "actionsheet_camera_black"),
                                 order: .first) {
                                    self.chooseFromLibraryAsDocument()
        }
        self.dismissKeyboardOnBackground()
        present(menuController, animated: true, completion: nil)
    }
    
    func chooseMediaTapped(sourceType:UIImagePickerControllerSourceType){
        self.chooseFromLibraryAsDocument(shouldTreatAsDocument: false, sourceType:sourceType)
    }
    
    func chooseFromLibraryAsDocument(){
        self.chooseFromLibraryAsDocument(shouldTreatAsDocument: true, sourceType:nil)
    }
    
    func chooseFromLibraryAsDocument(shouldTreatAsDocument:Bool, sourceType:UIImagePickerControllerSourceType?){
        self.isPickingMediaAsDocument = shouldTreatAsDocument
        if let type = sourceType, type == .camera{
            self.ows_ask(forCameraPermissions: { (granted) in
                if !granted{
                    print("Camera permission denied.")
                    return
                }
                self.dismissKeyboardOnBackground()
                
                self.presentPicker(with: .camera)
            })
        }else if let type = sourceType, type == .photoLibrary{
            self.ows_ask(forMediaLibraryPermissions: { (granted) in
                if !granted{
                    print("Camera permission denied.")
                    return
                }
                self.dismissKeyboardOnBackground()
                
                self.presentPicker(with: .photoLibrary)
            })
        }else{
            presentPicker(with: nil)
        }
    }
    
    func presentPicker(with sourceType:UIImagePickerControllerSourceType?){
        let picker = UIImagePickerController()
        picker.delegate = self
        //picker.allowsEditing = true
        picker.mediaTypes = [kUTTypeImage, kUTTypeMovie] as [String]
        if let type = sourceType{
            picker.sourceType = type
        }
        self.present(picker, animated: true, completion: nil)
    }
    
    // MARK: Document Menu Delegate
    func documentMenu(_ documentMenu: UIDocumentMenuViewController, didPickDocumentPicker documentPicker: UIDocumentPickerViewController) {
        print("Not implemented")
    }
    
    // MARK: Image Picker Delegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let videoUrl = info[UIImagePickerControllerMediaURL] as? URL{
            handleVideoAsset(with: nil, and: videoUrl)
            
        }else{
            // Image selected from library
            handleImageSelected(forInfo: info)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func handleVideoAsset(with filename:String?, and mediaUrl:URL){
        DispatchQueue.main.async {
            self.sendQualityAdjustedAttachment(for: mediaUrl, and: filename)
        }
    }
    
    func sendQualityAdjustedAttachment(for videoUrl:URL, and filename:String?){
        SwiftAssertIsOnMainThread(#function)
        guard let dataSource = DataSourcePath.dataSource(with: videoUrl) else{
            print("Video compression failed")
            return
        }
        dataSource.sourceFilename = filename
        
        let compressionResult = SignalAttachment.compressVideoAsMp4(dataSource: dataSource, dataUTI: kUTTypeMPEG4 as String) as (Promise<SignalAttachment>, AVAssetExportSession?)
        compressionResult.0.retainUntilComplete()
        compressionResult.0.then { (attachment) -> Void in
            SwiftAssertIsOnMainThread(#function)
            assert(attachment.isKind(of: SignalAttachment.self))
            let isLowDataOn = UserDefaults.standard.bool(forKey: "IS_LOW_DATA_MODE_ON")
            let maxVideoSize = isLowDataOn ? SignalAttachment.kMaxFileSizeVideoIfLowDataEnabled : SignalAttachment.kMaxFileSizeVideo
            let alertMessage = isLowDataOn ? "MAX_VIDEO_SIZE_FOR_LOW_DATA_ALERT_MESSAGE" : "MAX_VIDEO_SIZE_ALERT_MESSAGE"
            if attachment.hasError{
                print("Attachmet has errors", attachment.errorName ?? "Error creating attachment")
                self.showErrorAlertFor(attachment: attachment)
            }else if attachment.dataLength > maxVideoSize{
                //-BTIDER UPDATE- Low Data Mode for Videos
                let controller = UIAlertController(title: NSLocalizedString("MAX_VIDEO_SIZE_ALERT_TITLE", comment: "Alert title for video size"),
                                                   message: NSLocalizedString(alertMessage, comment: "Alert message for video size"),
                                                   preferredStyle: .alert)
                controller.addAction(UIAlertAction(title: NSLocalizedString("BUTTON_DONE", comment: "Done"), style: .default, handler: nil))
                self.present(controller, animated: true, completion: nil)
            }else{
                Timer.scheduledTimer(timeInterval: 0.1,
                                     target: self,
                                     selector: #selector(self.startSendingToRecipients(timer:)),
                                     userInfo: attachment,
                                     repeats: true)
            }
        }
    }
    
    func showErrorAlertFor(attachment:SignalAttachment){
        
        var errorMessage = ""
        if let desc = attachment.localizedErrorDescription{
            errorMessage = desc
        }else{
            errorMessage = SignalAttachment.missingDataErrorMessage
        }
        
        print("Attachment has error:", #function ,errorMessage)
        
        OWSAlerts.showAlert(title: NSLocalizedString("ATTACHMENT_ERROR_ALERT_TITLE", comment: "The title of the 'attachment error' alert."),
                            message: errorMessage)
    }
    
    private func handleImageSelected(forInfo info:[String : Any]){
        var selectedImage: UIImage?
        
        if let editedImage = info[UIImagePickerControllerEditedImage] as? UIImage{
            selectedImage = editedImage
        }else if let originalImage = info[UIImagePickerControllerOriginalImage] as? UIImage{
            selectedImage = originalImage
        }
        
        if let image = selectedImage{
            guard let attachment = convertImageToAttachment(image: image, filename: nil) else{ return }
            Timer.scheduledTimer(timeInterval: 0.1,
                                       target: self,
                                     selector: #selector(startSendingToRecipients(timer:)),
                                     userInfo: attachment,
                                      repeats: true)
        }
    }
}

extension BulkConversationViewController: ContactsPickerDelegate, ContactShareApprovalViewControllerDelegate{
    
    // MARK: Handler
    func chooseContactForSending(){
        let contactsPicker = ContactsPicker(allowsMultipleSelection: false, subtitleCellType: .none)
        contactsPicker.contactsPickerDelegate = self
        contactsPicker.title = NSLocalizedString("CONTACT_PICKER_TITLE", comment: "navbar title for contact picker when sharing a contact")
        let navController = OWSNavigationController(rootViewController: contactsPicker)
        self.dismissKeyboard()
        present(navController, animated: true, completion: nil)
    }
    
    func sendContactShare(contactShare:ContactShareViewModel){
        SwiftAssertIsOnMainThread(#function)
        print("BulkConversationViewController: Sending contact share.")
        
        Timer.scheduledTimer(timeInterval: 0.1,
                             target: self,
                             selector: #selector(startSendingToRecipients(timer:)),
                             userInfo: contactShare.dbRecord,
                             repeats: true)
    }
    
    // MARK: ContactShareApprovalViewControllerDelegate
    func approveContactShare(_ approveContactShare: ContactShareApprovalViewController, didApproveContactShare contactShare: ContactShareViewModel) {
        print("BulkConversationViewController: didApproveContactShare.")
        dismiss(animated: true) {
            self.sendContactShare(contactShare: contactShare)
        }
    }
    
    func approveContactShare(_ approveContactShare: ContactShareApprovalViewController, didCancelContactShare contactShare: ContactShareViewModel) {
        print("BulkConversationViewController: didCancelContactShare.")
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: ContactsPickerDelegate
    func contactsPicker(_: ContactsPicker, contactFetchDidFail error: NSError) {
        print("BulkConversationViewController: contactFetchDidFail:", error.localizedDescription)
        dismiss(animated: true, completion: nil)
    }
    
    func contactsPickerDidCancel(_: ContactsPicker) {
        print("BulkConversationViewController: contactsPickerDidCancel")
        dismiss(animated: true, completion: nil)
    }
    
    func contactsPicker(_ contactsPicker: ContactsPicker, didSelectContact contact: Contact) {
        guard let cManager = contactsManager else{ return }
        
        guard let cnContact = cManager.cnContact(withId: contact.cnContactId) else {
            owsFail("BulkConversationViewController: Could not load system contact.")
            return
        }
        
        guard let contactShareRecord = OWSContacts.contact(forSystemContact: cnContact) else {
            owsFail("BulkConversationViewController: Could not convert system contact.")
            return
        }
        
        var isProfileAvatar = false
        var avatarImageData = cManager.avatarData(forCNContactId: cnContact.identifier)
        for recipientId in contact.textSecureIdentifiers(){
            if avatarImageData != nil{
                break
            }
            
            avatarImageData = cManager.profileImageData(forPhoneIdentifier: recipientId)
            if avatarImageData != nil{
                isProfileAvatar = true
            }
        }
        contactShareRecord.isProfileAvatar = isProfileAvatar
        let contactShare = ContactShareViewModel(contactShareRecord: contactShareRecord, avatarImageData: avatarImageData)
        
        let approveContactShare = ContactShareApprovalViewController(contactShare: contactShare, contactsManager: cManager, delegate: self)
        assert(contactsPicker.navigationController != nil)
        contactsPicker.navigationController?.pushViewController(approveContactShare, animated: true)
        
//        ContactShareApprovalViewController *approveContactShare =
//            [[ContactShareApprovalViewController alloc] initWithContactShare:contactShare
//                contactsManager:self.contactsManager
//                delegate:self];
//        OWSAssert(contactsPicker.navigationController);
//        [contactsPicker.navigationController pushViewController:approveContactShare animated:YES];
    }
    
    func contactsPicker(_: ContactsPicker, didSelectMultipleContacts contacts: [Contact]) {
        print("BulkConversationViewController: didSelectMultipleContacts")
        dismiss(animated: true, completion: nil)
    }
    
    func contactsPicker(_: ContactsPicker, shouldSelectContact contact: Contact) -> Bool {
        return true
    }
    
    
}

// MARK: Location operations and callback
extension BulkConversationViewController{
    //-BTIDER UPDATE- Send Location Added
    func sendLocation() {
        
        self.locationManager.completionHandler = {
            self.callbackLocationFinished()
        }
        self.locationManager.requestCurrentLocation()
    }
    
    //-BTIDER UPDATE- Send Location Added
    func checkForLatestLocationSentDate(){
        let now = Date()
        if let latestLocationSent = UserDefaults.standard.object(forKey: "LATEST_LOCATION_SENT_DATE") as? Date{
            if fabs(now.timeIntervalSince(latestLocationSent)) > 3{
                UserDefaults.standard.set(now, forKey: "LATEST_LOCATION_SENT_DATE")
                UserDefaults.standard.synchronize()
                self.sendLocation()
            }else{
                let localizedTitle = NSLocalizedString("LOCATION_SEND_FREQUENCY_WARNING_TITLE", comment: "Warning title for location sending interval (3 seconds)")
                let localizedMessage = NSLocalizedString("LOCATION_SEND_FREQUENCY_WARNING_DESCRIPTION", comment: "Warning description for location sending interval")
                let controller = UIAlertController(title: localizedTitle, message: localizedMessage, preferredStyle: .alert)
                controller.addAction(UIAlertAction(title: NSLocalizedString("BUTTON_DONE", comment: "Done"), style: .default, handler: nil))
                present(controller, animated: true, completion: nil)
            }
        }else{
            UserDefaults.standard.set(now, forKey: "LATEST_LOCATION_SENT_DATE")
            UserDefaults.standard.synchronize()
            self.sendLocation()
        }
    }
    
    func callbackLocationFinished(){
        let locationImage = self.locationManager.image
        let messageBody = self.locationManager.message
        
        guard let body = messageBody else{
            print("Sending location failed.")
            return
        }
        
        if let image = locationImage{
            let filenameUUID = "location-" + NSUUID().uuidString
            if let attachment = convertImageToAttachment(image: image, filename: filenameUUID){
                attachment.captionText = body
            }else{
                self.sendTextMessageWith(messageString: body)
            }
        }else{
            sendTextMessageWith(messageString: body)
        }
    }
    
    func convertImageToAttachment(image:UIImage, filename:String?) -> SignalAttachment? {
        let isLowDataOn = UserDefaults.standard.bool(forKey: "IS_LOW_DATA_MODE_ON")
        let quality = isLowDataOn ? TSImageQuality.compact : TSImageQuality.medium
        let attachment = SignalAttachment.imageAttachment(image: image, dataUTI: kUTTypeJPEG as String, filename: filename, imageQuality: quality)
        if (attachment.hasError){
            print("Invalid attachment:", attachment.errorName ?? "Missing data")
            return nil
        }else{
            return attachment
        }
    }
}

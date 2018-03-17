//
//  ShareViewController.swift
//  silverblog_share
//
//  Created by 黄江华 on 2018/3/15.
//  Copyright © 2018年 qwe7002. All rights reserved.
//

import UIKit
import Social
import Alamofire

class ShareViewController: SLComposeServiceViewController {
    let shared = UserDefaults(suiteName: "group.silverblog")!
    var post_title = "No Title"
    var sulg = ""
    override func isContentValid() -> Bool {
        if(contentText.isEmpty){
            return false
        }
        if(shared.string(forKey: "server")?.isEmpty)!{
            return false
        }
        // Do validation of contentText and/or NSExtensionContext attachments here
        return true
    }

    override func didSelectPost() {
        // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
        var sign = md5(post_title+shared.string(forKey: "password"))

        let parameters : Parameters = [
            "title":post_title,
            "sign":sign,
            "content":contentText,
            "name":sulg
        ]
        Alamofire.request(shared.string(forKey: "server")+"/control/new", method: .post, parameters: parameters, encoding: JSONEncoding.default).validate().responseJSON { response in
            switch response.result {
            case .success:
                print("Validation Successful")
            case .failure(let error):
                print(error)
            }
        }

        // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }

    override func configurationItems() -> [Any]! {
        // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
        return [title_item,sulg_item]
    }

    lazy var title_item: SLComposeSheetConfigurationItem = {
        let item = SLComposeSheetConfigurationItem()!
        item.title = "Title"
        item.value = "No Title"
        item.tapHandler={
            let alert = UIAlertController(title:"Please enter a title:",message:"",preferredStyle:.alert)
            alert.addTextField(configurationHandler: {(textField)in
                textField.placeholder="Title"
                textField.keyboardType = .default
            })
            let cancel=UIAlertAction(title:"Cancel",style:.cancel)
            let confirm=UIAlertAction(title:"Ok",style:.default){(action)in
                let textField = alert.textFields![0] // Force unwrapping because we know it exists.
                item.value=textField.text
                self.post_title=textField.text!
            }
            alert.addAction(cancel)
            alert.addAction(confirm)
            self.present(alert, animated: true, completion: nil)
        }
        return item
    }()
    lazy var sulg_item: SLComposeSheetConfigurationItem = {
        let item = SLComposeSheetConfigurationItem()!
        item.title = "Slug"
        item.value = ""
        item.tapHandler={
            let alert = UIAlertController(title:"Please enter a sulg:",message:"",preferredStyle:.alert)
            alert.addTextField(configurationHandler: {(textField)in
                textField.placeholder="Title"
                textField.keyboardType = .default
            })
            let cancel=UIAlertAction(title:"Cancel",style:.cancel)
            let confirm=UIAlertAction(title:"Ok",style:.default){(action)in
                let textField = alert.textFields![0] // Force unwrapping because we know it exists.
                item.value=textField.text
                self.sulg=textField.text!
                //print("Text field: \(textField.text)")
            }
            alert.addAction(cancel)
            alert.addAction(confirm)
            self.present(alert, animated: true, completion: nil)
        }
        return item
    }()
    func md5(_ string: String) -> String {

        let context = UnsafeMutablePointer<CC_MD5_CTX>.allocate(capacity: 1)
        var digest = Array<UInt8>(repeating:0, count:Int(CC_MD5_DIGEST_LENGTH))
        CC_MD5_Init(context)
        CC_MD5_Update(context, string, CC_LONG(string.lengthOfBytes(using: String.Encoding.utf8)))
        CC_MD5_Final(&digest, context)
        context.deallocate(capacity: 1)
        var hexString = ""
        for byte in digest {
            hexString += String(format:"%02x", byte)
        }

        return hexString
    }
}

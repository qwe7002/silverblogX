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
    let shared = UserDefaults(suiteName: "group.silverblog.client")!
    var post_title = "No Title"
    var slug = ""
    var config_list: [String: Any] = [:]
    override func isContentValid() -> Bool {
        if (contentText.isEmpty || shared.string(forKey: "server") == nil) {
            return false
        }
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if (shared.dictionary(forKey: "config_list") != nil) {
            config_list = shared.dictionary(forKey: "config_list")!
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if (shared.string(forKey: "server") == nil) {
            self.displayUIAlertController(title: "Please set the server information first.", message: "")
        }
    }

    override func didSelectPost() {

        let content = contentText
        let split = content!.components(separatedBy: "\n")
        if (split[0].hasPrefix("# ")) {
            let alertQuestController = UIAlertController(title: "Notice", message: "The title has been found in the content. Do you want to remove the title?", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
                action in
                self.send_post(content: content!)
            })
            let okAction = UIAlertAction(title: "OK", style: .default, handler: {
                action in
                self.send_post(content: content!.replacingOccurrences(of: split[0] + "\n", with: ""))
            })
            alertQuestController.addAction(cancelAction)
            alertQuestController.addAction(okAction)
            self.present(alertQuestController, animated: true, completion: nil)

        } else {
            self.send_post(content: content!)
        }

    }

    override func configurationItems() -> [Any]! {
        if (!contentText.isEmpty) {
            let split = contentText.components(separatedBy: "\n")
            if (split[0].hasPrefix("# ")) {
                post_title = split[0].replacingOccurrences(of: "# ", with: "")
            }
        }
        return [title_item, sulg_item, site_table_Item]
    }

    func send_post(content: String) {
        let password: String = shared.string(forKey: "password")!
        let server: String = shared.string(forKey: "server")!
        let sign = md5(post_title + password)
        let alertController = UIAlertController(title: nil, message: "Please wait...", preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        loadingIndicator.startAnimating();
        alertController.view.addSubview(loadingIndicator)
        self.present(alertController, animated: true, completion: nil)


        let parameters: Parameters = [
            "title": post_title,
            "sign": sign,
            "content": content,
            "name": slug
        ]
        var result_message = ""
        Alamofire.request("https://" + server + "/control/new", method: .post, parameters: parameters, encoding: JSONEncoding.default).validate().responseJSON { response in
            self.dismiss(animated: true) {
                switch response.result {
                case .success(let json):
                    let dict = json as! Dictionary<String, AnyObject>
                    let status = dict["status"] as! Bool
                    result_message = "Article publication failed."
                    if (status) {
                        result_message = "The article has been successfully published."
                    }
                case .failure(_):
                    result_message = "Article publication failed.Please check the network."
                }
                self.displayUIAlertController(title: "Notice", message: result_message)
            }
        }
    }

    func displayUIAlertController(title: String, message: String) {

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (action: UIAlertAction!) -> () in
            self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
        }))

        self.present(alert, animated: true, completion: nil)
    }

    private lazy var site_table_Item: SLComposeSheetConfigurationItem = {
        let item = SLComposeSheetConfigurationItem()!
        item.title = "Sites"
        item.value = shared.string(forKey: "server")!
        item.tapHandler = {
            let actionSheetController: UIAlertController = UIAlertController(title: "Use the previous config", message: "Please select the config", preferredStyle: .actionSheet)
            self.config_list.forEach { (key, value) in
                actionSheetController.addAction(UIAlertAction(title: key, style: .default, handler: { (action: UIAlertAction!) -> () in
                    let self_server_url = key
                    let self_password = value as! String
                    item.value = self_server_url
                    self.save_info(server: self_server_url, password: self_password)
                }))
            }
            actionSheetController.addAction(UIAlertAction(title: "Clean", style: .destructive, handler: { (action: UIAlertAction!) -> () in
                self.config_list = [:]
                self.shared.set(self.config_list, forKey: "config_list")
                self.shared.synchronize()
            }))
            actionSheetController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(actionSheetController, animated: true, completion: nil)
        }
        return item
    }()

    func save_info(server: String, password: String) {
        shared.set(server, forKey: "server")
        shared.set(password, forKey: "password")

        config_list[server] = password
        shared.set(config_list, forKey: "config_list")
        shared.synchronize()
    }
    lazy var title_item: SLComposeSheetConfigurationItem = {
        let item = SLComposeSheetConfigurationItem()!
        item.title = "Title"
        item.value = self.post_title
        item.tapHandler = {
            let alert = UIAlertController(title: "Please enter a title:", message: "", preferredStyle: .alert)
            alert.addTextField(configurationHandler: { (textField) in
                textField.placeholder = "Title"
                textField.keyboardType = .default
                textField.text = self.post_title
            })
            let cancel = UIAlertAction(title: "Cancel", style: .cancel)
            let confirm = UIAlertAction(title: "Ok", style: .default) { (action) in
                let textField = alert.textFields![0] // Force unwrapping because we know it exists.
                item.value = textField.text
                self.post_title = textField.text!
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
        item.tapHandler = {
            let alert = UIAlertController(title: "Please enter a sulg:", message: "", preferredStyle: .alert)
            alert.addTextField(configurationHandler: { (textField) in
                textField.placeholder = "Sulg"
                textField.keyboardType = .default
                textField.text = self.slug
            })
            let cancel = UIAlertAction(title: "Cancel", style: .cancel)
            let confirm = UIAlertAction(title: "Ok", style: .default) { (action) in
                let textField = alert.textFields![0] // Force unwrapping because we know it exists.
                item.value = textField.text
                self.slug = textField.text!
            }
            alert.addAction(cancel)
            alert.addAction(confirm)
            self.present(alert, animated: true, completion: nil)
        }
        return item
    }()

    func md5(_ string: String) -> String {

        let context = UnsafeMutablePointer<CC_MD5_CTX>.allocate(capacity: 1)
        var digest = Array<UInt8>(repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        CC_MD5_Init(context)
        CC_MD5_Update(context, string, CC_LONG(string.lengthOfBytes(using: String.Encoding.utf8)))
        CC_MD5_Final(&digest, context)
        context.deallocate()
        var hexString = ""
        for byte in digest {
            hexString += String(format: "%02x", byte)
        }

        return hexString
    }
}

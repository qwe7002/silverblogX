//
//  post_list_view.swift
//  silverblog
//
//  Created by 黄江华 on 2018/3/28.
//  Copyright © 2018年 qwe7002. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
class post_list_view: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!
    var array_json = JSON()
    override func viewDidLoad() {
        super.viewDidLoad()
        let alertController = UIAlertController(title: "Now Loading, please wait...", message: "", preferredStyle: .alert)
        self.present(alertController, animated: true, completion: nil)
        self.load_data()
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        self.tableView.addSubview(refreshControl)
    }
    @objc func refresh(refreshControl: UIRefreshControl) {
        load_data()
        refreshControl.endRefreshing()
    }
    func load_data(){
        Alamofire.request(global_value.server_url + "/control/get_list/post", method: .post, parameters: [:], encoding: JSONEncoding.default).validate().responseJSON { response in
            switch response.result.isSuccess {
            case true:
                self.presentedViewController?.dismiss(animated: false, completion: nil)
                if let value = response.result.value {
                    self.array_json = JSON(value)
                    print(self.array_json)
                    self.tableView.reloadData()
                }
            case false:
                print(response.result.error)
            }
        }
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        let alertController = UIAlertController(title: "Warning！", message: "Are you sure you want to delete this article?", preferredStyle: UIAlertControllerStyle.alert)
        let CancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default)
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default){(ACTION) in
            let parameters: Parameters = [
                "post_id": indexPath.row,
                "sign": public_func.md5(String(indexPath.row) + self.array_json[indexPath.row]["title"].string! + global_value.password)
            ]
            let doneController = UIAlertController(title: "Now Deleteing, please wait...", message: "", preferredStyle: .alert)
            self.present(doneController, animated: true, completion: nil)
            Alamofire.request(global_value.server_url + "/control/delete", method: .post, parameters: parameters, encoding: JSONEncoding.default).validate().responseJSON { response in
                switch response.result {
                case .success(let json):
                    print(json)
                    self.presentedViewController?.dismiss(animated: false, completion: nil)
                    self.load_data()
                case .failure(let error):
                    print(error)
                }
            }
        }
        alertController.addAction(okAction);
        alertController.addAction(CancelAction);
        self.present(alertController, animated: true, completion: nil)

    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let sb = UIStoryboard(name:"Main", bundle: nil)
        //todo
        //let vc = sb.instantiateViewController(withIdentifier: "post_list") as! UITabBarController
        //vc.params = indexPath.row
        //self.present(vc, animated: true, completion: nil)

    }
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Delete"
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.array_json.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "cell")! as UITableViewCell
        cell.textLabel?.text = self.array_json[indexPath.row]["title"].string
        return cell
    }

}

//
//  ViewController.swift
//  Sample
//
//  Created by 李二狗 on 2018/1/24.
//  Copyright © 2018年 Meniny Lab. All rights reserved.
//

import UIKit
import Leaf
import Oath

enum SampleType: String {
    case async  = "Asynchronous"
    case async_portfolio  = "Asynchronous Portfolio"
    case sync   = "Synchronous"
    case decode = "Decode"
    case leafAsync = "Leaf-Asynchronous"
    
    var selector: Selector {
        switch self {
        case .async:
            return #selector(ViewController.sample_async)
        case .async_portfolio:
            return #selector(ViewController.sample_async_portfolio)
        case .sync:
            return #selector(ViewController.sample_sync)
        case .decode:
            return #selector(ViewController.sample_decode)
        case .leafAsync:
            return #selector(ViewController.sample_leaf_async)
        }
    }
    
    static let all: [SampleType] = [.async, .async_portfolio, .sync, .decode, .leafAsync]
}

class ViewController: UITableViewController {

    let session: Leafable = LeafURLSession.shared
//    let url = "http://10.9.175.248:8080/about.json"
    let url = "https://meniny.cn/api/v2/about.json"
    lazy var request: LeafRequest = {
        let r = LeafRequest.init(self.url)
        return r!
    }()
    
    let cells: [SampleType] = SampleType.all
    
    let label = UILabel.init(frame: CGRect.init(x: 0, y: 0, width: 100, height: 20))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.tableFooterView = UIView.init()
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")
        let data = self.cells[indexPath.row]
        cell?.textLabel?.text = data.rawValue
        return cell!
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.cells.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let data = self.cells[indexPath.row]
        self.perform(data.selector)
        self.tableView.deselectRow(at: indexPath, animated: true)
    }
    
    @objc
    func sample_async() {
        let controller = UIAlertController.init(title: "URL", message: "Enter the url", preferredStyle: .alert)
        controller.addTextField { (text) in
            text.clearButtonMode = .whileEditing
            text.placeholder = "URL"
            text.text = self.url
        }
        controller.addAction(UIAlertAction.init(title: "Go", style: .default, handler: { (_) in
            if let u = controller.textFields?.first?.text {
                if !u.isEmpty {
                    self._async(url: u)
                }
            }
        }))
        controller.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        self.present(controller, animated: true, completion: nil)
    }
    
    @objc
    func sample_async_portfolio() {
        let controller = UIAlertController.init(title: "URL", message: "Choose an url", preferredStyle: .alert)
        
        let buttons: [String] = [
            "portfolio_android",
            "portfolio_ios",
            "portfolio_mac",
            "portfolio_paintings",
            "portfolio_repos",
            "portfolio_win"
        ]
        for btn in buttons {
            controller.addAction(UIAlertAction.init(title: btn, style: .default, handler: { (action) in
                guard let u = action.title, !u.isEmpty else {
                    self.display("Error")
                    return
                }
                self._async_portfolio(u)
            }))
        }
        controller.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        self.present(controller, animated: true, completion: nil)
    }
    
    func _async_portfolio(_ jsonName: String) {
        let u = "https://meniny.cn/api/v2/\(jsonName).json"
        if let r = LeafRequest.init(u) {
            session.dataTask(r).progress({ (progress) in
                print(progress)
            }).async(success: { (response) in
                do {
                    if let result: Portfolio = try response.decode() {
                        self.display("\(result)")
                    }
                } catch {
                    self.display("Asynchronous: Parse error: \(error.localizedDescription)")
                }
            }, failure: { (error) in
                self.display("Asynchronous: Leaf error: \(error)")
            })
        } else {
            self.display("Asynchronous: Error: \(u)")
        }
    }
    
    // Asynchronous
    func _async(url u: String) {
        if let r = LeafRequest.init(u) {
            session.dataTask(r).progress({ (progress) in
                print(progress)
            }).async(success: { (response) in
                do {
                    if let object: [AnyHashable: Any] = try response.object() {
                        self.display("Asynchronous: \(object)")
                    }
                } catch {
                    self.display("Asynchronous: Parse error: \(error.localizedDescription)")
                }
            }, failure: { (error) in
                self.display("Asynchronous: Leaf error: \(error)")
            })
        }
    }
    
    @objc
    func sample_sync() {
        // Synchronous
        do {
            let date = Date()
            let object: [AnyHashable: Any] = try session.dataTask(request).progress({ (progress) in
                print(progress)
            }).sync().object()
            self.display("Synchronous: \(object)\n Time: \(Date().timeIntervalSince(date))")
        } catch {
            self.display("Synchronous: Error: \(error)")
        }
        
    }
    
    @objc
    func sample_decode() {
        // Decode
        session.dataTask(self.request).progress({ (progress) in
            print(progress)
        }).async(success: { (response) in
            do {
                if let result: AboutResponse = try response.decode() {
                    self.display(result.about.joined(separator: "\n------\n"))
                }
            } catch {
                self.display("Decode: Parse error: \(error)")
            }
        }, failure: { (error) in
            self.display("Decode: Leaf error: \(error)")
        })
    }
    
    @objc func sample_leaf_async() {
        let u = URL.init(string: self.url)!
        
        do {
            try Leaf.init(u, parameters: ["lan": "en-US"]).async(.GET, progress: { (progress) in
                print(progress)
            }, success: { (response) in
                do {
                    if let result: AboutResponse = try response.decode() {
                        self.display(result.about.joined(separator: "\n------\n"))
                    }
                } catch {
                    self.display("Leaf: Parse error: \(error)")
                }
            }, failure: { (error) in
                self.display("Leaf Asynchronous: Leaf error: \(error)")
            })
        } catch {
            self.display("Leaf: Request error: \(error)")
        }
    }
    
    @objc func sample_leaf_async_oath() {
        let u = URL.init(string: self.url)!
        
        do {
            let leaf = Leaf.init(u, parameters: ["lan": "en-US"])
//            leaf.request(.GET).then { response in
//                do {
//                    if let result: AboutResponse = try response.decode() {
//                        self.display(result.about.joined(separator: "\n------\n"))
//                    }
//                } catch {
//                    self.display("Leaf: Parse error: \(error)")
//                }
//                }.onError({ (error) in
//                    self.display("Leaf Asynchronous: Leaf error: \(error)")
//                })
            try leaf.async(.GET, progress: { (progress) in
                print(progress)
            }, success: { (response) in
                do {
                    if let result: AboutResponse = try response.decode() {
                        self.display(result.about.joined(separator: "\n------\n"))
                    }
                } catch {
                    self.display("Leaf: Parse error: \(error)")
                }
            }, failure: { (error) in
                self.display("Leaf Asynchronous: Leaf error: \(error)")
            })
        } catch {
            self.display("Leaf: Request error: \(error)")
        }
    }
    
    func display(_ portfolio: ProtfolioResponse, function: String = #function) {
        DispatchQueue.main.async {
            let next = PortfolioTableViewController.init(nibName: "PortfolioTableViewController", bundle: nil)
            next.portfolio = portfolio
            next.title = function
            self.navigationController?.show(next, sender: self)
        }
    }

    func display(_ text: String, function: String = #function) {
        DispatchQueue.main.async {
            let next = DisplayViewController.init(nibName: "DisplayViewController", bundle: nil)
            next.text = text
            next.title = function
            self.navigationController?.show(next, sender: self)
            print(text)
        }
    }
}


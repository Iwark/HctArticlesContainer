//
//  ViewController.swift
//  HctArticlesContainerViewController
//
//  Created by Kohei Iwasaki on 3/2/16.
//  Copyright © 2016 Kohei Iwasaki. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, ArticlesContainerDataSource {
    
    @IBOutlet weak var tableView: UITableView!

    // モデル
    var articles:[String] {
        get {
            var results:[String] = []
            for i in 0..<20 {
                results.append("記事\(i)")
            }
            return results
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 20
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = "記事\(indexPath.row)"
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let dvc = DescriptionViewController(dataSource: self, index: indexPath.row)
        self.navigationController?.pushViewController(dvc, animated: true)
    }
    
    func viewControllerAtIndex(index: Int) -> UIViewController? {
        if index < 0 || index > 19 {
            return nil
        }
        let avc = ArticleViewController()
        avc.view.frame.size.height = 800
        if index % 2 == 0 {
            avc.view.backgroundColor = UIColor.yellowColor()
        } else {
            avc.view.backgroundColor = UIColor.greenColor()
        }
        let titleLabel = UILabel(frame: avc.view.frame)
        titleLabel.text = articles[index]
        avc.view.addSubview(titleLabel)
        return avc
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}


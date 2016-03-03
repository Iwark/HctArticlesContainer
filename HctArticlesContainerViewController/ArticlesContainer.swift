//
//  ArticlesContainerViewController.swift
//  HctArticlesContainerViewController
//
//  Created by Kohei Iwasaki on 3/2/16.
//  Copyright © 2016 Kohei Iwasaki. All rights reserved.
//

import UIKit

@objc public protocol ArticlesContainerDataSource {
    func viewControllerAtIndex(index: Int) -> UIViewController?
}

class ArticlesContainer: UIViewController, UIScrollViewDelegate {
    
    /// 次の記事の冒頭部分の長さ（default to 60.0）
    var nextHeadlineLength:CGFloat = 60
    /// 前の記事へ移動する時間
    var goToPrevPageDuration:NSTimeInterval = 0.5
    /// 次の記事へ移動する時間
    var goToNextPageDuration:NSTimeInterval = 0.6
    
    /// 現在の記事と、前後の記事のコントローラを保持する
    var viewControllers:[UIViewController?] = [nil, nil, nil]
    var prevViewController:UIViewController? {
        get {
            return self.viewControllers[0]
        }
    }
    var currentViewController:UIViewController? {
        get {
            return self.viewControllers[1]
        }
    }
    var nextViewController:UIViewController? {
        get {
            return self.viewControllers[2]
        }
    }

    /// ３つの記事を表示するスクロールビュー
    var scrollView: UIScrollView!
    
    /// 記事のDataSource
    weak var dataSource:ArticlesContainerDataSource?
    
    private var _index:Int!
    /// 現在表示している記事インデックス
    var index:Int {
        get {
            return _index
        }
        set {
            let scrollTo = newValue - _index
            _index = newValue
            self.updateViewControllers(scrollTo)
        }
    }
    private var rendering = false

    /// ArticlesContainerの生成
    convenience init(dataSource:ArticlesContainerDataSource, index:Int) {
        self.init(nibName: nil, bundle: nil)
        self.dataSource = dataSource
        _index = index
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.scrollView = UIScrollView(frame: self.view.frame)
        self.view.addSubview(self.scrollView)
        self.scrollView.delegate = self
        self.updateViewControllers()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        guard let key = keyPath else {
            return
        }
        switch key {
        case "frame":
//            print(change)
            self.render()
        default:
            return
        }
    }
    
    func updateViewControllers(scrollTo:Int = 0) {
        for vc in self.viewControllers {
            if let vc = vc {
                vc.willMoveToParentViewController(nil)
                vc.view.removeFromSuperview()
                vc.view.removeObserver(self, forKeyPath: "frame")
                vc.removeFromParentViewController()
            }
        }
        var cy = self.scrollView.contentOffset.y
        if let pvc = prevViewController {
            if scrollTo > 0 {
                cy -= pvc.view.frame.size.height
            } else {
                cy += pvc.view.frame.size.height
            }
        }
        self.viewControllers[0] = self.dataSource?.viewControllerAtIndex(self.index-1)
        self.viewControllers[1] = self.dataSource?.viewControllerAtIndex(self.index)
        self.viewControllers[2] = self.dataSource?.viewControllerAtIndex(self.index+1)
        for vc in self.viewControllers {
            if let vc = vc {
                self.addChildViewController(vc)
                self.scrollView.addSubview(vc.view)
                vc.view.addObserver(self, forKeyPath: "frame", options: [.Old, .New], context: nil)
                vc.didMoveToParentViewController(self)
            }
        }
        self.render()
        if prevViewController != nil {
            self.scrollView.setContentOffset(CGPointMake(0, cy), animated: false)
        }
    }
    
    func render() {
        if self.rendering {
            return
        }
        self.rendering = true
        defer { self.rendering = false }
        
        var y:CGFloat = 0
        var h:CGFloat = 0
        if let pvc = self.prevViewController {
            pvc.view.frame.origin.y = y
            h = pvc.view.frame.size.height
            y += h
        }
        self.scrollView.contentInset.top = -h
        if let cvc = self.currentViewController {
            cvc.view.frame.origin.y = y
            y += cvc.view.frame.size.height
            h += nextHeadlineLength
        }
        if let nvc = self.nextViewController {
            nvc.view.frame.origin.y = y
            h += nvc.view.frame.size.height
            self.scrollView.contentSize.height = h
        }
    }
    
    func goToPrevPage() {
        if let pvc = self.prevViewController {
            self.scrollView.scrollEnabled = false
            UIView.animateWithDuration(goToPrevPageDuration, delay: 0, options: .CurveEaseOut, animations: { () -> Void in
                self.scrollView.setContentOffset(CGPointMake(0, pvc.view.frame.size.height - UIScreen.mainScreen().bounds.size.height), animated: false)
                }, completion: { (finished) -> Void in
                    self.index = self.index - 1
                    self.scrollView.scrollEnabled = true
            })
        }
    }
    
    func goToNextPage() {
        if let nvc = self.nextViewController {
            self.scrollView.scrollEnabled = false
            self.scrollView.contentSize.height += nvc.view.frame.size.height - self.nextHeadlineLength
            UIView.animateWithDuration(goToNextPageDuration, delay: 0, options: .CurveEaseOut, animations: { () -> Void in
                let navHeight = (self.navigationController?.navigationBar.frame.size.height ?? 0) + UIApplication.sharedApplication().statusBarFrame.size.height
                self.scrollView.setContentOffset(CGPointMake(0, nvc.view.frame.origin.y - navHeight), animated: false)
                }, completion: { (finished) -> Void in
                    self.index = self.index + 1
                    self.scrollView.scrollEnabled = true
            })
        }
    }
    
    deinit {
        for vc in self.viewControllers {
            if let vc = vc {
                vc.view.removeObserver(self, forKeyPath: "frame")
            }
        }
        self.viewControllers = [nil, nil, nil]
    }
    
    func scrollViewWillBeginDecelerating(scrollView: UIScrollView) {
        if scrollView.scrollEnabled == false {
            scrollView.setContentOffset(scrollView.contentOffset, animated: true)
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        let y = scrollView.contentOffset.y
        let navHeight = (self.navigationController?.navigationBar.frame.size.height ?? 0) + UIApplication.sharedApplication().statusBarFrame.size.height
        let prevY = -scrollView.contentInset.top - navHeight
        let nextY = scrollView.contentSize.height + nextHeadlineLength - UIScreen.mainScreen().bounds.size.height
        if y < prevY {
            goToPrevPage()
        }
        if y > nextY {
            goToNextPage()
        }
    }
}
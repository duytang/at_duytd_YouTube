//
//  FavoriteViewController.swift
//  YouTube
//
//  Created by Duy Tang on 8/6/16.
//  Copyright © 2016 Duy Tang. All rights reserved.
//

import UIKit
import RealmSwift
import SwiftUtils

class FavoriteViewController: BaseViewController {

    @IBOutlet weak private var favoriteTableView: UITableView!
    private var listFavorite: Results<Favorite>!
    private struct Options {
        static let HeightOfCell: CGFloat = 100
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        Notification()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        favoriteTableView.reloadData()
    }
    // MARK:- Set Up UI
    override func setUpUI() {
        navigationController?.navigationBarHidden = true
        configureFavoriteController()
    }
    // MARK:- Set Up Data
    override func setUpData() {
        loadData()
    }
    // MARK:- Configure FavoriteController
    private func configureFavoriteController() {
        favoriteTableView.registerNib(FavoriteCell)
    }
    // MARK:- Load Data
    func loadData() {
        do {
            let realm = try Realm()
            listFavorite = realm.objects(Favorite)
        } catch {

        }
    }
    // MARK:- Notification
    func Notification() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(deleteListFavorite), name: NotificationDefine.DeleteListFavorite, object: nil)
    }
    // MARK:- Update UI
    func deleteListFavorite(notification: NSNotification) {
        let userInfo = notification.userInfo
        let indexPath = userInfo!["indexPath"] as! NSIndexPath
        favoriteTableView.beginUpdates()
        var indexPaths = [NSIndexPath]()
        indexPaths.append(indexPath)
        favoriteTableView.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: .Left)
        favoriteTableView.endUpdates()
    }

}
extension FavoriteViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let favorites = listFavorite {
            return favorites.count
        } else {
            return 0
        }
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = favoriteTableView.dequeue(FavoriteCell)
        let favorite = listFavorite[indexPath.row]
        cell.configureFavoriteCell(favorite)
        return cell
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return Options.HeightOfCell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let detailFavoriteVC = DetailFavoriteViewController()
        detailFavoriteVC.favorite = listFavorite[indexPath.row]
        navigationController?.pushViewController(detailFavoriteVC, animated: true)
    }

    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .Default, title: Message.Delete) { action, index in
            let listVideo: Results<VideoFavorite>!
            do {
                let realm = try Realm()
                listVideo = realm.objects(VideoFavorite).filter("idListFavorite = %@", self.listFavorite[indexPath.row].id)
                try realm.write({
                    realm.delete(self.listFavorite[indexPath.row])
                    realm.delete(listVideo)
                    NSNotificationCenter.defaultCenter().postNotificationName(NotificationDefine.DeleteListFavorite, object: nil, userInfo: ["indexPath": indexPath])
                })
            } catch {

            }
        }
        return [delete]
    }
}


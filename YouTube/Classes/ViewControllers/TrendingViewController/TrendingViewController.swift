//
//  TrendingViewController.swift
//  YouTube
//
//  Created by Duy Tang on 8/16/16.
//  Copyright © 2016 Duy Tang. All rights reserved.
//

import UIKit
import RealmSwift

class TrendingViewController: BaseViewController {

    @IBOutlet weak var trendingTableView: UITableView!
    private var trendingVideos: Results<Video>!
    private var idCategory = "0"
    private var nextPage: String?
    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK:- Configure TrendingViewControllers
    func configureTrendingViewController() {
        self.trendingTableView.registerNib(HomeCell)
    }

    // MARk:- Set up UI
    override func setUpUI() {
        configureTrendingViewController()
    }

    // MARK:- Set Up Data
    override func setUpData() {
        if let videos = Video.getVideos(idCategory) where videos.count > 0 {
            trendingVideos = videos
            loadData()
        } else {
            loadTrendingVideo(idCategory, pageToken: nil)
        }
    }

    // MARK:- Load Data

    func loadData() {
        do {
            let realm = try Realm()
            trendingVideos = realm.objects(Video).filter("idCategory = %@", idCategory)
            self.trendingTableView.reloadData()
        } catch {

        }
    }

    func loadTrendingVideo(id: String, pageToken: String?) {
        var parameters = [String: AnyObject]()
        parameters["part"] = "snippet,contentDetails,statistics"
        parameters["chart"] = "mostPopular"
        parameters["regionCode"] = "VN"
        parameters["maxResults"] = "10"
        parameters["pageToken"] = pageToken
        MyVideo.loadDataFromAPI(idCategory, pageToken: nextPage, parameters: parameters) { (success, nextPageToken, error) in
            if success {
                self.loadData()
                self.nextPage = nextPageToken
            }
        }
    }
}

extension TrendingViewController: UITableViewDataSource {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let videos = trendingVideos {
            return videos.count
        } else {
            return 0
        }
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = self.trendingTableView.dequeue(HomeCell.self)
        let video = trendingVideos[indexPath.row]
        cell.configureCell(video)
        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let detailVideoVC = DetailVideoViewController()
        let video = trendingVideos![indexPath.row]
        detailVideoVC.video = video
        self.navigationController?.pushViewController(detailVideoVC, animated: true)
    }

    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if scrollView == trendingTableView {
            if (scrollView.contentOffset.y + scrollView.frame.size.height) >= scrollView.contentSize.height {
                loadTrendingVideo(idCategory, pageToken: nextPage)
                trendingTableView.reloadData()
            }
        }
    }

    func scrollViewDidScroll(scrollView: UIScrollView) {
        let currentOffset = scrollView.contentOffset.y
        let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height;
        if (maximumOffset - currentOffset <= 10.0) {
            loadTrendingVideo(idCategory, pageToken: nextPage)
            trendingTableView.reloadData()
        }
    }
}

extension TrendingViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return AppDefine.heightOfHomeCell
    }
}

//
//  DetailVideoViewController.swift
//  YouTube
//
//  Created by Duy Tang on 8/6/16.
//  Copyright © 2016 Duy Tang. All rights reserved.
//

import UIKit
import RealmSwift
import ObjectMapper
import XCDYouTubeKit
import SwiftUtils
protocol DetailVideoDelegete {
    func deleteFromListFavorite(isDeleted: Bool)
}

class DetailVideoViewController: BaseViewController {
    @IBOutlet weak var detailVideoTable: UITableView!
    @IBOutlet weak private var playerVideoView: UIView!
    private var dataOfRelatedVideo: Results<RelatedVideo>!
    private var youtubeVideoPlayer: XCDYouTubeVideoPlayerViewController?
    private var isExpandDescription = false
    private var isFavorite = false
    private var isPlaying = false
    private var width = UIScreen.mainScreen().bounds.width
    private var viewPlayer: UIView!
    var video = Video()
    var oldVideo = Video()
    var videos = [Video]()
    var dismissButton: UIButton!
    var favoriteButton: UIButton!
    var playButton: UIButton!
    var nextButton: UIButton!
    var previousButton: UIButton!
    private var indicator: UIActivityIndicatorView!
    var delegate: DetailVideoDelegete?
    private struct Options {
        static let HeightOfRow: CGFloat = 83
        static let HeightOfPlayVideoCell: CGFloat = 104
        static let HeightOfButtonCell: CGFloat = 30
        static let MaxRelatedVideo = 20
    }
    @IBOutlet weak var backgroundView: UIView!
    var handlePan: ((panGestureRecognizer: UIPanGestureRecognizer) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        indicator.startAnimating()

    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func setUp() {
        modalPresentationStyle = .OverCurrentContext
        addNotifiation()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

    }

    private func addNotifiation() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(moviePlayerNowPlayingMovieDidChange),
            name: MPMoviePlayerNowPlayingMovieDidChangeNotification, object: youtubeVideoPlayer?.moviePlayer)

        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: #selector(moviePlayerLoadStateDidChange),
            name: MPMoviePlayerLoadStateDidChangeNotification, object: youtubeVideoPlayer?.moviePlayer)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(moviePlayerPlaybackDidChange),
            name: MPMoviePlayerPlaybackStateDidChangeNotification, object: youtubeVideoPlayer?.moviePlayer)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(moviePlayerPlayBackDidFinish),
            name: MPMoviePlayerPlaybackDidFinishNotification, object: youtubeVideoPlayer?.moviePlayer)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(changeVideo(_:)), name: XCDYouTubeVideoPlayerViewControllerDidReceiveVideoNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(rotatedDevice), name: UIDeviceOrientationDidChangeNotification, object: nil)
    }

    func changeVideo(notification: NSNotification) {
        dispatch_async(dispatch_get_main_queue()) {
            self.youtubeVideoPlayer!.moviePlayer.prepareToPlay()
        }
    }

    // MARK:- Add Video Player View
    func addVideoPlayerView() {
        viewPlayer = UIView(frame: CGRect(x: 0, y: 0, width: width, height: width * 2.4 / 4))
        prepareToPlayVideo(video.idVideo)
        playerVideoView.addSubview(viewPlayer)
    }

    func prepareToPlayVideo(id: String) {
        youtubeVideoPlayer?.view.removeFromSuperview()
        youtubeVideoPlayer = XCDYouTubeVideoPlayerViewController(videoIdentifier: id)
        youtubeVideoPlayer?.presentInView(viewPlayer)
    }

    // MARK:- Config DetailVideoViewController
    private func configureDetailVideoViewController() {
        dismissButton = UIButton(frame: CGRect(x: 10, y: 0, width: 30, height: 30))
        dismissButton.setImage(UIImage(named: "bt_close"), forState: .Normal)
        dismissButton.addTarget(self, action: #selector(hideView), forControlEvents: .TouchUpInside)

        favoriteButton = UIButton(frame: CGRect(x: width - 40, y: 0, width: 40, height: 40))
        setImageForFavoriteButton()
        favoriteButton.addTarget(self, action: #selector(addVideoToFavoriteList), forControlEvents: .TouchUpInside)

        playButton = UIButton(frame: CGRect(x: viewPlayer.frame.midX - 25, y: viewPlayer.frame.midY - 25, width: 50, height: 50))
        playButton.setImage(UIImage(named: "bt_play"), forState: .Normal)
        playButton.tintColor = .whiteColor()
        playButton.addTarget(self, action: #selector(handlePause), forControlEvents: .TouchUpInside)
        playButton.hidden = true

        nextButton = UIButton(frame: CGRect(x: viewPlayer.frame.midX + 25, y: viewPlayer.frame.midY - 25, width: 50, height: 50))
        nextButton.setImage(UIImage(named: "bt_next"), forState: .Normal)
        nextButton.tintColor = .whiteColor()
        nextButton.addTarget(self, action: #selector(handleNext), forControlEvents: .TouchUpInside)
        nextButton.hidden = true

        previousButton = UIButton(frame: CGRect(x: viewPlayer.frame.midX - 75, y: viewPlayer.frame.midY - 25, width: 50, height: 50))
        previousButton.setImage(UIImage(named: "bt_previou"), forState: .Normal)
        previousButton.tintColor = .whiteColor()
        previousButton.addTarget(self, action: #selector(handlePrevious), forControlEvents: .TouchUpInside)
        previousButton.hidden = true

        indicator = UIActivityIndicatorView(frame: CGRect(x: viewPlayer.frame.midX - 25, y: viewPlayer.frame.midY - 25, width: 50, height: 50))

        view.addSubview(indicator)
        view.addSubview(dismissButton)
        view.addSubview(favoriteButton)
        view.addSubview(playButton)
        view.addSubview(nextButton)
        view.addSubview(previousButton)

        detailVideoTable.registerNib(PlayVideoCell)
        detailVideoTable.registerNib(DecriptVideoCell)
        detailVideoTable.registerNib(ButtonCell)
        detailVideoTable.registerNib(VideoFavoriteCell)
    }

    private func setTimeAppear() {
        _ = NSTimer.scheduledTimerWithTimeInterval(4, target: self, selector: #selector(tapVideoPlayer), userInfo: nil, repeats: true)

    }

    func tapVideoPlayer() {
        hideButton(true)
    }

    private func hideButton(status: Bool) {
        nextButton.hidden = status
        playButton.hidden = status
        previousButton.hidden = status
    }

    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if isPlaying {
            youtubeVideoPlayer?.moviePlayer.pause()
            playButton.setImage(UIImage(named: "bt_play"), forState: .Normal)
            isPlaying = false
        } else {
            youtubeVideoPlayer?.moviePlayer.play()
            playButton.setImage(UIImage(named: "bt_pause"), forState: .Normal)
            isPlaying = true
        }
        hideButton(false)
    }

    func setImageForFavoriteButton() {
        isFavorite = checkFavorite(video.idVideo)
        let nameImage = isFavorite ? "bt_starfill" : "bt_star"
        favoriteButton.setImage(UIImage(named: nameImage), forState: .Normal)
    }

    func handlePause() {
        if isPlaying {
            youtubeVideoPlayer?.moviePlayer.pause()
            playButton.setImage(UIImage(named: "bt_play"), forState: .Normal)
        } else {
            youtubeVideoPlayer?.moviePlayer.play()
            playButton.setImage(UIImage(named: "bt_pause"), forState: .Normal)
        }
        isPlaying = !isPlaying
    }

    func handleNext() {
        oldVideo = video
        video = videos[0]
        handleChangState()
    }

    func handlePrevious() {
        video = oldVideo
        handleChangState()
    }

    private func handleChangState() {
        hideButton(true)
        indicator.startAnimating()
        isFavorite = checkFavorite(video.idVideo)
        setImageForFavoriteButton()
        loadData()
        youtubeVideoPlayer?.moviePlayer.pause()
        prepareToPlayVideo(video.idVideo)
        History.addVideoToHistory(video)
    }

    // MARK:- Set Up UI
    override func setUpUI() {
        addVideoPlayerView()
        configureDetailVideoViewController()
        setTimeAppear()
    }

    // MARK:- Set Up Data
    override func setUpData() {
        videos.removeAll()
        loadData()
    }

    // MARK:- Load related video
    func loadData() {
        videos.removeAll()
        loadRelatedVideo(video.idVideo)
    }

    private func loadRelatedVideo(id: String) {
        var parameters = [String: AnyObject]()
        parameters["part"] = "snippet"
        parameters["maxResults"] = Options.MaxRelatedVideo
        parameters["relatedToVideoId"] = id
        parameters["type"] = "video"
        showLoading()
        VideoService.loadListVideoRelated(parameters) { (response) in
            if let items = response as? NSArray {
                for item in items {
                    let video = Mapper<Video>().map(item)
                    var parameter = [String: AnyObject]()
                    parameter["part"] = "contentDetails,statistics"
                    parameter["id"] = video?.idVideo
                    VideoService.loadDetailVideoFromIdVideo(parameter, completion: { (response) in
                        if let detailVideo = response as? NSArray {
                            for item in detailVideo {
                                if let detailVideo = item.objectForKey("contentDetails") as? NSDictionary {
                                    video?.duration = detailVideo["duration"] as? String ?? ""
                                }
                                if let statistics = item.objectForKey("statistics") as? NSDictionary {
                                    video?.viewCount = statistics["viewCount"] as? String ?? ""
                                }
                                self.videos.append(video!)
                                self.detailVideoTable.reloadData()
                            }
                        }
                    })
                }
                self.hideLoading()
            }
        }
    }

    // MARK:- Check Favorite
    func checkFavorite(idVideo: String) -> Bool {
        var isFavorite = false
        let listVideo = RealmManager.getListVideoFavorite(video.idVideo)
        if listVideo?.count > 0 {
            isFavorite = true
        }
        return isFavorite
    }

    // MARK:- Action
    @IBAction func addVideoToFavoriteList(sender: AnyObject) {
        self.youtubeVideoPlayer?.moviePlayer.pause()
        if isFavorite == false {
            let addFavoriteVC = AddFavoriteViewController()
            addFavoriteVC.video = video
            addFavoriteVC.delegate = self
            addFavoriteVC.view.frame = view.bounds
            view.addSubview(addFavoriteVC.view)
            self.addChildViewController(addFavoriteVC)
        } else {
            let video = RealmManager.getVideoFavorite(self.video.idVideo)
            RealmManager.deleteRealm(video)
            favoriteButton.setImage(UIImage(named: "bt_star"), forState: .Normal)
            isFavorite = false
            delegate?.deleteFromListFavorite(isFavorite)
        }
    }
    // MARK:- Progress Rotate Device
    func rotatedDevice() {
        let orientation = UIDevice.currentDevice().orientation
        if orientation == UIDeviceOrientation.LandscapeLeft || orientation == UIDeviceOrientation.LandscapeRight || orientation == UIDeviceOrientation.PortraitUpsideDown {
            youtubeVideoPlayer?.moviePlayer.setFullscreen(true, animated: true)
        } else {
            if orientation == UIDeviceOrientation.Portrait {
                youtubeVideoPlayer?.moviePlayer.setFullscreen(false, animated: true)
            } else if orientation == UIDeviceOrientation.FaceDown {
                youtubeVideoPlayer?.moviePlayer.pause()
            } else {
                youtubeVideoPlayer?.moviePlayer.play()
            }
        }

    }

    @IBAction func handlePan(sender: UIPanGestureRecognizer) {
        self.handlePan?(panGestureRecognizer: sender)
    }

    func hideView(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }

    func moviePlayerPlayBackDidFinish(notification: NSNotification) {
        print("moviePlayerPlayBackDidFinish")
        handleNext()
    }

    func moviePlayerNowPlayingMovieDidChange(notification: NSNotification) {
        print("moviePlayerNowPlayingMovieDidChange")
    }

    func moviePlayerLoadStateDidChange(notification: NSNotification) {
        let state = (youtubeVideoPlayer?.moviePlayer.playbackState)!
        switch state {
        case .Stopped:
            break
        case .Interrupted:
            break
        case .SeekingForward:
            break
        case .SeekingBackward:
            break
        case .Paused:
            break
        case .Playing:
            break
        }
    }

    func moviePlayerPlaybackDidChange(notification: NSNotification) {
        let state = (youtubeVideoPlayer?.moviePlayer.playbackState)!
        switch state {
        case .Stopped:
            handleNext()
            break
        case .Interrupted:
            break
        case .SeekingForward:
            break
        case .SeekingBackward:
            break
        case .Paused:
            break
        case .Playing:
            indicator.stopAnimating()
            playButton.setImage(UIImage(named: "bt_pause"), forState: .Normal)
            hideButton(false)
            break
        }
    }
}
// MARK:- Extension
extension DetailVideoViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return videos.count + 4
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            let cell = detailVideoTable.dequeue(PlayVideoCell.self)
            cell.configPlayVideoCell(video)
            return cell
        case 1:
            let cell = detailVideoTable.dequeue(DecriptVideoCell.self)
            cell.configureDecriptVideoCell(video.descript, nameFont: UIFont().fontHelveticaNeue(), size: 12, color: .blackColor())
            return cell
        case 2:
            let cell = detailVideoTable.dequeue(ButtonCell.self)
            cell.delegate = self
            return cell
        case 3:
            let cell = detailVideoTable.dequeue(DecriptVideoCell.self)
            cell.configureDecriptVideoCell(Message.RelatedVideo, nameFont: UIFont().fontHelveticaNeue(), size: 15, color: Color.TitleColor)
            return cell
        default:
            let cell = detailVideoTable.dequeue(VideoFavoriteCell.self)
            let video = videos[indexPath.row - 4]
            cell.configureCell(video)
            return cell
        }
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch indexPath.row {
        case 0:
            return Options.HeightOfPlayVideoCell
        case 1:
            return !isExpandDescription ? 0 : UITableViewAutomaticDimension
        case 2:
            return Options.HeightOfButtonCell
        case 3:
            return 15
        default:
            return Options.HeightOfRow
        }
    }

    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row > 3 {
            if videos.count > 0 {
                indicator.startAnimating()
                youtubeVideoPlayer?.moviePlayer.pause()
                hideButton(true)
                oldVideo = video
                video = videos[indexPath.row - 4]
                loadData()
                isFavorite = checkFavorite(video.idVideo)
                favoriteButton.setImage(UIImage(named: "bt_star"), forState: .Normal)
                prepareToPlayVideo(video.idVideo)
                History.addVideoToHistory(video)
            }

        }
    }
}

extension DetailVideoViewController: AddFavoriteDelegate {
    func addSuccess(isSuccess: Bool) {
        if isSuccess {
            favoriteButton.setImage(UIImage(named: "bt_starfill"), forState: .Normal)
            isFavorite = isSuccess
        } else {
            isFavorite = isSuccess
        }

    }
}

extension DetailVideoViewController: ButtonCellDelegate {
    func clickExpandDescription(cell: ButtonCell) {
        isExpandDescription = !isExpandDescription
        detailVideoTable.beginUpdates()
        detailVideoTable.endUpdates()
    }
}

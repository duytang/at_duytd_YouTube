//
//  Video.swift
//  YouTube
//
//  Created by Duy Tang on 8/10/16.
//  Copyright © 2016 Duy Tang. All rights reserved.
//

import Foundation
import RealmSwift
import ObjectMapper

private protocol VideoObject {
    init?(_ object: VideoFavorite)
    init?(history: History)
}

struct Option {
    static let UrlImage = "https://i.ytimg.com/vi/"
    // MARK:- Type Image
    static let DefaulImage = "/default.jpg"
    static let MediumImage = "/mqdefault.jpg"
    static let HighImage = "/hqdefault.jpg"
    static let StandardImage = "/sddefault.jpg"
    static let MaxresImage = "/maxresdefault.jpg"
}

class Video: Object, Mappable, VideoObject {
    dynamic var idVideo = ""
    dynamic var idCategory = ""
    dynamic var title = ""
    dynamic var viewCount = ""
    dynamic var duration = ""
    dynamic var channelId = ""
    dynamic var channelTitle = ""
    dynamic var channelThumnail = ""
    dynamic var descript = ""
    dynamic var thumbnail = ""
    dynamic var timeUpload = ""

    required convenience init?(_ map: Map) {
        self.init()
    }

    func mapping(map: Map) {
        var id = ""
        id <- map["id"]
        if id == "" {
            var items = [String: AnyObject]()
            items <- map["id"]
            idVideo = items["videoId"] as? String ?? ""
        } else {
            idVideo = id
        }

        idVideo <- map["id"]
        var snippet = [String: AnyObject]()
        snippet <- map["snippet"]
        title = snippet["title"] as? String ?? ""
        channelId = snippet["channelId"] as? String ?? ""
        channelTitle = snippet["channelTitle"] as? String ?? ""
        descript = snippet["description"] as? String ?? ""
        timeUpload = snippet["publishedAt"] as? String ?? ""
        var contentDetails = [String: AnyObject]()
        contentDetails <- map["contentDetails"]
        duration = contentDetails["duration"] as? String ?? ""

        var statistics = [String: AnyObject]()
        statistics <- map["statistics"]
        viewCount = statistics["viewCount"] as? String ?? ""
        thumbnail = Option.UrlImage + idVideo + Option.HighImage
    }

    class func getVideos(id: String) -> Results<Video>? {
        do {
            let realm = try Realm()
            let videos = realm.objects(self).filter("idCategory = %@", id)
            return videos
        } catch {
            return nil
        }
    }

    convenience required init(_ object: VideoFavorite) {
        self.init()
        idVideo = object.idVideo ?? ""
        idCategory = object.idCategory ?? ""
        title = object.title ?? ""
        viewCount = object.viewCount ?? ""
        duration = object.duration ?? ""
        channelId = object.channelId ?? ""
        channelTitle = object.channelTitle ?? ""
        channelThumnail = object.channelThumbnail ?? ""
        thumbnail = object.thumbnail ?? ""
        descript = object.descript ?? ""
        timeUpload = object.timeUpload
    }

    convenience required init(history: History) {
        self.init()
        idVideo = history.idVideo ?? ""
        idCategory = history.idCategory ?? ""
        title = history.title ?? ""
        viewCount = history.viewCount ?? ""
        duration = history.duration ?? ""
        channelId = history.channelId ?? ""
        channelTitle = history.channelTitle ?? ""
        channelThumnail = history.channelThumbnail ?? ""
        thumbnail = history.thumbnail ?? ""
        descript = history.descript ?? ""
    }

    class func cleanData() {
        do {
            let realm = try Realm()
            let videos = realm.objects(self)
            try realm.write({
                realm.delete(videos)
            })
        } catch {

        }
    }
}


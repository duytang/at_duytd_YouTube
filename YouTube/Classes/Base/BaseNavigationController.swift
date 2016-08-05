//
//  BaseNavigationController.swift
//  YouTube
//
//  Created by Duy Tang on 8/6/16.
//  Copyright © 2016 Duy Tang. All rights reserved.
//

import UIKit

class BaseNavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationBar.tintColor = UIColor.whiteColor()
        self.navigationBar.barTintColor = UIColor.whiteColor()
        self.navigationBar.translucent = false
        self.navigationBar.hidden = true
        self.navigationBar.shadowImage = UIImage()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

    }
    func setAttributeForNavigation(title: String, image: String) {
        self.title = title
        self.tabBarItem.image = UIImage(named: image)!.imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal)
        self.tabBarItem.selectedImage = UIImage(named: image)!.imageWithRenderingMode(.AlwaysTemplate)
    }

}
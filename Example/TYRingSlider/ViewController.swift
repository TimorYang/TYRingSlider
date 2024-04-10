//
//  ViewController.swift
//  TYRingSlider
//
//  Created by zhidong.yang on 04/08/2024.
//  Copyright (c) 2024 zhidong.yang. All rights reserved.
//

import UIKit
import TYRingSlider
import SnapKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        setupUI()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - UI
    private func setupUI() {
        view.addSubview(seasonSlider)
        
        seasonSlider.snp.makeConstraints { make in
            make.center.equalTo(view)
            make.size.equalTo(CGSizeMake(300, 300))
        }
    }
    
    // MARK: - Private Property
    private lazy var seasonSlider: TYMultiRingSlider = {
        let slider = TYMultiRingSlider()
        slider.backgroundColor = .white
        slider.thumbImage = UIImage(named: "start")
        slider.maximumValue = 12
        slider.step = 1
        slider.lineWidth = 28
        slider.backtrackLineWidth = 28
        slider.diskColor = UIColor(red: 232 / 255.0, green: 249 / 255.0, blue: 239 / 255.0, alpha: 1)
        slider.diskFillColor = UIColor.blue
        slider.diskImage = UIImage(named: "season_disk")
        slider.diskImageOffset = 5
        slider.radiusOffSet = 20
//        slider.thumbPoints = [9.0, 2.0]
        slider.thumbPoints = [0.0, 3.0, 6.0]
//        slider.thumbPoints = [0.0, 3.0, 6.0, 9.0]
        slider.minDistance = 1
//        slider.trackFillColor = UIColor.clear
        slider.trackColor = UIColor(red: 0.45, green: 0.78, blue: 0.54, alpha: 1)
        slider.stepTickColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.1020)
        slider.stepTickWidth = 4
        slider.stepTickLength = 16
        return slider
    }()

}


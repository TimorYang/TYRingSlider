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
        initData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Init Data
    private func initData() {
        let _timeRange1 = TYRingSliderTimeRange(start: 1 * 60 * 60, end: 3 * 60 * 60, lineColor: .red, showThumb: true)
        let _timeRange2 = TYRingSliderTimeRange(start: 8 * 60 * 60, end: 12 * 60 * 60, lineColor: .blue, showThumb: false)
        let _timeRange3 = TYRingSliderTimeRange(start: 14 * 60 * 60, end: 16 * 60 * 60, lineColor: .purple, showThumb: false)
        let _timeRange4 = TYRingSliderTimeRange(start: 17 * 60 * 60, end: 18 * 60 * 60, lineColor: .orange, showThumb: false)
        rangeSlider.timeRangeList = [_timeRange1, _timeRange2, _timeRange3]
    }
    
    // MARK: - UI
    private func setupUI() {
//        view.addSubview(seasonSlider)
//        
//        seasonSlider.snp.makeConstraints { make in
//            make.center.equalTo(view)
//            make.size.equalTo(CGSizeMake(300, 300))
//        }
        
        view.addSubview(rangeSlider)
        
        rangeSlider.snp.makeConstraints { make in
            make.center.equalTo(view)
            make.size.equalTo(CGSizeMake(300, 300))
        }
        
//        // 创建控件并设置大小和位置
//        let circularControl = CircularControl(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
//        
//        // 通常你可能会希望控件居中显示
//        circularControl.center = view.center
//        
//        // 添加控件到视图
//        view.addSubview(circularControl)
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
    
    private lazy var rangeSlider: TYRangeRingSlider = {
        let slider = TYRangeRingSlider()
        slider.backgroundColor = .white
        slider.startThumbImage = UIImage(named: "start")
        slider.endThumbImage = UIImage(named: "start")
        slider.maximumValue = 24 * 60 * 60
        slider.step = 0.5 * 60 * 60
        slider.lineWidth = 28
        slider.backtrackLineWidth = 28
        slider.diskColor = UIColor(red: 232 / 255.0, green: 249 / 255.0, blue: 239 / 255.0, alpha: 1)
        slider.diskImage = UIImage(named: "time")
        slider.diskImageOffset = 5
        slider.radiusOffSet = 20
        slider.trackFillColor = .blue
        slider.trackColor = UIColor(red: 0.45, green: 0.78, blue: 0.54, alpha: 1)
        slider.stepTickColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.1020)
        slider.stepTickWidth = 2
        slider.stepTickLength = 10
        slider.minDistance = 1 * 60 * 60
        return slider
    }()
    
    private var testSlider:CircularControl {
        let test = CircularControl()
        return test
    }

}


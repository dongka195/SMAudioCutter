//
//  ViewController.swift
//  AudioCutterV2
//
//  Created by Nguyễn Đình Đông on 11/9/18.
//  Copyright © 2018 Hintoro. All rights reserved.
//

import UIKit
import Foundation
import AVFoundation
import CoreAudio

class ViewController: UIViewController {
    
    
    @IBOutlet weak var statTimeLabel:UILabel!
    @IBOutlet weak var endTimeLabel:UILabel!

    
    @IBOutlet weak var waveView:UIView!
    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet weak var leftBar: UIView!
    @IBOutlet weak var rightBar: UIView!
    
    
    @IBOutlet weak var limitedDuration:UIView!
    @IBOutlet weak var draggView:UIView!
    
    @IBOutlet weak var durationLabel:UILabel!
    
    var panGesture = UIPanGestureRecognizer()
    var panGestureR = UIPanGestureRecognizer()

    var startTime:CGFloat = 0.0
    var endTime:CGFloat = 0.0
    
    var limitDuration:CGFloat = 20.0
    var limitBarWidth:CGFloat = 200.0
    
    var bombSoundEffect: AVAudioPlayer?
    let s = 235.55
    var audioDuration:CGFloat = 0.0


    //Thông số trên màn hình
    @IBOutlet weak var limitDurationLabel: UILabel!
    @IBOutlet weak var lblLimit: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.draggedView(_:)))
        leftBar.isUserInteractionEnabled = true
        leftBar.addGestureRecognizer(panGesture)
        
        panGestureR = UIPanGestureRecognizer(target: self, action: #selector(self.draggedViewR(_:)))
        rightBar.isUserInteractionEnabled = true
        rightBar.addGestureRecognizer(panGestureR)
        
        self.renderWave()
        
        //
        let path = Bundle.main.url(forResource: "Thang-Dien-JustaTee-Phuong-Ly", withExtension: "mp3")
        let audioAsset = AVURLAsset.init(url: path!, options: nil)
        let duration = audioAsset.duration
        let durationInSeconds = CMTimeGetSeconds(duration)
//        print("Duuration = \(durationInSeconds)")
        self.audioDuration = CGFloat(durationInSeconds)
        print("Duration = \(self.audioDuration)")
        
    }
    
    func renderWave() {
        let url = Bundle.main.url(forResource: "Thang-Dien-JustaTee-Phuong-Ly", withExtension: "mp3")
        let file = try! AVAudioFile(forReading: url!)
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: file.fileFormat.sampleRate, channels: file.fileFormat.channelCount, interleaved: false)
        print(file.fileFormat.channelCount)
        let buf = AVAudioPCMBuffer(pcmFormat: format!, frameCapacity: UInt32(file.length))
        try! file.read(into: buf!)
        
        // this makes a copy, you might not want that
        readFile.arrayFloatValues = Array(UnsafeBufferPointer(start: buf!.floatChannelData?[0], count:Int(buf!.frameLength)))
        
        //        print("floatArray \(readFile.arrayFloatValues)\n")
        //        self.waveFormView.setNeedsDisplay()
        let waveFormView = DrawWaveform.init(frame:CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: self.containerView.frame.height))
        let width = waveFormView.getWidth()
//        print(width)
        
        waveFormView.frame.size.width = width
        waveFormView.backgroundColor = .clear
        let scrollView = UIScrollView.init(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: self.containerView.frame.height))
        scrollView.contentSize = .init(width: width + 1, height: self.containerView.frame.height)
        scrollView.backgroundColor = UIColor.clear
        scrollView.addSubview(waveFormView)
        self.waveView.addSubview(scrollView)
        scrollView.delegate = self
        
        let path = Bundle.main.url(forResource: "Thang-Dien-JustaTee-Phuong-Ly", withExtension: "mp3")
        
        do {
            bombSoundEffect = try AVAudioPlayer(contentsOf: path!)
            bombSoundEffect?.play()
        } catch {
            // couldn't load file :(
        }
        print("Play audio")
//        self.updateDuration(offSet: <#CGPoint#>)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.changeLimitDuration(num: 40)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    @objc func draggedView(_ sender:UIPanGestureRecognizer){
        self.view.bringSubviewToFront(leftBar)
        let translation = sender.translation(in: self.view)
        leftBar.center = CGPoint(x: leftBar.center.x + translation.x, y: self.leftBar.center.y)
        
        if self.leftBar.frame.origin.x <= 0 {
            self.leftBar.frame.origin.x = 0
        }
        
        if self.leftBar.frame.origin.x >= UIScreen.main.bounds.size.width - 100.0  {
            self.leftBar.frame.origin.x = UIScreen.main.bounds.size.width - 100.0
        }
        self.collisionHandling(translation : translation)
        self.view.updateConstraintsIfNeeded()
        self.view.layoutIfNeeded()
        sender.setTranslation(CGPoint.zero, in: self.view)
    }

    @objc func draggedViewR(_ sender:UIPanGestureRecognizer){
        self.view.bringSubviewToFront(rightBar)
        let translation = sender.translation(in: self.view)
        rightBar.center = CGPoint(x: rightBar.center.x + translation.x, y: self.rightBar.center.y)
        
        if self.rightBar.frame.origin.x >= UIScreen.main.bounds.size.width - self.rightBar.frame.size.width {
            self.rightBar.frame.origin.x = UIScreen.main.bounds.size.width - self.rightBar.frame.size.width
        }
        
        if self.rightBar.frame.origin.x <= 0 + 50 {
            self.rightBar.frame.origin.x = 0 + 50
        }
        collisionHandlingR(translation: translation)
        self.view.updateConstraintsIfNeeded()
        self.view.layoutIfNeeded()
        sender.setTranslation(CGPoint.zero, in: self.view)
    }
    
    
    //Xử lý va chạm
    func collisionHandling(translation : CGPoint) {
        let leftOrigin = self.leftBar.frame.origin.x
        let rightOrigin = self.rightBar.frame.origin.x
        
        let limitedDurationLeftOrigin = self.limitedDuration.frame.origin.x

        let width:CGFloat = 50.0
        
//        print("Lx = \(leftOrigin) -- Rx =\(rightOrigin) -- RL = \(limitedDurationLeftOrigin)")
        
        //TH1: Nếu cạnh phải của L chạm cạnh trái của R thì di chuyển đồng thời R (Kéo sáng phải)
        if leftOrigin + width >= rightOrigin {
            //Cho origin của thanh R = origin của L + chiều rộng của L
            self.rightBar.frame.origin.x = leftOrigin + width
            //Nếu origin của R + width >= Limit origin + width => Đồng thời di chuyển Limit
            if rightOrigin + 50.0 >= limitedDurationLeftOrigin + limitBarWidth {
                self.limitedDuration.frame.origin.x = rightOrigin + 50.0 - limitBarWidth
            }
        }
        
        //TH2: Nếu cạnh trái của L chạm cạnh trái của thanh giới hạn thì di chuyển đồng thời R sang trái (Kéo sáng trái)
        if leftOrigin <= limitedDurationLeftOrigin {
            //Cho origin của Limit = origin của thanh L
            self.limitedDuration.frame.origin.x = leftOrigin
            //Nếu origin của R + width = origin của L + Width của Limit thì đồng thời kéo R theo
            if (rightOrigin + 50.0 ) >= (limitedDurationLeftOrigin + limitBarWidth) {
                self.rightBar.frame.origin.x = limitedDurationLeftOrigin + limitBarWidth - 50.0
            }
        }
        self.updateDraggView()
        self.view.updateConstraintsIfNeeded()
        self.view.layoutIfNeeded()
    }
    
    //Xử lý va chạm
    func collisionHandlingR(translation : CGPoint) {
        let leftOrigin = self.leftBar.frame.origin.x
        let rightOrigin = self.rightBar.frame.origin.x
        
        let limitedDurationLeftOrigin = self.limitedDuration.frame.origin.x
        
        let width:CGFloat = 50.0 // Chiều rộng của L hoặc R
        
//        print("Lx = \(leftOrigin) -- Rx =\(rightOrigin) -- RL = \(limitedDurationLeftOrigin)")
        
        //TH1: Nếu cạnh trái của R chạm cạnh phải của L thì di chuyển đồng thời L (Kéo sáng trái)
        if rightOrigin <= leftOrigin + width {
            //Cho origin của thanh L = origin của R - chiều rộng của L
            self.leftBar.frame.origin.x = rightOrigin - width
            //Nếu origin của L >= Limit origin => Đồng thời di chuyển Limit
            if leftOrigin <= limitedDurationLeftOrigin {
                self.limitedDuration.frame.origin.x = leftOrigin
            }
        }
        
        //TH2: Nếu cạnh phải của R chạm cạnh phải của thanh giới hạn thì di chuyển đồng thời L sang phải (Kéo sáng phải)
        if rightOrigin + width >= limitedDurationLeftOrigin + limitBarWidth {
            //Cho origin của Limit = origin của thanh R + width R - space Limit
            self.limitedDuration.frame.origin.x = rightOrigin + 50.0 - limitBarWidth
            //Nếu origin của L = origin của Limit thì đồng thời kéo R theo
            if leftOrigin <= limitedDurationLeftOrigin {
                self.leftBar.frame.origin.x = limitedDurationLeftOrigin
            }
        }
        self.updateDraggView()
        self.view.updateConstraintsIfNeeded()
        self.view.layoutIfNeeded()
    }
    
    func updateDraggView() {
        self.draggView.frame.origin.x = self.leftBar.frame.origin.x
        self.draggView.frame.size.width = self.rightBar.frame.origin.x + self.rightBar.frame.size.width - self.draggView.frame.origin.x
        self.updateTimmer()
        
    }
    
    //Tính toán thời gian
    func updateTimmer() {
        let draggViewWidth = self.draggView.frame.size.width
        let denta = self.limitDuration / self.limitBarWidth
        let duration = denta * draggViewWidth
        self.durationLabel.text = String(format: "%.0f", duration) + "s"
    }
    
    //Cập nhận view
    func updateUI() {
        self.limitDurationLabel.text = "Độ dài giới hạn = \(self.limitDuration)"
        
        let screenWidth = UIScreen.main.bounds.size.width
        let maxDuration:CGFloat = 40.0
        UIView.animate(withDuration: 0.5) {
            let denta = maxDuration / screenWidth
            self.limitedDuration.frame.size.width = self.limitDuration / denta
            self.limitBarWidth = self.limitDuration / denta
            self.leftBar.frame.origin.x = 0
            self.rightBar.frame.origin.x = self.limitedDuration.frame.size.width - self.rightBar.frame.size.width
            self.limitedDuration.frame.origin.x = 0
            self.updateDraggView()
        }

        
    }
    
    //Thay đổi độ dài của âm thanh mặc định mặc định
    func changeLimitDuration(num:Int) {
        self.limitDuration = CGFloat(num)
        self.updateUI()
        self.updateDraggView()
        self.lblLimit.text = "Limit width = \(self.limitedDuration.frame.size.width)"
//        print(UIScreen.main.bounds.size.width)
    }
    
    func updateDuration(offSet:CGPoint) {
        print("Content offset = \(offSet.x)")
        let denta = self.audioDuration / 1732.5
        let t = offSet.x * denta
//        print("---> \(t)")
//        print("Content offset = \(offSet.y) <-> time = \(t)")
        self.startTime = t
        endTime = startTime + 40.0
        self.statTimeLabel.text = String(format: "%.0f", startTime) + "s"
        self.endTimeLabel.text = String(format: "%.0f", endTime) + "s"

    }
    
    
    //Action
    
    @IBAction func set10s(_ sender: Any) {
        changeLimitDuration(num: 10)
    }
    @IBAction func set20s(_ sender: Any) {
        changeLimitDuration(num: 20)
    }
    @IBAction func set30s(_ sender: Any) {
        changeLimitDuration(num: 30)
    }
    @IBAction func set40s(_ sender: Any) {
        changeLimitDuration(num: 40)
    }
    
    
}

extension ViewController : UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.updateDuration(offSet: scrollView.contentOffset)
    }
}


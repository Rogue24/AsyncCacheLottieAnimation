//
//  ViewController.swift
//  LottieDemo
//
//  Created by 周健平 on 2020/11/4.
//

import UIKit

class ViewController: UIViewController {

    var isPlaying = false
    let filePath = Bundle.main.path(forResource: "appgift_fire", ofType: nil, inDirectory: "LottieResource")!
    
    @IBAction func noCacheToPlay() {
        guard isPlaying == false else {
            JPrint("正在播放中，等会再点~")
            return
        }
        
        isPlaying = true
        AsyncAnimationView.originPlayAnimation(withFilePaths: [filePath], addToSuperview: view) { [weak self] in
            JPrint("播放结束")
            self?.isPlaying = false
        }
    }
    
    @IBAction func cacheToPlay() {
        guard isPlaying == false else {
            JPrint("正在播放中，等会再点~")
            return
        }
        
        isPlaying = true
        AsyncAnimationView.playAnimation(withFilePaths: [filePath], isPreDecode: false, addToSuperview: view) { [weak self] in
            JPrint("播放结束")
            self?.isPlaying = false
        }
    }
    
    @IBAction func cacheAndDecodeToPlay() {
        guard isPlaying == false else {
            JPrint("正在播放中，等会再点~")
            return
        }
        
        isPlaying = true
        AsyncAnimationView.playAnimation(withFilePaths: [filePath], addToSuperview: view) { [weak self] in
            JPrint("播放结束")
            self?.isPlaying = false
        }
    }
}


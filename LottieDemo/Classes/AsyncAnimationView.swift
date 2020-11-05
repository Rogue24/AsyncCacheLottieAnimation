//
//  AsyncAnimationView.swift
//  Neves_Example
//
//  Created by aa on 2020/10/22.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import Lottie

class AsyncAnimationView: UIView {
    
    fileprivate struct CacheImageProvider: AnimationImageProvider {
        let images: [String: CGImage]
        func imageForAsset(asset: ImageAsset) -> CGImage? {
            images[asset.name] ?? nil
        }
    }
    
    fileprivate struct AnimItem {
        let filePath: String
        let animTag: Int
        var playCount: Int = 1
        var subItems: [AnimSubItem] = []
    }
    
    fileprivate struct AnimSubItem {
        let viewTag: Int
        let anim: Animation?
        let provider: AnimationImageProvider?
    }
    
    fileprivate var animItems: [AnimItem] = []
    
    typealias AnimDone = () -> ()
    var animDone: AnimDone? = nil
    
    private let isPreCache: Bool
    private let isPreDecode: Bool
    
    class func playAnimation(withFilePaths filePaths: [String], isPreDecode: Bool = true, addToSuperview sView: UIView, at index: Int = -1, animDone: AnimDone? = nil) {
        guard filePaths.count > 0 else { return }
        let animView = AsyncAnimationView(isPreCache: true, isPreDecode: isPreDecode, animDone: animDone)
        animView.add(toSuperview: sView, at: index)
        animView.prepareToPlay(filePaths)
    }
    
    class func originPlayAnimation(withFilePaths filePaths: [String], addToSuperview sView: UIView, at index: Int = -1, animDone: AnimDone? = nil) {
        guard filePaths.count > 0 else { return }
        let animView = AsyncAnimationView(isPreCache: false, isPreDecode: false, animDone: animDone)
        animView.add(toSuperview: sView, at: index)
        animView.prepareToPlay(filePaths)
    }
    
    init(isPreCache: Bool = true, isPreDecode: Bool = true, animDone: AnimDone?) {
        self.animDone = animDone
        self.isPreCache = isPreCache
        self.isPreDecode = isPreDecode
        super.init(frame: PortraitScreenBounds)
        backgroundColor = .clear
        clipsToBounds = true
        isUserInteractionEnabled = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func add(toSuperview sView: UIView, at index: Int) {
        if index < 0 {
            sView.addSubview(self)
        } else {
            sView.insertSubview(self, at: index)
        }
    }
    
    deinit {
        JPrint("老子死了")
    }
}

extension AsyncAnimationView {
    private func prepareToPlay(_ filePaths: [String]) {
        DispatchQueue.global().async {
            // 去重：如果文件名一样，就设置playCount，不重复创建了
            var animItems = [String: AnimItem]()
            var animTag = 0
            for filePath in filePaths {
                if var animItem = animItems[filePath] {
                    animItem.playCount += 1
                    animItems[filePath] = animItem
                    self.animItems[animItem.animTag] = animItem
                } else {
                    let animItem = AnimItem(filePath: filePath, animTag: animTag)
                    animItems[filePath] = animItem
                    self.animItems.append(animItem)
                    animTag += 1
                }
            }
            
            DispatchQueue.concurrentPerform(iterations: self.animItems.count) { [weak self] in
                guard let self = self else { return }
                var animItem = self.animItems[$0]
                
                /*
                 * packageJson:
                     {
                         "list": [{
                             ...... // 其他的布局信息
                             "packageName": "appgift_fire_animation", // json文件和图片资源的文件夹名字
                         }],
                         "totalTime": 6500
                     }
                 */
                
                let packageJson = URL(fileURLWithPath: animItem.filePath).appendingPathComponent("package.json")
                
                guard let config = try? JSONSerialization.jsonObject(with: Data(contentsOf: packageJson), options: .allowFragments),
                      let configDic = config as? [String: Any],
                      let configList = configDic["list"] as? [[String: Any]] else { return }
                
                for i in 0..<configList.count {
                    let subConfig = configList[i]
                    guard let packageName = subConfig["packageName"] as? String else { break }
                    
                    let animDirPath = packageJson.deletingLastPathComponent().appendingPathComponent(packageName).path
                    
                    guard let objs: (Animation?, AnimationImageProvider?) = Self.createAnimationAndImageProvider(animDirPath, self.isPreCache, self.isPreDecode) else { break }
                    
                    /*
                     * viewTag ==> 1 01
                                   ↓ ↓↓
                                   ↓ →→→→→→→→→→→→→→→→→→→→→→→→→→→
                                   ↓                          ↓↓
                                   ↓                    当前Lottie的tag animTag
                            当前Lottie里面的第几个元素的tag
                     */
                    let subItem = AnimSubItem(viewTag: animItem.animTag + (i + 1) * 100,
                                              anim: objs.0,
                                              provider: objs.1)
                    animItem.subItems.append(subItem)
                    
                    DispatchQueue.main.sync {
                        let animView = AnimationView(animation: subItem.anim, imageProvider: subItem.provider)
                        animView.contentMode = .scaleToFill
                        animView.tag = subItem.viewTag
                        animView.frame = PortraitScreenBounds
                        animView.isHidden = true
                        self.addSubview(animView)
                    }
                }
                
                self.animItems[$0] = animItem
            }
            
            DispatchQueue.main.async { [weak self] in self?.playAll() }
        }
        
    }
    
    private func playAll() {
        guard let animItem = self.animItems.first else {
            animDone?()
            self.removeFromSuperview()
            return
        }
        
        self.animItems.remove(at: 0)
        
        let playCount = Float(animItem.playCount)
        
        let total = animItem.subItems.count
        let allDone = { [weak self] (count: Int) in
            if count == total { self?.playAll() }
        }
        
        var currCount = 0
        for i in 0..<animItem.subItems.count {
            let subItem = animItem.subItems[i]
            
            guard let animView = viewWithTag(subItem.viewTag) as? AnimationView else {
                currCount += 1
                allDone(currCount)
                return
            }
            
            animView.isHidden = false
            animView.play(toProgress: 1, loopMode: .repeat(playCount)) { [weak animView] _ in
                animView?.removeFromSuperview()
                currCount += 1
                allDone(currCount)
            }
        }
    }
}

extension AsyncAnimationView {
    static func createAnimationAndImageProvider(_ animDirPath: String, _ isPreCache: Bool, _ isPreDecode: Bool) -> (Animation?, AnimationImageProvider?)? {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: animDirPath) else { return nil }
        
        let animJsonPath = animDirPath + "/data.json"
        let imageDirPath = animDirPath + "/images"
        
        guard fileManager.fileExists(atPath: animJsonPath) else { return nil }
        
        let anim = Animation.filepath(animJsonPath)
        
        guard fileManager.fileExists(atPath: imageDirPath) else { return (anim, nil) }
        
        // TODO: 可以考虑用NSCache缓存在内存，具有时效性的缓存
        let provider: AnimationImageProvider
        if isPreCache, let fileNames = try? fileManager.subpathsOfDirectory(atPath: imageDirPath) {
            
            var images: [String: CGImage] = [:]
            for fileName in fileNames {
                let imagePath = imageDirPath + "/\(fileName)"
                guard let image = UIImage(contentsOfFile: imagePath) else { break }
                
                if isPreDecode {
                    guard let cgImage = image.jp.decode() else { break }
                    images[fileName] = cgImage
                } else {
                    guard let cgImage = image.cgImage else { break }
                    images[fileName] = cgImage
                }
            }
            
            provider = CacheImageProvider(images: images)
            
        } else {
            provider = FilepathImageProvider(filepath: animDirPath)
        }
        
        return (anim, provider)
    }
}

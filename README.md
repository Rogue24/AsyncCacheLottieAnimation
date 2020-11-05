# AsyncCacheLottieAnimation

## 使用Lottie动画导致内存暴增的原因之一

> 众所周知，Lottie是个非常赞的动画库，不过如果稍不注意，就会导致内存暴增，这里介绍其中一种情况。

最近公司有个需求是要在直播房间内播放一个礼物动画，用的是 **Lottie**，但是播放动画时，会卡个两秒，这种体验是十分不好的，另外播放期间内存会暴增至900+M，非常危险！必须得解决这个问题。

![](https://github.com/Rogue24/JPCover/raw/master/AsyncCacheLottieAnimation/image0.jpg)

首先使用 **Time Profiler** 定位到卡顿的位置是在`LayerImageProvider`的`reloadImages()`这个函数（这是用来加载动画的资源图片）

![](https://github.com/Rogue24/JPCover/raw/master/AsyncCacheLottieAnimation/image1.jpg)

因为我们项目的礼物动画是会用到本地图片的，需要使用`AnimationView(animation:, imageProvider:)`方式创建动画，指定资源路径：

![动画文件结构](https://github.com/Rogue24/JPCover/raw/master/AsyncCacheLottieAnimation/image2.jpg)

而`reloadImages`内部通过循环调用`imageProvider.imageForAsset(asset:)`来加载的，再点进去看看详细的代码：
![](https://github.com/Rogue24/JPCover/raw/master/AsyncCacheLottieAnimation/image3.jpg)

原来 **Lottie** 是这么简单粗暴的加载图片（众所周知，`UIImage(contentsOfFile:)`方式创建的图片是不会缓存的，好处是使用完就能销毁，不过每次调用都是一个新的UIImage对象，不适合用在复用性高的图片），不过整个礼物动画也就20张小图片而已，怎么就暴增到900+M呢，在`imageForAsset`里面打印一下调用情况：
![](https://github.com/Rogue24/JPCover/raw/master/AsyncCacheLottieAnimation/image4.jpg)

哇靠，好家伙，果然，即便同一张图片都重复创建了200+次，何况20张，一两秒内就加载了差不多4000多张，不卡才怪，难怪内存暴增900+M。

发现问题所在就好解决了，先将图片缓存起来，在动画播放期间内复用，不要重复创建即可。

好在 **Lottie** 可以让我们自定义`imageProvider`，做法很简单，初始化时先将 UIImage 缓存起来，再创建动画：
```swift
struct CacheImageProvider: AnimationImageProvider {
    let images: [String: CGImage]
    func imageForAsset(asset: ImageAsset) -> CGImage? {
        images[asset.name] ?? nil
    }
}
        
func startAnimation() {
    let anim = Animation.filepath(animJsonPath)

    var images: [String: CGImage] = [:]
    
    for fileName in fileNames {
        let imagePath = imageDirPath + "/\(fileName)" // 拼接完整路径
        guard let image = UIImage(contentsOfFile: imagePath) else { break }
        images[fileName] = cgImage
    }
    let provider = CacheImageProvider(images: images)
            
    let animView = AnimationView(animation: anim, imageProvider: subItem.provider)
    self.addSubview(animView)
    animView.play()
}
```
立马试试，不会再卡个两秒了，爽，再看看内存：

![](https://github.com/Rogue24/JPCover/raw/master/AsyncCacheLottieAnimation/image5.jpg)

最高也就60M，并且动画结束就释放，舒服了~

另外，既然是提前缓存，可以参考`YYWebImage`的做法，再加个异步解码吧（系统默认是图片显示的那一刻才会解码，并且解码过程是在主线程），这样主线程就更加顺滑了：
```swift
struct CacheImageProvider: AnimationImageProvider {
    let images: [String: CGImage]
    func imageForAsset(asset: ImageAsset) -> CGImage? {
        images[asset.name] ?? nil
    }
}
        
func startAnimation() {
    DispatchQueue.global().async {
        let anim = Animation.filepath(animJsonPath)

        var images: [String: CGImage] = [:]
        
        for fileName in fileNames {
            let imagePath = imageDirPath + "/\(fileName)" // 拼接完整路径
            guard let image = UIImage(contentsOfFile: imagePath) else { break }
            guard let cgImage = image.jp.decode() else { break } // 解码
            images[fileName] = cgImage
        }
        let provider = CacheImageProvider(images: images)
                
        DispatchQueue.main.sync {
            let animView = AnimationView(animation: anim, imageProvider: subItem.provider)
            self.addSubview(animView)
            animView.play()
        }
    }
}
```
最终效果：

![](https://github.com/Rogue24/JPCover/raw/master/AsyncCacheLottieAnimation/gift.gif)

而且内存进一步减少至49M左右，看来使用`CGBitmap`方式绘制的图片更适用于手机的显示（猜的）：

![](https://github.com/Rogue24/JPCover/raw/master/AsyncCacheLottieAnimation/image6.jpg)

到此为止最棘手的问题算是解决了~

**特别声明：这个内存暴增的问题是我们公司iOS大佬发现的，十分感激他，以后要多向他学习。**

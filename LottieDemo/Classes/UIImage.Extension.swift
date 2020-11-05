//
//  UIImage.Extension.swift
//  LottieDemo
//
//  Created by 周健平 on 2020/11/4.
//

import UIKit

extension UIImage: JPCompatible {}
extension JP where Base: UIImage {
    func decode() -> CGImage? {
        guard let cgImg = base.cgImage else { return nil }
        
        let width = cgImg.width
        let height = cgImg.height
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        var bitmapRawValue = CGBitmapInfo.byteOrder32Little.rawValue
        let alphaInfo = cgImg.alphaInfo
        if alphaInfo == .premultipliedLast ||
            alphaInfo == .premultipliedFirst ||
            alphaInfo == .last ||
            alphaInfo == .first {
            bitmapRawValue += CGImageAlphaInfo.premultipliedFirst.rawValue
        } else {
            bitmapRawValue += CGImageAlphaInfo.noneSkipFirst.rawValue
        }
        
        guard let context = CGContext(data: nil,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: 8,
                                      bytesPerRow: 0,
                                      space: colorSpace,
                                      bitmapInfo: bitmapRawValue) else { return cgImg }
        context.draw(cgImg, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        let decodeImg = context.makeImage()
        return decodeImg
    }
}

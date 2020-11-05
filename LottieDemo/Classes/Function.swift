//
//  Function.swift
//  Neves_Example
//
//  Created by aa on 2020/10/12.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit

func JPrint(_ msg: Any..., file: NSString = #file, line: Int = #line, fn: String = #function) {
#if DEBUG
    guard msg.count != 0, let lastItem = msg.last else { return }

    let date = hhmmssSSFormatter.string(from: Date()).utf8
    let fileName = (file.lastPathComponent as NSString).deletingPathExtension
    let prefix = "[\(date)] [\(fileName) \(fn)] [第\(line)行]:"
    print(prefix, terminator: " ")

    let maxIndex = msg.count - 1
    for item in msg[..<maxIndex] {
        print(item, terminator: " ")
    }

    print(lastItem)
#endif
}

func swapValues<T>(_ a: inout T, _ b: inout T) {
    (a, b) = (b, a)
}

func ScaleValue(_ value: CGFloat) -> CGFloat {
    value * BasisWScale
}

func ScaleValue(_ value: Double) -> CGFloat {
    CGFloat(value) * BasisWScale
}

func ScaleValue(_ value: Float) -> CGFloat {
    CGFloat(value) * BasisWScale
}

func ScaleValue(_ value: Int) -> CGFloat {
    CGFloat(value) * BasisWScale
}

func HalfDiffValue(_ superValue: CGFloat, _ subValue: CGFloat) -> CGFloat {
    (superValue - subValue) * 0.5
}

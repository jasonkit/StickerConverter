//
//  UIImage+ensureSize.swift
//  StickerConverter
//
//  Created by Jason Wu on 30/10/2018.
//  Copyright © 2018 Jason Wu. All rights reserved.
//

import UIKit

extension UIImage {
    func resize(newSize: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: CGRect(origin: CGPoint.zero, size: CGSize(width: newSize.width, height: newSize.height)))
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }

    func pad(x: CGFloat, y: CGFloat) -> UIImage {
        let width: CGFloat = size.width + x
        let height: CGFloat = size.height + y
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, 1.0)
        let origin: CGPoint = CGPoint(x: (width - size.width) / 2, y: (height - size.height) / 2)
        draw(at: origin)
        let imageWithPadding = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        return imageWithPadding
    }

    func ensureSize(width: CGFloat, height: CGFloat) -> UIImage {
        if self.size.width > width || self.size.height > height {
            if self.size.width > self.size.height {
                return self.resize(newSize: CGSize(width: width, height: width * self.size.height / self.size.width))
                    .ensureSize(width: width, height: height)
            } else {
                return self.resize(newSize: CGSize(width: height * self.size.width / self.size.height, height: height))
                    .ensureSize(width: width, height: height)
            }
        }

        return self.pad(x: width - self.size.width, y: height - self.size.height)
    }
}

//
//  UIImage+WebP.swift
//  StickerConverter
//
//  Created by Jason Wu on 30/10/2018.
//  Copyright © 2018 Jason Wu. All rights reserved.
//

import UIKit

extension UIImage {
    static func fromWebP(data: Data) -> UIImage {
        let decoder = YYImageDecoder(data: data, scale: 1.0)!
        return decoder.frame(at: 0, decodeForDisplay: true)!.image!
    }

    func toWebP() -> Data {
        let encoder = YYImageEncoder(type: .webP)!
        encoder.add(self, duration: 0.0)
        return encoder.encode()!
    }
}

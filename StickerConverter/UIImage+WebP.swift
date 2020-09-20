//
//  UIImage+WebP.swift
//  StickerConverter
//
//  Created by Jason Wu on 30/10/2018.
//  Copyright © 2018 Jason Wu. All rights reserved.
//

import UIKit
import WebP

extension UIImage {
    static func fromWebP(data: Data) -> UIImage {
        let decoder = WebPDecoder()
        let cgImage = try! decoder.decode(data, options: WebPDecoderOptions())
        return UIImage(cgImage: cgImage)
    }

    func toWebP() -> Data {
        let encoder = WebPEncoder()
        return try! encoder.encode(self, config: .preset(.picture, quality: 100))
    }
}

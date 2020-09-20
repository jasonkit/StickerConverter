//
//  convert.swift
//  StickerConverter
//
//  Created by Jason Wu on 30/10/2018.
//  Copyright © 2018 Jason Wu. All rights reserved.
//

import Foundation
import PromiseKit
import RxCocoa
import RxSwift
import UIKit

let kNumStickerInPack = 30

class StickerConverter {
    private let telegramAPIClient: TelegramAPIClient
    let progress: PublishRelay<String> = PublishRelay()

    init(telegramAPIClient: TelegramAPIClient) {
        self.telegramAPIClient = telegramAPIClient
    }

    func convertStickerSet(from: TGStickerSet) -> Promise<SCStickerPack> {
        self.progress.accept("Fetching each sticker in the sticker set...")
        let promises = from.stickers.map { sticker in
            return self.telegramAPIClient.downloadFile(fileId: sticker.fileId).then { (data: Data?) -> Promise<SCSticker> in
                let image = UIImage.fromWebP(data: data!)
                let stickerPack = SCSticker(emojis: sticker.emoji.map { [$0] } ?? [], image: image.ensureSize(width: 512, height: 512))
                DispatchQueue.main.async { [weak self] in
                    self?.progress.accept("Fetched \(sticker.fileId)")
                }
                return .value(stickerPack)
            }
        }

        return when(fulfilled: promises.makeIterator(), concurrently: 4).then { (stickers: [SCSticker]) -> Promise<SCStickerPack> in
            return .value(SCStickerPack(name: from.name, title: from.title, stickers: stickers))
        }
    }

    func convertStickerSet(from: SCStickerPack) -> Promise<[WAStickerPack]> {
        self.progress.accept("Converting Telegram stacker set to Whatsapp sticker pack")
        let promises = from.stickers.map { sticker in
            return Promise<WASticker> { resolver in
                let webp = sticker.image.toWebP()
                print(webp.count)
                let data = webp.base64EncodedString()
                resolver.fulfill(WASticker(imageData: data, emojis: sticker.emojis))
            }
        }

        return when(fulfilled: promises.makeIterator(), concurrently: 4).then { (stickers: [WASticker]) -> Promise<[WAStickerPack]> in
            let stickerPacks = self.splitStickers(stickers: stickers).enumerated().map { item -> WAStickerPack in
                let trayImageData = from.stickers[item.offset * kNumStickerInPack].image.resize(newSize: CGSize(width: 96, height: 96)).pngData()!.base64EncodedString()
                return WAStickerPack(
                    identifier: stickers.count > kNumStickerInPack ? "\(from.name)-\(item.offset + 1)" : from.name,
                    name: stickers.count > kNumStickerInPack ? "\(from.title) \(item.offset + 1)" : from.title,
                    trayImage: trayImageData, publisher: "Sticker Converter", stickers: item.element
                )
            }
            return .value(stickerPacks)
        }
    }

    private func splitStickers(stickers: [WASticker]) -> [[WASticker]] {
        var stickerSet: [[WASticker]] = []
        var index = 0
        for sticker in stickers {
            if stickerSet.count == index {
                stickerSet.append([])
            }
            stickerSet[index].append(sticker)
            if stickerSet[index].count == kNumStickerInPack {
                index += 1
            }
        }
        return stickerSet
    }
}

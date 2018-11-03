//
//  models.swift
//  StickerConverter
//
//  Created by Jason Wu on 30/10/2018.
//  Copyright © 2018 Jason Wu. All rights reserved.
//

import UIKit

struct TelegramResponse<T: Codable>: Codable {
    let ok: Bool
    let result: T?
    let errorCode: Int?
    let description: String?
}

struct TGStickerSet: Equatable, Codable {
    let name: String
    let title: String
    let containsMasks: Bool
    let stickers: [TGSticker]
}

struct TGSticker: Equatable, Codable {
    let fileId: String
    let width: Int
    let height: Int
    let thumb: TGPhotoSize?
    let emoji: String?
    let setName: String?
    let maskPosition: TGMaskPosition?
    let fileSize: Int?
}

struct TGPhotoSize: Equatable, Codable {
    let fileId: String
    let width: Int
    let height: Int
    let fileSize: Int?
}

struct TGMaskPosition: Equatable, Codable {
    let point: String
    let xShift: Float
    let yShift: Float
    let scale: Float
}

struct TGFile: Equatable, Codable {
    let fileId: String
    let fileSize: Int?
    let filePath: String?
}

struct SCStickerPack: Equatable {
    var name: String
    var title: String
    var stickers: [SCSticker]
}

struct SCSticker: Equatable {
    var emojis: [String]
    var image: UIImage
}

struct WAStickerPack: Equatable, Codable {
    var identifier: String
    var name: String
    var trayImage: String
    var publisher: String
    var stickers: [WASticker]
}

struct WASticker: Equatable, Codable {
    var imageData: String
    var emojis: [String]
}

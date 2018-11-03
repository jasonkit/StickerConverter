//
//  SCError.swift
//  StickerConverter
//
//  Created by Jason Wu on 28/10/2018.
//  Copyright © 2018 Jason Wu. All rights reserved.
//

import Foundation

enum SCError: Error {
    case requestError
    case stickerSetNotFound
    case modelSerializationError(model: String)
}

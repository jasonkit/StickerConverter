//
//  TelegramAPIClient.swift
//  StickerConverter
//
//  Created by Jason Wu on 28/10/2018.
//  Copyright © 2018 Jason Wu. All rights reserved.
//

import Alamofire
import Foundation
import PromiseKit

class TelegramAPIClient {
    private let token: String

    private lazy var url: String = {
        "https://api.telegram.org/bot\(self.token)"
    }()

    private lazy var fileUrl: String = {
        "https://api.telegram.org/file/bot\(self.token)"
    }()

    init(token: String) {
        self.token = token
    }

    private func makeRequest<T: Codable>(method: String, parameters: Parameters) -> Promise<T> {
        return Promise<T> { resolver in
            Alamofire.request("\(self.url)/\(method)", method: .post, parameters: parameters,
                              encoding: JSONEncoding.default).responseJSON { response in
                switch response.result {
                case .success:
                    do {
                        let resp = try TelegramResponse<T?>.fromJSON(decoder: JSONDecoder.createDefault(), response.data!)
                        if resp.ok {
                            resolver.fulfill(resp.result!!)
                        } else {
                            resolver.reject(SCError.requestError)
                        }

                    } catch {
                        resolver.reject(error)
                    }
                case let .failure(error):
                    resolver.reject(error)
                }
            }
        }
    }

    func getStickerSet(name: String) -> Promise<TGStickerSet> {
        return self.makeRequest(method: "getStickerSet", parameters: ["name": name])
    }

    func getFile(fileId: String) -> Promise<TGFile> {
        return self.makeRequest(method: "getFile", parameters: ["file_id": fileId])
    }

    func downloadFile(path: String) -> Promise<Data?> {
        let url = "\(self.fileUrl)/\(path)"
        return Promise { resolver in
            Alamofire.request(url).responseData { response in
                if let data = response.result.value {
                    resolver.fulfill(data)
                } else {
                    resolver.fulfill(nil)
                }
                if response.error != nil {
                    print(response.error!.localizedDescription)
                }
            }
        }
    }

    func downloadFile(fileId: String) -> Promise<Data?> {
        return self.getFile(fileId: fileId)
            .then { [weak self] (file: TGFile) -> Promise<Data?> in
                guard let `self` = self,
                    let path = file.filePath else { return .value(nil) }
                return self.downloadFile(path: path)
            }
    }
}

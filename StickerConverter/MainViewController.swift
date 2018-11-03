//
//  MainViewController.swift
//  StickerConverter
//
//  Created by Jason Wu on 28/10/2018.
//  Copyright © 2018 Jason Wu. All rights reserved.
//

import PromiseKit
import RxCocoa
import RxSwift
import SnapKit
import UIKit

let kTelegramBotToken = "INSERT_TELEGRAM_BOT_TOKEN_HERE"

struct LocalState {
    let stickerSetName: BehaviorRelay<String?> = BehaviorRelay(value: nil)
}

class MainViewController: UIViewController {
    private let state = LocalState()
    private let telegramApiClient = TelegramAPIClient(token: kTelegramBotToken)
    private lazy var stickerConverter: StickerConverter = {
        let converter = StickerConverter(telegramAPIClient: self.telegramApiClient)
        return converter
    }()

    private let disposeBag = DisposeBag()

    private var serializedStickerPacks: [[String: Any]] = []

    private let stickerSetNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.text = "Telegram Sticker Set"
        return label
    }()

    private let stickerSetNameTextField: UITextField = {
        let field = UITextField()
        field.text = "DoraemonLinepack"
        field.placeholder = "Enter telegram sticker set name"
        return field
    }()

    private let stickerSetNameTextFieldLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.lightGray
        return view
    }()

    private let getButton: UIButton = {
        let button = UIButton(type: .roundedRect)
        button.setTitle("GET", for: .normal)
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.lightGray.cgColor
        button.layer.cornerRadius = 5
        return button
    }()

    private let progressLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 10)
        label.textColor = UIColor.lightGray
        return label
    }()

    private let stackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 10
        return view
    }()

    private let paddingView = UIView()

    private var buttons: [UIButton] = []
    private var buttonDisposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .white
        self.layoutSubviews()
        self.binding()
    }

    private func layoutSubviews() {
        self.view.addSubview(self.stickerSetNameLabel)
        self.stickerSetNameLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(20)
            make.top.equalTo(self.topLayoutGuide.snp.bottom).offset(10)
        }

        self.view.addSubview(self.stickerSetNameTextField)
        self.stickerSetNameTextField.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(20)
            make.top.equalTo(self.stickerSetNameLabel.snp.bottom).offset(10)
        }

        self.view.addSubview(self.stickerSetNameTextFieldLine)
        self.stickerSetNameTextFieldLine.snp.makeConstraints { make in
            make.left.right.equalTo(self.stickerSetNameTextField)
            make.top.equalTo(self.stickerSetNameTextField.snp.bottom).offset(2)
            make.height.equalTo(1)
        }

        self.view.addSubview(self.getButton)
        self.getButton.snp.makeConstraints { make in
            make.left.equalTo(self.stickerSetNameTextField.snp.right).offset(10)
            make.right.equalToSuperview().inset(20)
            make.width.equalTo(50)
            make.centerY.equalTo(self.stickerSetNameTextField.snp.centerY)
        }

        self.view.addSubview(self.progressLabel)
        self.progressLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(20)
            make.top.equalTo(self.stickerSetNameTextFieldLine.snp.bottom).offset(10)
        }

        self.view.addSubview(self.stackView)
        self.stackView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(20)
            make.top.equalTo(self.progressLabel.snp.bottom).offset(10)
            make.bottom.equalToSuperview().inset(10)
        }

        self.stackView.addArrangedSubview(self.paddingView)
    }

    private func binding() {
        self.stickerSetNameTextField.rx.value
            .bind(to: self.state.stickerSetName)
            .disposed(by: self.disposeBag)

        self.getButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                self?.getButton.isEnabled = false
                self?.fetchStickerSet()
            })
            .disposed(by: self.disposeBag)

        self.stickerConverter.progress.bind(to: self.progressLabel.rx.text).disposed(by: self.disposeBag)
    }

    private func fetchStickerSet() {
        if (self.state.stickerSetName.value ?? "").trimmingCharacters(in: .whitespaces).count == 0 {
            self.presentError(message: "Please enter sticker name first!")
            return
        }

        for view in self.buttons {
            self.stackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        self.buttons = []
        self.buttonDisposeBag = DisposeBag()

        self.progressLabel.text = "Fetching sticker set from Telegram..."
        self.telegramApiClient.getStickerSet(name: self.state.stickerSetName.value!)
            .then(self.stickerConverter.convertStickerSet)
            .then(self.stickerConverter.convertStickerSet)
            .then { (stickerPacks: [WAStickerPack]) -> Promise<[[String: Any]]> in
                return when(fulfilled: stickerPacks.map { stickerPack in
                    stickerPack.toJSON(encoder: JSONEncoder.createDefault())
                })
            }
            .done { packs in
                self.progressLabel.text = "Done"
                self.serializedStickerPacks = packs
                for (index, pack) in packs.enumerated() {
                    let button = UIButton(type: .roundedRect)
                    button.backgroundColor = .lightGray
                    button.setTitle(pack["name"] as? String, for: .normal)
                    button.setTitleColor(.black, for: .normal)
                    button.rx.tap.bind {
                        _ = self.sendToWhatsapp(json: pack)
                    }
                    .disposed(by: self.buttonDisposeBag)
                    self.stackView.insertArrangedSubview(button, at: index)
                    self.buttons.append(button)
                    self.getButton.isEnabled = true
                }
            }
            .catch { error in
                print(error)
                self.presentError(message: "Error")
                self.getButton.isEnabled=true
            }
    }

    private func sendToWhatsapp(json: [String: Any]) -> Promise<Void> {
        guard let data = try? JSONSerialization.data(withJSONObject: json, options: []) else { return .value(()) }
        return Promise<Void> { resolver in
            let pasteboard = UIPasteboard.general
            pasteboard.setItems([["net.whatsapp.third-party.sticker-pack": data]],
                                options: [
                                    UIPasteboard.OptionsKey.localOnly: true,
                                    UIPasteboard.OptionsKey.expirationDate: NSDate(timeIntervalSinceNow: 60),
            ])

            DispatchQueue.main.async {
                if UIApplication.shared.canOpenURL(URL(string: "whatsapp://")!) {
                    UIApplication.shared.open(URL(string: "whatsapp://stickerPack")!, options: [:], completionHandler: nil)
                }
                resolver.fulfill(())
            }
        }
    }

    private func presentError(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true)
    }
}

//
//  CryptoCurrencyMonitor.swift
//  CoinMenuBar
//
//  Created by Horváth Balázs on 2017. 08. 29..
//  Copyright © 2017. Horváth Balázs. All rights reserved.
//

import Cocoa

class CryptoCurrencyMonitor: NSObject {

    // MARK: Properties
    var timer = Timer()
    let defaults = UserDefaults.standard
    let cryptoCurrencyAPI = CryptoCurrencyAPI()

    var cryptoCurrency: String {
        return defaults.string(forKey: UserDefaults.Key.cryptoCurrency)!
    }

    var fiatCurrency: String {
        return defaults.string(forKey: UserDefaults.Key.fiatCurrency)!
    }

    var exchangeRateThreshold: Double {
        return defaults.double(forKey: UserDefaults.Key.exchangeRateThreshold)
    }

    var isExchangeRateWatcherOn: Bool {
        get {
            return defaults.bool(forKey: UserDefaults.Key.isExchangeRateWatcherOn)
        }
        set(newVal) {
            defaults.set(newVal, forKey: UserDefaults.Key.isExchangeRateWatcherOn)
            defaults.synchronize()
        }
    }

    // MARK: Utility methods
    func setRepeatingDataFetcher() {
        timer = Timer.scheduledTimer(timeInterval: Constant.dataFetcherTimerInterval,
                                     target: self,
                                     selector: #selector(getCurrentExchangeRate),
                                     userInfo: nil,
                                     repeats: true)
    }

    @objc func getCurrentExchangeRate() {
        cryptoCurrencyAPI.fetchExchangeRate(from: cryptoCurrency, to: fiatCurrency) { exchangeRate in
            self.updateMenuBarStatusElement(by: exchangeRate)
            self.compareThreshold(with: exchangeRate)
        }
    }

    private func updateMenuBarStatusElement(by exchangeRate: Double) {
        guard let appDelegate = NSApplication.shared.delegate as? AppDelegate else { return }
        DispatchQueue.main.async {
            // For example "LTC\EUR: 44.56
            appDelegate.statusItem.title = "\(self.cryptoCurrency)\\\(self.fiatCurrency): \(exchangeRate)"
        }
    }

    private func compareThreshold(with exchangeRate: Double) {
        if isExchangeRateWatcherOn && isThresholdExceeded(basedOn: exchangeRate) == true {
            sendThresholdExceededNotification()
            isExchangeRateWatcherOn = false
        }
    }

    private func isThresholdExceeded(basedOn exchangeRate: Double) -> Bool {
        return exchangeRate >= exchangeRateThreshold
    }

    private func sendThresholdExceededNotification() {
        let notification = NSUserNotification()
        notification.title = "Threshold exceeded"
        notification.informativeText = "Exchange rate for \(cryptoCurrency)"
                                        + "exceeded \(exchangeRateThreshold) \(fiatCurrency)."
        NSUserNotificationCenter.default.deliver(notification)
    }

}

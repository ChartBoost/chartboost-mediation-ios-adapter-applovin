//
//  AppLovinAdAdapter.swift
//  ChartboostHeliumAdapterAppLovin
//

import Foundation
import HeliumSdk
import AppLovinSDK
import UIKit

/// Requirements for an ad adapter for AppLovin
protocol AppLovinAdAdapter: NSObjectProtocol, PartnerLogger, PartnerErrorFactory {
    /// Initializer
    init(sdk: ALSdk, adapter: PartnerAdapter, request: PartnerAdLoadRequest, partnerAdDelegate: PartnerAdDelegate)

    /// Load the ad
    func load(completion: @escaping (Result<PartnerAd, Error>) -> Void)

    /// Show the ad
    func show(completion: @escaping (Result<PartnerAd, Error>) -> Void)
}

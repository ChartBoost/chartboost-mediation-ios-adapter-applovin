//
//  AppLovinAdAdapterBanner.swift
//  ChartboostHeliumAdapterAppLovin
//

import Foundation
import HeliumSdk
import AppLovinSDK
import UIKit

/// Banner ad adapter for AppLovin
final class AppLovinAdAdapterBanner: NSObject, AppLovinAdAdapter {
    /// The AppLovin SDK instance
    let sdk: ALSdk

    /// The current adapter instance
    let adapter: PartnerAdapter

    /// The current PartnerAdLoadRequest containing data relevant to the curent ad request
    let request: PartnerAdLoadRequest

    /// The partner ad delegate to send ad life-cycle events to.
    weak var partnerAdDelegate: PartnerAdDelegate?

    /// A PartnerAd object with a placeholder (nil) ad object.
    lazy var partnerAd = PartnerAd(ad: nil, details: [:], request: request)

    /// The completion for the ongoing load operation
    var loadCompletion: ((Result<PartnerAd, Error>) -> Void)?

    required init(sdk: ALSdk, adapter: PartnerAdapter, request: PartnerAdLoadRequest, partnerAdDelegate: PartnerAdDelegate) {
        self.sdk = sdk
        self.adapter = adapter
        self.request = request
        self.partnerAdDelegate = partnerAdDelegate
    }

    func load(completion: @escaping (Result<PartnerAd, Error>) -> Void) {
        loadCompletion = completion

        let banner = ALAdView(sdk: sdk, size: .from(size: request.size), zoneIdentifier: request.partnerPlacement)
        banner.adDisplayDelegate = self
        banner.adLoadDelegate = self
        
        partnerAd = PartnerAd(ad: banner, details: [:], request: request)
        banner.loadNextAd()
    }

    func show(completion: @escaping (Result<PartnerAd, Error>) -> Void) {
        // NO-OP
    }
}

extension AppLovinAdAdapterBanner: ALAdLoadDelegate {
    func adService(_ adService: ALAdService, didLoad ad: ALAd) {
        loadCompletion?(.success(partnerAd)) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }

    func adService(_ adService: ALAdService, didFailToLoadAdWithError code: Int32) {
        loadCompletion?(.failure(error(.loadFailure(request), description: "AppLovin error \(code)"))) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }
}

extension AppLovinAdAdapterBanner: ALAdDisplayDelegate {
    func ad(_ ad: ALAd, wasDisplayedIn view: UIView) {
        log("wasDisplayedIn")
    }

    func ad(_ ad: ALAd, wasHiddenIn view: UIView) {
        log("wasHiddenIn")
    }

    func ad(_ ad: ALAd, wasClickedIn view: UIView) {
        log(.didClick(partnerAd, error: nil))
        partnerAdDelegate?.didClick(partnerAd) ?? log(.delegateUnavailable)
    }
}

extension ALAdSize {
    static func from(size: CGSize?) -> ALAdSize {
        let height = size?.height ?? 50
        switch height {
        case 50...89:
            return .banner
        case 90...249:
            return .leader
        case 250...:
            return .mrec
        default:
            return .banner
        }
    }
}

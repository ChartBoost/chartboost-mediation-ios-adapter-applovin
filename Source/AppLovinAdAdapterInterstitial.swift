//
//  AppLovinAdAdapterInterstitial.swift
//  ChartboostHeliumAdapterAppLovin
//

import Foundation
import HeliumSdk
import AppLovinSDK
import UIKit

/// Interstitial ad adapter for AppLovin
class AppLovinAdAdapterInterstitial: NSObject, PartnerAdAdapter {
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

    /// The completion for the ongoing show operation
    var showCompletion: ((Result<PartnerAd, Error>) -> Void)?

    required init(sdk: ALSdk, adapter: PartnerAdapter, request: PartnerAdLoadRequest, partnerAdDelegate: PartnerAdDelegate) {
        self.sdk = sdk
        self.adapter = adapter
        self.request = request
        self.partnerAdDelegate = partnerAdDelegate
    }
    
    func load(with viewController: UIViewController?, completion: @escaping (Result<PartnerAd, Error>) -> Void) {
        loadCompletion = completion
        sdk.adService.loadNextAd(forZoneIdentifier: request.partnerPlacement, andNotify: self)
    }
    
    func show(with viewController: UIViewController, completion: @escaping (Result<PartnerAd, Error>) -> Void) {
        guard let ad = partnerAd.ad as? ALAd else {
            return completion(.failure(error(.showFailure(partnerAd), description: "Ad instance is nil/not an ALAd.")))
        }
        showCompletion = completion
        
        let interstitial = ALInterstitialAd(sdk: sdk)
        interstitial.adDisplayDelegate = self
        interstitial.adVideoPlaybackDelegate = self
        interstitial.show(ad)
    }
}

extension AppLovinAdAdapterInterstitial: ALAdLoadDelegate {
    func adService(_ adService: ALAdService, didLoad ad: ALAd) {
        partnerAd = PartnerAd(ad: ad, details: [:], request: request)
        loadCompletion?(.success(partnerAd)) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }

    func adService(_ adService: ALAdService, didFailToLoadAdWithError code: Int32) {
        loadCompletion?(.failure(error(.loadFailure(request), description: "AppLovin error \(code)"))) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }
}

extension AppLovinAdAdapterInterstitial: ALAdDisplayDelegate {
    func ad(_ ad: ALAd, wasDisplayedIn view: UIView) {
        showCompletion?(.success(partnerAd)) ?? log(.showResultIgnored)
        showCompletion = nil
    }

    func ad(_ ad: ALAd, wasHiddenIn view: UIView) {
        log(.didDismiss(partnerAd, error: nil))
        partnerAdDelegate?.didDismiss(partnerAd, error: nil) ?? log(.delegateUnavailable)
    }

    func ad(_ ad: ALAd, wasClickedIn view: UIView) {
        log(.didClick(partnerAd, error: nil))
        partnerAdDelegate?.didClick(partnerAd) ?? log(.delegateUnavailable)
    }
}

extension AppLovinAdAdapterInterstitial: ALAdVideoPlaybackDelegate {
    func videoPlaybackBegan(in ad: ALAd) {
        log("videoPlaybackBegan")
    }

    func videoPlaybackEnded(in ad: ALAd, atPlaybackPercent percentPlayed: NSNumber, fullyWatched wasFullyWatched: Bool) {
        if percentPlayed.intValue == 0 && !wasFullyWatched {
            let error = error(.showFailure(partnerAd), description: "Failed to show the AppLovin ad. Video playback ended at 0% played.")
            showCompletion?(.failure(error))
            showCompletion = nil
        }
    }
}

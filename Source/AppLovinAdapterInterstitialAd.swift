//
//  AppLovinAdapterInterstitialAd.swift
//  ChartboostHeliumAdapterAppLovin
//

import Foundation
import HeliumSdk
import AppLovinSDK
import UIKit

/// The Helium AppLovin adapter interstitial ad.
class AppLovinAdapterInterstitialAd: AppLovinAdapterAd, PartnerAd {
    
    /// The partner ad view to display inline. E.g. a banner view.
    /// Should be nil for full-screen ads.
    var inlineView: UIView? { nil }
    
    /// The AppLovin loaded ad instance.
    var ad: ALAd?
    
    /// The AppLovin display ad instance.
    private var interstitial: ALInterstitialAd?
    
    /// Loads an ad.
    /// - parameter viewController: The view controller on which the ad will be presented on. Needed on load for some banners.
    /// - parameter completion: Closure to be performed once the ad has been loaded.
    func load(with viewController: UIViewController?, completion: @escaping (Result<PartnerEventDetails, Error>) -> Void) {
        log(.loadStarted)
        loadCompletion = completion
        sdk.adService.loadNextAd(forZoneIdentifier: request.partnerPlacement, andNotify: self)
    }
    
    /// Shows a loaded ad.
    /// It will never get called for banner ads. You may leave the implementation blank for that ad format.
    /// - parameter viewController: The view controller on which the ad will be presented on.
    /// - parameter completion: Closure to be performed once the ad has been shown.
    func show(with viewController: UIViewController, completion: @escaping (Result<PartnerEventDetails, Error>) -> Void) {
        log(.showStarted)
        guard let ad = ad else {
            let error = error(.noAdReadyToShow)
            log(.showFailed(error))
            return completion(.failure(error))
        }
        showCompletion = completion
        
        let interstitial = ALInterstitialAd(sdk: sdk)
        interstitial.adDisplayDelegate = self
        interstitial.adVideoPlaybackDelegate = self
        interstitial.show(ad)
        self.interstitial = interstitial
    }
}

extension AppLovinAdapterInterstitialAd: ALAdLoadDelegate {
    
    func adService(_ adService: ALAdService, didLoad ad: ALAd) {
        log(.loadSucceeded)
        self.ad = ad
        loadCompletion?(.success([:])) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }

    func adService(_ adService: ALAdService, didFailToLoadAdWithError code: Int32) {
        let error = error(.loadFailure, description: "\(code)")
        log(.loadFailed(error))
        loadCompletion?(.failure(error)) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }
}

extension AppLovinAdapterInterstitialAd: ALAdDisplayDelegate {
    
    func ad(_ ad: ALAd, wasDisplayedIn view: UIView) {
        log(.showSucceeded)
        showCompletion?(.success([:])) ?? log(.showResultIgnored)
        showCompletion = nil
    }

    func ad(_ ad: ALAd, wasHiddenIn view: UIView) {
        log(.didDismiss(error: nil))
        delegate?.didDismiss(self, details: [:], error: nil) ?? log(.delegateUnavailable)
    }

    func ad(_ ad: ALAd, wasClickedIn view: UIView) {
        log(.didClick(error: nil))
        delegate?.didClick(self, details: [:]) ?? log(.delegateUnavailable)
    }
}

extension AppLovinAdapterInterstitialAd: ALAdVideoPlaybackDelegate {
    
    func videoPlaybackBegan(in ad: ALAd) {
        log("videoPlaybackBegan")
    }

    func videoPlaybackEnded(in ad: ALAd, atPlaybackPercent percentPlayed: NSNumber, fullyWatched wasFullyWatched: Bool) {
        if percentPlayed.intValue == 0 && !wasFullyWatched {
            let error = error(.showFailure, description: "Video playback ended at 0% played.")
            log(.showFailed(error))
            showCompletion?(.failure(error)) ?? log(.showResultIgnored)
            showCompletion = nil
        }
    }
}

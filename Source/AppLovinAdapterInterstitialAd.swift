// Copyright 2022-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import AppLovinSDK
import ChartboostMediationSDK
import Foundation
import UIKit

/// The Chartboost Mediation AppLovin adapter interstitial ad.
class AppLovinAdapterInterstitialAd: AppLovinAdapterAd, PartnerFullscreenAd {
    /// The AppLovin loaded ad instance.
    var ad: ALAd?

    /// The AppLovin display ad instance.
    private var interstitial: ALInterstitialAd?

    /// Loads an ad.
    /// - parameter viewController: The view controller on which the ad will be presented on. Needed on load for some banners.
    /// - parameter completion: Closure to be performed once the ad has been loaded.
    func load(with viewController: UIViewController?, completion: @escaping (Error?) -> Void) {
        log(.loadStarted)
        loadCompletion = completion
        sdk.adService.loadNextAd(forZoneIdentifier: request.partnerPlacement, andNotify: self)
    }

    /// Shows a loaded ad.
    /// Chartboost Mediation SDK will always call this method from the main thread.
    /// - parameter viewController: The view controller on which the ad will be presented on.
    /// - parameter completion: Closure to be performed once the ad has been shown.
    func show(with viewController: UIViewController, completion: @escaping (Error?) -> Void) {
        log(.showStarted)
        guard let ad else {
            let error = error(.showFailureAdNotReady)
            log(.showFailed(error))
            completion(error)
            return
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
        loadCompletion?(nil) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }

    func adService(_ adService: ALAdService, didFailToLoadAdWithError code: Int32) {
        let error = partnerError(Int(code))
        log(.loadFailed(error))
        loadCompletion?(error) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }
}

extension AppLovinAdapterInterstitialAd: ALAdDisplayDelegate {
    func ad(_ ad: ALAd, wasDisplayedIn view: UIView) {
        log(.showSucceeded)
        showCompletion?(nil) ?? log(.showResultIgnored)
        showCompletion = nil
    }

    func ad(_ ad: ALAd, wasHiddenIn view: UIView) {
        log(.didDismiss(error: nil))
        delegate?.didDismiss(self, error: nil) ?? log(.delegateUnavailable)
    }

    func ad(_ ad: ALAd, wasClickedIn view: UIView) {
        log(.didClick(error: nil))
        delegate?.didClick(self) ?? log(.delegateUnavailable)
    }
}

extension AppLovinAdapterInterstitialAd: ALAdVideoPlaybackDelegate {
    func videoPlaybackBegan(in ad: ALAd) {
        log(.delegateCallIgnored)
    }

    func videoPlaybackEnded(in ad: ALAd, atPlaybackPercent percentPlayed: NSNumber, fullyWatched wasFullyWatched: Bool) {
        if percentPlayed.intValue == 0 && !wasFullyWatched {
            let error = error(.showFailureVideoPlayerError, description: "Video playback ended at 0% played.")
            log(.showFailed(error))
            showCompletion?(error) ?? log(.showResultIgnored)
            showCompletion = nil
        }
    }
}

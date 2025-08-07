// Copyright 2022-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import AppLovinSDK
import ChartboostMediationSDK
import Foundation
import UIKit

/// The Chartboost Mediation AppLovin adapter rewarded ad.
final class AppLovinAdapterRewardedAd: AppLovinAdapterInterstitialAd {
    private var isEligibleToReward = false
    private var hasRewarded = false

    /// The AppLovin display ad instance.
    private var rewarded: ALIncentivizedInterstitialAd?

    /// Shows a loaded ad.
    /// Chartboost Mediation SDK will always call this method from the main thread.
    /// - parameter viewController: The view controller on which the ad will be presented on.
    /// - parameter completion: Closure to be performed once the ad has been shown.
    override func show(with viewController: UIViewController, completion: @escaping (Error?) -> Void) {
        log(.showStarted)
        guard let ad else {
            let error = error(.showFailureAdNotReady)
            log(.showFailed(error))
            completion(error)
            return
        }
        showCompletion = completion

        let rewarded = ALIncentivizedInterstitialAd(sdk: sdk)
        rewarded.adDisplayDelegate = self
        rewarded.adVideoPlaybackDelegate = self
        rewarded.show(ad, andNotify: self)
        self.rewarded = rewarded
    }
}

extension AppLovinAdapterRewardedAd {
    override func videoPlaybackEnded(in ad: ALAd, atPlaybackPercent percentPlayed: NSNumber, fullyWatched wasFullyWatched: Bool) {
        super.videoPlaybackEnded(in: ad, atPlaybackPercent: percentPlayed, fullyWatched: wasFullyWatched)

        if isEligibleToReward, wasFullyWatched, !hasRewarded {
            log(.didReward)
            delegate?.didReward(self) ?? log(.delegateUnavailable)
            hasRewarded = true
        } else {
            log(.delegateCallIgnored)
        }
    }
}

extension AppLovinAdapterRewardedAd: ALAdRewardDelegate {
    func rewardValidationRequest(for ad: ALAd, didSucceedWithResponse response: [AnyHashable: Any]) {
        isEligibleToReward = true
        log(.delegateCallIgnored)
    }

    func rewardValidationRequest(for ad: ALAd, didExceedQuotaWithResponse response: [AnyHashable: Any]) {
        log(.delegateCallIgnored)
    }

    func rewardValidationRequest(for ad: ALAd, wasRejectedWithResponse response: [AnyHashable: Any]) {
        log(.delegateCallIgnored)
    }

    func rewardValidationRequest(for ad: ALAd, didFailWithError responseCode: Int) {
        log(.delegateCallIgnored)
    }
}

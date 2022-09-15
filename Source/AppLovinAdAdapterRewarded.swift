//
//  AppLovinAdAdapterRewarded.swift
//  ChartboostHeliumAdapterAppLovin
//

import Foundation
import HeliumSdk
import AppLovinSDK
import UIKit

/// Incentivised rewuarded ad adapter for AppLovin
final class AppLovinAdAdapterRewarded: AppLovinAdAdapterInterstitial {
    private var isEligibleToReward = false
    private var hasRewarded = false

    override func show(completion: @escaping (Result<PartnerAd, Error>) -> Void) {
        guard let ad = partnerAd.ad as? ALAd else {
            return completion(.failure(error(.showFailure(partnerAd), description: "Ad instance is nil/not a ALAd.")))
        }
        showCompletion = completion
        let rewarded = ALIncentivizedInterstitialAd(sdk: sdk)
        rewarded.adDisplayDelegate = self
        rewarded.adVideoPlaybackDelegate = self
        rewarded.show(ad, andNotify: self)
    }
}

extension AppLovinAdAdapterRewarded {
    override func videoPlaybackEnded(in ad: ALAd, atPlaybackPercent percentPlayed: NSNumber, fullyWatched wasFullyWatched: Bool) {
        if percentPlayed.intValue == 0 && !wasFullyWatched {
            let error = error(.showFailure(partnerAd), description: "Failed to show the AppLovin ad. Video playback ended at 0% played.")
            showCompletion?(.failure(error))
            showCompletion = nil
        }
        else if isEligibleToReward, wasFullyWatched, !hasRewarded {
            hasRewarded = true
            let reward = Reward(amount: 1, label: "")
            log(.didReward(partnerAd, reward: reward))
            partnerAdDelegate?.didReward(partnerAd, reward: reward) ?? log(.delegateUnavailable)
        }
    }
}

extension AppLovinAdAdapterRewarded: ALAdRewardDelegate {
    func rewardValidationRequest(for ad: ALAd, didSucceedWithResponse response: [AnyHashable : Any]) {
        isEligibleToReward = true
    }

    func rewardValidationRequest(for ad: ALAd, didExceedQuotaWithResponse response: [AnyHashable : Any]) {
        // NO-OP
    }

    func rewardValidationRequest(for ad: ALAd, wasRejectedWithResponse response: [AnyHashable : Any]) {
        // NO-OP
    }

    func rewardValidationRequest(for ad: ALAd, didFailWithError responseCode: Int) {
        // NO-OP
    }
}

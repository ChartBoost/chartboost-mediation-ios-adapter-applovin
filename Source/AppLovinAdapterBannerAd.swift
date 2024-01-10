// Copyright 2022-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import AppLovinSDK
import ChartboostMediationSDK
import Foundation
import UIKit

/// The Chartboost Mediation AppLovin adapter banner ad.
final class AppLovinAdapterBannerAd: AppLovinAdapterAd, PartnerAd {
    
    /// The partner ad view to display inline. E.g. a banner view.
    /// Should be nil for full-screen ads.
    var inlineView: UIView?
    
    /// Loads an ad.
    /// - parameter viewController: The view controller on which the ad will be presented on. Needed on load for some banners.
    /// - parameter completion: Closure to be performed once the ad has been loaded.
    func load(with viewController: UIViewController?, completion: @escaping (Result<PartnerEventDetails, Error>) -> Void) {
        log(.loadStarted)

        // Fail if we cannot fit a fixed size banner in the requested size.
        guard let size = fixedBannerSize(for: request.size ?? IABStandardAdSize) else {
            let error = error(.loadFailureInvalidBannerSize)
            log(.loadFailed(error))
            return completion(.failure(error))
        }
        
        loadCompletion = completion

        let banner = ALAdView(sdk: sdk, size: size.partnerSize, zoneIdentifier: request.partnerPlacement)
        banner.adDisplayDelegate = self
        banner.adLoadDelegate = self
        inlineView = banner
        
        banner.loadNextAd()
    }
    
    /// Shows a loaded ad.
    /// It will never get called for banner ads. You may leave the implementation blank for that ad format.
    /// - parameter viewController: The view controller on which the ad will be presented on.
    /// - parameter completion: Closure to be performed once the ad has been shown.
    func show(with viewController: UIViewController, completion: @escaping (Result<PartnerEventDetails, Error>) -> Void) {
        // NO-OP
    }
}

extension AppLovinAdapterBannerAd: ALAdLoadDelegate {
    
    func adService(_ adService: ALAdService, didLoad ad: ALAd) {
        log(.loadSucceeded)

        var partnerDetails: [String: String] = [:]
        if let loadedSize = fixedBannerSize(for: request.size ?? IABStandardAdSize) {
            partnerDetails["bannerWidth"] = "\(loadedSize.size.width)"
            partnerDetails["bannerHeight"] = "\(loadedSize.size.height)"
            partnerDetails["bannerType"] = "0" // Fixed banner
        }
        loadCompletion?(.success(partnerDetails)) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }

    func adService(_ adService: ALAdService, didFailToLoadAdWithError code: Int32) {
        let error = partnerError(Int(code))
        log(.loadFailed(error))
        loadCompletion?(.failure(error)) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }
}

extension AppLovinAdapterBannerAd: ALAdDisplayDelegate {
    
    func ad(_ ad: ALAd, wasDisplayedIn view: UIView) {
        log(.delegateCallIgnored)
    }

    func ad(_ ad: ALAd, wasHiddenIn view: UIView) {
        log(.delegateCallIgnored)
    }

    func ad(_ ad: ALAd, wasClickedIn view: UIView) {
        log(.didClick(error: nil))
        delegate?.didClick(self, details: [:]) ?? log(.delegateUnavailable)
    }
}

// MARK: - Helpers
extension AppLovinAdapterBannerAd {
    private func fixedBannerSize(for requestedSize: CGSize) -> (size: CGSize, partnerSize: ALAdSize)? {
        let sizes: [(size: CGSize, partnerSize: ALAdSize)] = [
            (size: IABLeaderboardAdSize, partnerSize: .leader),
            (size: IABMediumAdSize, partnerSize: .mrec),
            (size: IABStandardAdSize, partnerSize: .banner)
        ]
        // Find the largest size that can fit in the requested size.
        for (size, partnerSize) in sizes {
            // If height is 0, the pub has requested an ad of any height, so only the width matters.
            if requestedSize.width >= size.width &&
                (size.height == 0 || requestedSize.height >= size.height) {
                return (size, partnerSize)
            }
        }
        // The requested size cannot fit any fixed size banners.
        return nil
    }
}

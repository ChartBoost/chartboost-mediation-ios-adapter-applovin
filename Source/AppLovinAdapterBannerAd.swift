// Copyright 2022-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import AppLovinSDK
import ChartboostMediationSDK
import Foundation
import UIKit

/// The Chartboost Mediation AppLovin adapter banner ad.
final class AppLovinAdapterBannerAd: AppLovinAdapterAd, PartnerBannerAd {
    /// The partner banner ad view to display.
    var view: UIView?

    /// The loaded partner ad banner size.
    var size: PartnerBannerSize?

    /// Loads an ad.
    /// - parameter viewController: The view controller on which the ad will be presented on. Needed on load for some banners.
    /// - parameter completion: Closure to be performed once the ad has been loaded.
    func load(with viewController: UIViewController?, completion: @escaping (Error?) -> Void) {
        log(.loadStarted)

        // Fail if we cannot fit a fixed size banner in the requested size.
        guard
            let requestedSize = request.bannerSize,
            let loadedSize = BannerSize.largestStandardFixedSizeThatFits(in: requestedSize),
            let appLovinSize = loadedSize.appLovinAdSize
        else {
            let error = error(.loadFailureInvalidBannerSize)
            log(.loadFailed(error))
            completion(error)
            return
        }

        size = PartnerBannerSize(size: loadedSize.size, type: .fixed)
        loadCompletion = completion

        let banner = ALAdView(sdk: sdk, size: appLovinSize, zoneIdentifier: request.partnerPlacement)
        banner.adDisplayDelegate = self
        banner.adLoadDelegate = self
        view = banner

        banner.loadNextAd()
    }
}

extension AppLovinAdapterBannerAd: ALAdLoadDelegate {
    func adService(_ adService: ALAdService, didLoad ad: ALAd) {
        log(.loadSucceeded)
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

extension AppLovinAdapterBannerAd: ALAdDisplayDelegate {
    func ad(_ ad: ALAd, wasDisplayedIn view: UIView) {
        log(.delegateCallIgnored)
    }

    func ad(_ ad: ALAd, wasHiddenIn view: UIView) {
        log(.delegateCallIgnored)
    }

    func ad(_ ad: ALAd, wasClickedIn view: UIView) {
        log(.didClick(error: nil))
        delegate?.didClick(self) ?? log(.delegateUnavailable)
    }
}

extension BannerSize {
    fileprivate var appLovinAdSize: ALAdSize? {
        switch self {
        case .standard:
            .banner
        case .medium:
            .mrec
        case .leaderboard:
            .leader
        default:
            nil
        }
    }
}

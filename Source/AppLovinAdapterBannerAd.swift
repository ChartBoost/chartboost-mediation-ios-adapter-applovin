// Copyright 2022-2024 Chartboost, Inc.
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
    func load(with viewController: UIViewController?, completion: @escaping (Result<PartnerDetails, Error>) -> Void) {
        log(.loadStarted)

        // Fail if we cannot fit a fixed size banner in the requested size.
        guard let loadedSize = fixedBannerSize(for: request.bannerSize) else {
            let error = error(.loadFailureInvalidBannerSize)
            log(.loadFailed(error))
            return completion(.failure(error))
        }
        
        size = PartnerBannerSize(size: loadedSize.size, type: .fixed)
        loadCompletion = completion

        let banner = ALAdView(sdk: sdk, size: loadedSize.partnerSize, zoneIdentifier: request.partnerPlacement)
        banner.adDisplayDelegate = self
        banner.adLoadDelegate = self
        view = banner

        banner.loadNextAd()
    }
}

extension AppLovinAdapterBannerAd: ALAdLoadDelegate {
    
    func adService(_ adService: ALAdService, didLoad ad: ALAd) {
        log(.loadSucceeded)
        loadCompletion?(.success([:])) ?? log(.loadResultIgnored)
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
    private func fixedBannerSize(for requestedSize: BannerSize?) -> (size: CGSize, partnerSize: ALAdSize)? {
        // Return a default value if no size is specified
        guard let requestedSize else {
            return (BannerSize.standard.size, .banner)
        }

        // If we can find a size that fits, return that.
        if let size = BannerSize.largestStandardFixedSizeThatFits(in: requestedSize) {
            switch size {
            case .standard:
                return (BannerSize.standard.size, .banner)
            case .medium:
                return (BannerSize.medium.size, .mrec)
            case .leaderboard:
                return (BannerSize.leaderboard.size, .leader)
            default:
                // largestStandardFixedSizeThatFits currently only returns .standard, .medium, or .leaderboard,
                // but if that changes then just default to .standard until this code gets updated.
                return (BannerSize.standard.size, .banner)
            }
        } else {
            // largestStandardFixedSizeThatFits has returned nil to indicate it couldn't find a fit.
            return nil
        }
    }
}

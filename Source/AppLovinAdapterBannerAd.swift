//
//  AppLovinAdapterBannerAd.swift
//  ChartboostHeliumAdapterAppLovin
//

import Foundation
import HeliumSdk
import AppLovinSDK
import UIKit

/// The Helium AppLovin adapter banner ad.
final class AppLovinAdapterBannerAd: AppLovinAdapterAd, PartnerAd {
    
    /// The partner ad view to display inline. E.g. a banner view.
    /// Should be nil for full-screen ads.
    var inlineView: UIView?
    
    /// Loads an ad.
    /// - parameter viewController: The view controller on which the ad will be presented on. Needed on load for some banners.
    /// - parameter completion: Closure to be performed once the ad has been loaded.
    func load(with viewController: UIViewController?, completion: @escaping (Result<PartnerEventDetails, Error>) -> Void) {
        log(.loadStarted)
        
        loadCompletion = completion
        
        let banner = ALAdView(sdk: sdk, size: .from(size: request.size), zoneIdentifier: request.partnerPlacement)
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
        loadCompletion?(.success([:])) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }

    func adService(_ adService: ALAdService, didFailToLoadAdWithError code: Int32) {
        let error = error(.loadFailureUnknown, description: "\(code)")
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

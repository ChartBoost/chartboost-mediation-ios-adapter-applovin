// Copyright 2022-2023 Chartboost, Inc.
// 
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

//
//  AppLovinAdapter.swift
//  ChartboostMediationAdapterAppLovin
//

import AppLovinSDK
import ChartboostMediationSDK
import Foundation
import UIKit

/// The Chartboost Mediation AppLovin adapter.
final class AppLovinAdapter: PartnerAdapter {
    
    /// The version of the partner SDK.
    let partnerSDKVersion = ALSdk.version()
    
    /// The version of the adapter.
    /// It should have either 5 or 6 digits separated by periods, where the first digit is Chartboost Mediation SDK's major version, the last digit is the adapter's build version, and intermediate digits are the partner SDK's version.
    /// Format: `<Chartboost Mediation major version>.<Partner major version>.<Partner minor version>.<Partner patch version>.<Partner build version>.<Adapter build version>` where `.<Partner build version>` is optional.
    let adapterVersion = "4.11.5.4.0"
    
    /// The partner's unique identifier.
    let partnerIdentifier = "applovin"
    
    /// The human-friendly partner name.
    let partnerDisplayName = "AppLovin"
    
    /// Instance of the AppLovin SDK
    static var sdk: ALSdk? {
        didSet {
            AppLovinAdapterConfiguration.sync()
        }
    }
    
    /// The designated initializer for the adapter.
    /// Chartboost Mediation SDK will use this constructor to create instances of conforming types.
    /// - parameter storage: An object that exposes storage managed by the Chartboost Mediation SDK to the adapter.
    /// It includes a list of created `PartnerAd` instances. You may ignore this parameter if you don't need it.
    init(storage: PartnerAdapterStorage) {}
    
    /// Does any setup needed before beginning to load ads.
    /// - parameter configuration: Configuration data for the adapter to set up.
    /// - parameter completion: Closure to be performed by the adapter when it's done setting up. It should include an error indicating the cause for failure or `nil` if the operation finished successfully.
    func setUp(with configuration: PartnerConfiguration, completion: @escaping (Error?) -> Void) {
        log(.setUpStarted)
        guard let sdkKey = configuration.sdkKey, !sdkKey.isEmpty else {
            let error = error(.initializationFailureInvalidCredentials, description: "Missing \(String.sdkKey)")
            log(.setUpFailed(error))
            return completion(error)
        }
        guard let sdk = ALSdk.shared(withKey: sdkKey) else {
            let error = error(.initializationFailureInvalidCredentials, description: "Invalid \(String.sdkKey)")
            log(.setUpFailed(error))
            return completion(error)
        }
        Self.sdk = sdk

        sdk.mediationProvider = "Helium"
        sdk.initializeSdk { _ in
            if sdk.isInitialized {
                self.log(.setUpSucceded)
                completion(nil)
            }
            else {
                let error = self.error(.initializationFailureUnknown)
                self.log(.setUpFailed(error))
                completion(error)
            }
        }
    }
    
    /// Fetches bidding tokens needed for the partner to participate in an auction.
    /// - parameter request: Information about the ad load request.
    /// - parameter completion: Closure to be performed with the fetched info.
    func fetchBidderInformation(request: PreBidRequest, completion: @escaping ([String : String]?) -> Void) {
        completion(nil)
    }
    
    /// Indicates if GDPR applies or not and the user's GDPR consent status.
    /// - parameter applies: `true` if GDPR applies, `false` if not, `nil` if the publisher has not provided this information.
    /// - parameter status: One of the `GDPRConsentStatus` values depending on the user's preference.
    func setGDPR(applies: Bool?, status: GDPRConsentStatus) {
        if applies == true {
            // https://dash.applovin.com/docs/integration#iosPrivacySettings
            let userConsented = status == .granted
            ALPrivacySettings.setHasUserConsent(userConsented)
            log(.privacyUpdated(setting: "hasUserConsent", value: userConsented))
        }
    }

    /// Indicates if the user is subject to COPPA or not.
    /// - parameter isChildDirected: `true` if the user is subject to COPPA, `false` otherwise.
    func setCOPPA(isChildDirected: Bool) {
        ALPrivacySettings.setIsAgeRestrictedUser(isChildDirected)
        log(.privacyUpdated(setting: "isAgeRestrictedUser", value: isChildDirected))
    }
    
    /// Indicates the CCPA status both as a boolean and as an IAB US privacy string.
    /// - parameter hasGivenConsent: A boolean indicating if the user has given consent.
    /// - parameter privacyString: An IAB-compliant string indicating the CCPA status.
    func setCCPA(hasGivenConsent: Bool, privacyString: String) {
        // Note the NOT operator, for converting from "has not consented" to "do not sell" and vice versa
        let doNotSell = !hasGivenConsent
        ALPrivacySettings.setDoNotSell(doNotSell)
        log(.privacyUpdated(setting: "doNotSell", value: doNotSell))
    }
    
    /// Creates a new ad object in charge of communicating with a single partner SDK ad instance.
    /// Chartboost Mediation SDK calls this method to create a new ad for each new load request. Ad instances are never reused.
    /// Chartboost Mediation SDK takes care of storing and disposing of ad instances so you don't need to.
    /// `invalidate()` is called on ads before disposing of them in case partners need to perform any custom logic before the object gets destroyed.
    /// If, for some reason, a new ad cannot be provided, an error should be thrown.
    /// - parameter request: Information about the ad load request.
    /// - parameter delegate: The delegate that will receive ad life-cycle notifications.
    func makeAd(request: PartnerAdLoadRequest, delegate: PartnerAdDelegate) throws -> PartnerAd {
        guard let sdk = Self.sdk else {
            throw error(.loadFailurePartnerInstanceNotFound)
        }
        switch request.format {
        case .banner:
            return AppLovinAdapterBannerAd(sdk: sdk, adapter: self, request: request, delegate: delegate)
        case .interstitial:
            return AppLovinAdapterInterstitialAd(sdk: sdk, adapter: self, request: request, delegate: delegate)
        case .rewarded:
            return AppLovinAdapterRewardedAd(sdk: sdk, adapter: self, request: request, delegate: delegate)
        @unknown default:
            throw error(.loadFailureUnsupportedAdFormat)
        }
    }
}

/// Convenience extension to access AppLovin credentials from the configuration.
private extension PartnerConfiguration {
    var sdkKey: String? { credentials[.sdkKey] as? String }
}

private extension String {
    /// AppLovin sdk credentials key
    static let sdkKey = "sdk_key"
}

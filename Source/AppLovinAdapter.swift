// Copyright 2022-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import AppLovinSDK
import ChartboostMediationSDK
import Foundation
import UIKit
import AdSupport

/// The Chartboost Mediation AppLovin adapter.
final class AppLovinAdapter: PartnerAdapter {
    
    /// The version of the partner SDK.
    let partnerSDKVersion = ALSdk.version()
    
    /// The version of the adapter.
    /// It should have either 5 or 6 digits separated by periods, where the first digit is Chartboost Mediation SDK's major version, the last digit is the adapter's build version, and intermediate digits are the partner SDK's version.
    /// Format: `<Chartboost Mediation major version>.<Partner major version>.<Partner minor version>.<Partner patch version>.<Partner build version>.<Adapter build version>` where `.<Partner build version>` is optional.
    let adapterVersion = "4.12.4.0.0"
    
    /// The partner's unique identifier.
    let partnerID = "applovin"
    
    /// The human-friendly partner name.
    let partnerDisplayName = "AppLovin"
    
    /// Instance of the AppLovin SDK
    let sdk: ALSdk = ALSdk.shared()

    /// The designated initializer for the adapter.
    /// Chartboost Mediation SDK will use this constructor to create instances of conforming types.
    /// - parameter storage: An object that exposes storage managed by the Chartboost Mediation SDK to the adapter.
    /// It includes a list of created `PartnerAd` instances. You may ignore this parameter if you don't need it.
    init(storage: PartnerAdapterStorage) {}
    
    /// Does any setup needed before beginning to load ads.
    /// - parameter configuration: Configuration data for the adapter to set up.
    /// - parameter completion: Closure to be performed by the adapter when it's done setting up. It should include an error indicating the cause for failure or `nil` if the operation finished successfully.
    func setUp(with configuration: PartnerConfiguration, completion: @escaping (Result<PartnerDetails, Error>) -> Void) {
        log(.setUpStarted)
        guard let sdkKey = configuration.sdkKey, !sdkKey.isEmpty else {
            let error = error(.initializationFailureInvalidCredentials, description: "Missing \(String.sdkKey)")
            log(.setUpFailed(error))
            return completion(.failure(error))
        }
        let initConfig = ALSdkInitializationConfiguration(sdkKey: sdkKey) { builder in
            builder.mediationProvider = "Chartboost"
            if AppLovinAdapterConfiguration.testMode {
                let idfa = ASIdentifierManager.shared().advertisingIdentifier
                if idfa.uuidString != "00000000-0000-0000-0000-000000000000" {
                    builder.testDeviceAdvertisingIdentifiers = [idfa.uuidString]
                }
            }
            else {
                builder.testDeviceAdvertisingIdentifiers = []
            }
        }

        sdk.initialize(with: initConfig) { sdkConfig in
            if self.sdk.isInitialized {
                self.log(.setUpSucceded)
                completion(.success([:]))
            }
            else {
                let error = self.error(.initializationFailureUnknown)
                self.log(.setUpFailed(error))
                completion(.failure(error))
            }
        }
    
        AppLovinAdapterConfiguration.sync()
    }
    
    /// Fetches bidding tokens needed for the partner to participate in an auction.
    /// - parameter request: Information about the ad load request.
    /// - parameter completion: Closure to be performed with the fetched info.
    func fetchBidderInformation(request: PartnerAdPreBidRequest, completion: @escaping (Result<[String : String], Error>) -> Void) {
        log(.fetchBidderInfoNotSupported)
        completion(.success([:]))
    }
    
    /// Indicates if GDPR applies or not and the user's GDPR consent status.
    /// - parameter applies: `true` if GDPR applies, `false` if not, `nil` if the publisher has not provided this information.
    /// - parameter status: One of the `GDPRConsentStatus` values depending on the user's preference.
    func setGDPR(applies: Bool?, status: GDPRConsentStatus) {
        // See https://dash.applovin.com/documentation/mediation/ios/getting-started/privacy#consent-and-age-related-flags-in-gdpr-and-other-regions
        if applies == true {
            let userConsented = status == .granted
            ALPrivacySettings.setHasUserConsent(userConsented)
            log(.privacyUpdated(setting: "hasUserConsent", value: userConsented))
        }
    }

    /// Indicates if the user is subject to COPPA or not.
    /// - parameter isChildDirected: `true` if the user is subject to COPPA, `false` otherwise.
    func setCOPPA(isChildDirected: Bool) {
        // See https://dash.applovin.com/documentation/mediation/ios/getting-started/privacy#prohibition-on-ads-to,-and-personal-information-from,-children-and-apps-exclusively-designed-for,-or-exclusively-directed-to,-children
        ALPrivacySettings.setIsAgeRestrictedUser(isChildDirected)
        log(.privacyUpdated(setting: "isAgeRestrictedUser", value: isChildDirected))
    }
    
    /// Indicates the CCPA status both as a boolean and as an IAB US privacy string.
    /// - parameter hasGivenConsent: A boolean indicating if the user has given consent.
    /// - parameter privacyString: An IAB-compliant string indicating the CCPA status.
    func setCCPA(hasGivenConsent: Bool, privacyString: String) {
        // See https://dash.applovin.com/documentation/mediation/ios/getting-started/privacy#multi-state-consumer-privacy-laws
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
        // This partner supports multiple loads for the same partner placement.
        switch request.format {
        case PartnerAdFormats.banner:
            return AppLovinAdapterBannerAd(sdk: sdk, adapter: self, request: request, delegate: delegate)
        case PartnerAdFormats.interstitial:
            return AppLovinAdapterInterstitialAd(sdk: sdk, adapter: self, request: request, delegate: delegate)
        case PartnerAdFormats.rewarded:
            return AppLovinAdapterRewardedAd(sdk: sdk, adapter: self, request: request, delegate: delegate)
        default:
            throw error(.loadFailureUnsupportedAdFormat)
        }
    }
    
    /// Maps a partner load error to a Chartboost Mediation error code.
    /// Chartboost Mediation SDK calls this method when a load completion is called with a partner error.
    ///
    /// A default implementation is provided that returns `nil`.
    /// Only implement if the partner SDK provides its own list of error codes that can be mapped to Chartboost Mediation's.
    /// If some case cannot be mapped return `nil` to let Chartboost Mediation choose a default error code.
    func mapLoadError(_ error: Error) -> ChartboostMediationError.Code? {
        guard let errorCode = Int32(exactly: (error as NSError).code) else {
            return nil
        }

        switch errorCode {
        case kALErrorCodeSdkDisabled:
            return .loadFailureAborted
        case kALErrorCodeNoFill:
            return .loadFailureNoFill
        case kALErrorCodeAdRequestNetworkTimeout:
            return .loadFailureTimeout
        case kALErrorCodeNotConnectedToInternet:
            return .loadFailureNoConnectivity
        case kALErrorCodeAdRequestUnspecifiedError:
            return .loadFailureUnknown
        case kALErrorCodeUnableToRenderAd:
            return .loadFailureInvalidAdMarkup
        case kALErrorCodeInvalidZone:
            return .loadFailureUnknown
        case kALErrorCodeInvalidAdToken:
            return .loadFailureInvalidAdRequest
        case kALErrorCodeUnableToPrecacheResources:
            return .loadFailureOutOfStorage
        case kALErrorCodeUnableToPrecacheImageResources:
            return .loadFailureOutOfStorage
        case kALErrorCodeUnableToPrecacheVideoResources:
            return .loadFailureOutOfStorage
        case kALErrorCodeInvalidResponse:
            return .loadFailureInvalidBidResponse
        case kALErrorCodeIncentiviziedAdNotPreloaded:
            return .loadFailureUnknown
        case kALErrorCodeIncentivizedUnknownServerError:
            return .loadFailureServerError
        case kALErrorCodeIncentivizedValidationNetworkTimeout:
            return .loadFailureTimeout
        default:
            return nil
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

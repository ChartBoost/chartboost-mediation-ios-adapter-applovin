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
    /// The adapter configuration type that contains adapter and partner info.
    /// It may also be used to expose custom partner SDK options to the publisher.
    var configuration: PartnerAdapterConfiguration.Type { AppLovinAdapterConfiguration.self }

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

        // Apply initial consents
        setConsents(configuration.consents, modifiedKeys: Set(configuration.consents.keys))
        setIsUserUnderage(configuration.isUserUnderage)

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
    
    /// Indicates that the user consent has changed.
    /// - parameter consents: The new consents value, including both modified and unmodified consents.
    /// - parameter modifiedKeys: A set containing all the keys that changed.
    func setConsents(_ consents: [ConsentKey: ConsentValue], modifiedKeys: Set<ConsentKey>) {
        // See https://dash.applovin.com/documentation/mediation/ios/getting-started/privacy#consent-and-age-related-flags-in-gdpr-and-other-regions
        if modifiedKeys.contains(configuration.partnerID) || modifiedKeys.contains(ConsentKeys.gdprConsentGiven) {
            // Use a partner-specific consent if available, falling back to the general GDPR consent if not
            let consent = (consents[configuration.partnerID] ?? consents[ConsentKeys.gdprConsentGiven]) == ConsentValues.granted
            ALPrivacySettings.setHasUserConsent(consent)
            log(.privacyUpdated(setting: "hasUserConsent", value: consent))
        }

        // See https://dash.applovin.com/documentation/mediation/ios/getting-started/privacy#multi-state-consumer-privacy-laws
        if modifiedKeys.contains(ConsentKeys.ccpaOptIn) {
            let doNotSell = consents[ConsentKeys.ccpaOptIn] != ConsentValues.granted
            ALPrivacySettings.setDoNotSell(doNotSell)
            log(.privacyUpdated(setting: "doNotSell", value: doNotSell))
        }
    }

    /// Indicates that the user is underage signal has changed.
    /// - parameter isUserUnderage: `true` if the user is underage as determined by the publisher, `false` otherwise.
    func setIsUserUnderage(_ isUserUnderage: Bool) {
        // See https://dash.applovin.com/documentation/mediation/ios/getting-started/privacy#prohibition-on-ads-to,-and-personal-information-from,-children-and-apps-exclusively-designed-for,-or-exclusively-directed-to,-children
        ALPrivacySettings.setIsAgeRestrictedUser(isUserUnderage)
        log(.privacyUpdated(setting: "isAgeRestrictedUser", value: isUserUnderage))
    }

    /// Creates a new banner ad object in charge of communicating with a single partner SDK ad instance.
    /// Chartboost Mediation SDK calls this method to create a new ad for each new load request. Ad instances are never reused.
    /// Chartboost Mediation SDK takes care of storing and disposing of ad instances so you don't need to.
    /// ``PartnerAd/invalidate()`` is called on ads before disposing of them in case partners need to perform any custom logic before the
    /// object gets destroyed.
    /// If, for some reason, a new ad cannot be provided, an error should be thrown.
    /// Chartboost Mediation SDK will always call this method from the main thread.
    /// - parameter request: Information about the ad load request.
    /// - parameter delegate: The delegate that will receive ad life-cycle notifications.
    func makeBannerAd(request: PartnerAdLoadRequest, delegate: PartnerAdDelegate) throws -> PartnerBannerAd {
        // This partner supports multiple loads for the same partner placement.
        AppLovinAdapterBannerAd(sdk: sdk, adapter: self, request: request, delegate: delegate)
    }

    /// Creates a new ad object in charge of communicating with a single partner SDK ad instance.
    /// Chartboost Mediation SDK calls this method to create a new ad for each new load request. Ad instances are never reused.
    /// Chartboost Mediation SDK takes care of storing and disposing of ad instances so you don't need to.
    /// ``PartnerAd/invalidate()`` is called on ads before disposing of them in case partners need to perform any custom logic before the
    /// object gets destroyed.
    /// If, for some reason, a new ad cannot be provided, an error should be thrown.
    /// - parameter request: Information about the ad load request.
    /// - parameter delegate: The delegate that will receive ad life-cycle notifications.
    func makeFullscreenAd(request: PartnerAdLoadRequest, delegate: PartnerAdDelegate) throws -> PartnerFullscreenAd {
        // This partner supports multiple loads for the same partner placement.
        switch request.format {
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

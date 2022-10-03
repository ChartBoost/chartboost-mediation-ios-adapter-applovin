//
//  AppLovinAdapter.swift
//  ChartboostHeliumAdapterAppLovin
//

import Foundation
import HeliumSdk
import AppLovinSDK
import UIKit

final class AppLovinAdapter: ModularPartnerAdapter {
    /// Get the version of the partner SDK.
    let partnerSDKVersion = ALSdk.version()
    
    /// Get the version of the mediation adapter. To determine the version, use the following scheme to indicate compatibility:
    /// [Helium SDK Major Version].[Partner SDK Major Version].[Partner SDK Minor Version].[Partner SDK Patch Version].[Adapter Version]
    ///
    /// For example, if this adapter is compatible with Helium SDK 4.x.y and partner SDK 1.0.0, and this is its initial release, then its version should be 4.1.0.0.0.
    let adapterVersion = "4.11.3.1.0"
    
    /// Get the internal name of the partner.
    let partnerIdentifier = "applovin"
    
    /// Get the external/official name of the partner.
    let partnerDisplayName = "AppLovin"
    
    /// Storage of adapter instances.  Keyed by the request identifier.
    var adAdapters: [String: PartnerAdAdapter] = [:]

    /// Instance of the AppLovin SDK
    static var sdk: ALSdk? {
        didSet {
            AppLovinAdapterConfiguration.sync()
        }
    }

    /// The last value set on `setGDPRApplies(_:)`.
    private var gdprApplies = false

    /// The last value set on `setGDPRConsentStatus(_:)`.
    private var gdprStatus: GDPRConsentStatus = .unknown

    /// Override this method to initialize the partner SDK so that it's ready to request and display ads.
    /// For simplicity, the current implementation always assumes successes.
    /// - Parameters:
    ///   - configuration: The necessary initialization data provided by Helium.
    ///   - completion: Handler to notify Helium of task completion.
    func setUp(with configuration: PartnerConfiguration, completion: @escaping (Error?) -> Void) {
        log(.setUpStarted)
        guard let sdkKey = configuration.sdkKey, !sdkKey.isEmpty else {
            let error = error(.missingSetUpParameter(key: .sdkKey))
            log(.setUpFailed(error))
            return completion(error)
        }
        guard let sdk = ALSdk.shared(withKey: sdkKey) else {
            let error = error(.setUpFailure)
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
                let error = self.error(.setUpFailure, description: "AppLovin failed to initialize")
                completion(error)
            }
        }
    }
    
    /// Compute and return a bid token for the bid request.
    /// - Parameters:
    ///   - request: The necessary data associated with the current bid request.
    ///   - completion: Handler to notify Helium of task completion.
    func fetchBidderInformation(request: PreBidRequest, completion: @escaping ([String : String]) -> Void) {
        log(.fetchBidderInfoStarted(request))
        log(.fetchBidderInfoSucceeded(request))
        completion([:])
    }
    
    /// Set GDPR applicability as determined by the Helium SDK.
    /// - Parameter applies: true if GDPR applies, false otherwise.
    func setGDPRApplies(_ applies: Bool) {
        // Save value and set GDPR using both gdprApplies and gdprStatus
        gdprApplies = applies
        updateGDPRConsent()
   }
    
    /// Set the GDPR consent status as determined by the Helium SDK.
    /// - Parameter status: The user's current GDPR consent status.
    func setGDPRConsentStatus(_ status: GDPRConsentStatus) {
        // Save value and set GDPR using both gdprApplies and gdprStatus
        gdprStatus = status
        updateGDPRConsent()
    }

    private func updateGDPRConsent() {
        // Set AppLovin GDPR consent using both gdprApplies and gdprStatus
        if gdprApplies {
            // https://dash.applovin.com/docs/integration#iosPrivacySettings
            ALPrivacySettings.setHasUserConsent(gdprStatus == .granted)
            log(.privacyUpdated(setting: "'setHasUserConsent'", value: gdprStatus == .granted))
        }
    }

    /// Set the COPPA subjectivity as determined by the Helium SDK.
    /// - Parameter isSubject: True if the user is subject to COPPA, false otherwise.
    func setUserSubjectToCOPPA(_ isSubject: Bool) {
        log(.privacyUpdated(setting: "'IsAgeRestrictedUser'", value: isSubject))
        ALPrivacySettings.setIsAgeRestrictedUser(isSubject)
    }
    
    /// Set the CCPA privacy String as supplied by the Helium SDK.
    /// - Parameters:
    ///   - hasGivenConsent: True if the user has given CCPA consent, false otherwise.
    ///   - privacyString: The CCPA privacy String.
    func setCCPAConsent(hasGivenConsent: Bool, privacyString: String?) {
        // Note the NOT operator, for converting from "has not consented" to "do not sell" and vice versa
        log(.privacyUpdated(setting: "'DoNotSell'", value: !hasGivenConsent))
        ALPrivacySettings.setDoNotSell(!hasGivenConsent)
    }
    
    func makeAdAdapter(request: PartnerAdLoadRequest, partnerAdDelegate: PartnerAdDelegate) throws -> PartnerAdAdapter {
        guard let sdk = Self.sdk else {
            throw error(.loadFailure(request), description: "No SDK instance available")
        }
        switch request.format {
        case .banner:
            return AppLovinAdAdapterBanner(sdk: sdk, adapter: self, request: request, partnerAdDelegate: partnerAdDelegate)
        case .interstitial:
            return AppLovinAdAdapterInterstitial(sdk: sdk, adapter: self, request: request, partnerAdDelegate: partnerAdDelegate)
        case .rewarded:
            return AppLovinAdAdapterRewarded(sdk: sdk, adapter: self, request: request, partnerAdDelegate: partnerAdDelegate)
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

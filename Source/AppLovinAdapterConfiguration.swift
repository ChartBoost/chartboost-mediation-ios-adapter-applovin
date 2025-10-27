// Copyright 2022-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import AdSupport
import AppLovinSDK
import ChartboostMediationSDK

/// A list of externally configurable properties pertaining to the partner SDK that can be retrieved and set by publishers.
@objc public class AppLovinAdapterConfiguration: NSObject, PartnerAdapterConfiguration {
    /// The version of the partner SDK.
    @objc public static var partnerSDKVersion: String {
        ALSdk.version()
    }

    /// The version of the adapter.
    /// It should have either 5 or 6 digits separated by periods, where the first digit is Chartboost Mediation SDK's major version, the
    /// last digit is the adapter's build version, and intermediate digits are the partner SDK's version.
    /// Format: `<Chartboost Mediation major version>.<Partner major version>.<Partner minor version>.<Partner patch version>.
    /// <Partner build version>.<Adapter build version>` where `.<Partner build version>` is optional.
    @objc public static let adapterVersion = "5.13.5.0.0"

    /// The partner's unique identifier.
    @objc public static let partnerID = "applovin"

    /// The human-friendly partner name.
    @objc public static let partnerDisplayName = "AppLovin"

    /// Flag that can optionally be set to enable the partner's test mode.
    /// Disabled by default.
    @objc public static var testMode = false

    /// Flag that can optionally be set to disable the partner's audio.
    /// Disabled by default.
    @objc public static var isMuted = false {
        didSet {
            syncIsMuted()
        }
    }

    /// Flag that can optionally be set to enable the partner's verbose logging.
    /// Disabled by default.
    @objc public static var verboseLogging = false {
        didSet {
            syncVerboseLogging()
        }
    }

    /// Flag that can optionally be set to enable location collection.
    /// This property no longer does anything. `ALSdkSettings.isLocationCollectionEnabled`
    /// no longer exists starting in SDK version `12.6.0`.
    @available(*, deprecated, message: "This property no longer does anything.")
    @objc public static var locationCollection: Bool = false
}

extension AppLovinAdapterConfiguration {
    /// The AppLovin SDK instance
    private static let sdk = ALSdk.shared()

    static func sync() {
        syncVerboseLogging()
        syncIsMuted()
    }

    private static func syncVerboseLogging() {
        sdk.settings.isVerboseLoggingEnabled = verboseLogging
        log("Verbose logging set to \(verboseLogging)")
    }

    private static func syncIsMuted() {
        sdk.settings.isMuted = isMuted
        log("isMuted set to \(isMuted)")
    }
}

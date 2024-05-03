// Copyright 2022-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import AppLovinSDK
import AdSupport
import os.log

/// A list of externally configurable properties pertaining to the partner SDK that can be retrieved and set by publishers.
@objc public class AppLovinAdapterConfiguration: NSObject {
    
    /// The version of the partner SDK.
    @objc public static var partnerSDKVersion: String {
        ALSdk.version()
    }

    /// The version of the adapter.
    /// It should have either 5 or 6 digits separated by periods, where the first digit is Chartboost Mediation SDK's major version, the last digit is the adapter's build version, and intermediate digits are the partner SDK's version.
    /// Format: `<Chartboost Mediation major version>.<Partner major version>.<Partner minor version>.<Partner patch version>.<Partner build version>.<Adapter build version>` where `.<Partner build version>` is optional.
    @objc public static let adapterVersion = "5.12.4.0.0"

    /// The partner's unique identifier.
    @objc public static let partnerID = "applovin"

    /// The human-friendly partner name.
    @objc public static let partnerDisplayName = "AppLovin"

    private static let log = OSLog(subsystem: "com.chartboost.mediation.adapter.applovin", category: "Configuration")

    /// Flag that can optionally be set to enable the partner's test mode.
    /// Disabled by default.
    @objc public static var testMode: Bool = false

    /// Flag that can optionally be set to disable the partner's audio.
    /// Disabled by default.
    @objc public static var isMuted: Bool = false {
        didSet {
            syncIsMuted()
        }
    }

    /// Flag that can optionally be set to enable the partner's verbose logging.
    /// Disabled by default.
    @objc public static var verboseLogging: Bool = false {
        didSet {
            syncVerboseLogging()
        }
    }

    /// Flag that can optionally be set to enable location collection as documented at
    /// https://dash.applovin.com/documentation/mediation/ios/getting-started/data-passing#location-passing
    /// Enabled by default.
    @objc public static var locationCollection: Bool = true {
        didSet {
            syncLocationCollection()
        }
    }
}

extension AppLovinAdapterConfiguration {
    
    /// The AppLovin SDK instance
    private static let sdk: ALSdk = ALSdk.shared()

    static func sync() {
        syncVerboseLogging()
        syncLocationCollection()
        syncIsMuted()
    }

    private static func syncVerboseLogging() {
        sdk.settings.isVerboseLoggingEnabled = verboseLogging
        os_log(.debug, log: log, "AppLovin SDK verbose logging set to %{public}s", "\(verboseLogging)")
    }

    private static func syncLocationCollection() {
        sdk.settings.isLocationCollectionEnabled = locationCollection
        os_log(.debug, log: log, "AppLovin SDK location collection set to %{public}s", "\(locationCollection)")
    }

    private static func syncIsMuted() {
        sdk.settings.isMuted = isMuted
        os_log(.debug, log: log, "AppLovin SDK isMuted set to %{public}s", "\(isMuted)")
    }
}

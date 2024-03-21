// Copyright 2022-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import AppLovinSDK
import AdSupport
import os.log

/// A list of externally configurable properties pertaining to the partner SDK that can be retrieved and set by publishers.
@objc public class AppLovinAdapterConfiguration: NSObject {
    
    private static let log = OSLog(subsystem: "com.chartboost.mediation.adapter.applovin", category: "Configuration")

    /// Flag that can optionally be set to enable the partner's test mode.
    /// Disabled by default.
    @objc public static var testMode: Bool = false {
        didSet {
            syncTestMode()
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
    static var sdk: ALSdk? { AppLovinAdapter.sdk }
    
    
    static func sync() {
        syncTestMode()
        syncVerboseLogging()
        syncLocationCollection()
    }

    static func syncTestMode() {
        if testMode {
            let idfa = ASIdentifierManager.shared().advertisingIdentifier
            if idfa.uuidString == "00000000-0000-0000-0000-000000000000" {
                if #available(iOS 12.0, *) {
                    os_log(.info, log: log, "Invalid IDFA set for AppLovin test mode. Check user privacy settings.")
                }
            }
        }
        if #available(iOS 12.0, *) {
            os_log(.debug, log: log, "AppLovin SDK test mode set to %{public}s", "\(testMode)")
        }
    }

    static func syncVerboseLogging() {
        guard let sdk = Self.sdk else { return }
        sdk.settings.isVerboseLoggingEnabled = verboseLogging
        if #available(iOS 12.0, *) {
            os_log(.debug, log: log, "AppLovin SDK verbose logging set to %{public}s", "\(verboseLogging)")
        }
    }

    static func syncLocationCollection() {
        guard let sdk = Self.sdk else { return }
        sdk.settings.isLocationCollectionEnabled = locationCollection
        if #available(iOS 12.0, *) {
            os_log(.debug, log: log, "AppLovin SDK location collection set to %{public}s", "\(locationCollection)")
        }
    }
}

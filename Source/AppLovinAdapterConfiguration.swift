//
//  AppLovinAdapterConfiguration.swift
//  ChartboostHeliumAdapterAppLovin
//

import AppLovinSDK
import AdSupport

/// A list of externally configurable properties pertaining to the partner SDK that can be retrieved and set by publishers.
@objc public class AppLovinAdapterConfiguration: NSObject {
    
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
}

extension AppLovinAdapterConfiguration {
    
    /// The AppLovin SDK instance
    static var sdk: ALSdk? { AppLovinAdapter.sdk }
    
    static func sync() {
        syncTestMode()
        syncVerboseLogging()
    }

    static func syncTestMode() {
        guard let sdk = Self.sdk else { return }
        if testMode {
            let idfa = ASIdentifierManager.shared().advertisingIdentifier
            if idfa.uuidString == "00000000-0000-0000-0000-000000000000" {
                print("Invalid IDFA set for AppLovin test mode. Check user privacy settings.")
            }
            else {
                sdk.settings.testDeviceAdvertisingIdentifiers = [idfa.uuidString]
            }
        }
        else {
            sdk.settings.testDeviceAdvertisingIdentifiers = []
        }
        print("AppLovin SDK test mode set to \(testMode)")
    }

    static func syncVerboseLogging() {
        guard let sdk = Self.sdk else { return }
        sdk.settings.isVerboseLogging = verboseLogging
        print("AppLovin SDK verbose logging set to \(verboseLogging)")
    }
}

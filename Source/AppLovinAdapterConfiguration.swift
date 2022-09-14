//
//  AppLovinAdapterConfiguration.swift
//

import AppLovinSDK
import AdSupport

/// A list of externally configurable properties pertaining to the partner SDK that can be retrieved and set by publishers.
public class AppLovinAdapterConfiguration {
    /// The AppLovin SDK instance
    static var sdk: ALSdk? { AppLovinAdapter.sdk }

    /// Flag that can optionally be set to enable the partner's test mode.
    /// Disabled by default.
    private static var _testMode = false
    public static var testMode: Bool {
        get {
            return _testMode
        }
        set {
            _testMode = newValue
            syncTestMode()
        }
    }
    
    /// Flag that can optionally be set to enable the partner's verbose logging.
    /// Disabled by default.
    private static var _verboseLogging = false
    public static var verboseLogging: Bool {
        get {
            return _verboseLogging
        }
        set {
            _verboseLogging = newValue
            syncVerboseLogging()
        }
    }
    
    /// Append any other properties that publishers can configure.
}

extension AppLovinAdapterConfiguration {
    static func sync() {
        syncTestMode()
        syncVerboseLogging()
    }

    static func syncTestMode() {
        guard let sdk = Self.sdk else { return }
        if _testMode {
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
        print("The AppLovin SDK's test mode is \(_testMode ? "enabled" : "disabled").")
    }

    static func syncVerboseLogging() {
        guard let sdk = Self.sdk else { return }
        sdk.settings.isVerboseLogging = _verboseLogging
        print("The AppLovin SDK's verbose logging is \(_verboseLogging ? "enabled" : "disabled").")
    }
}

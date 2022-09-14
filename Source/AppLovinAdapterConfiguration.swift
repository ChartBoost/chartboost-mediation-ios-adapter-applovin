//
//  AppLovinAdapterConfiguration.swift
//

import Foundation

/// A list of externally configurable properties pertaining to the partner SDK that can be retrieved and set by publishers.
public class AppLovinAdapterConfiguration {
    /// Flag that can optionally be set to enable the partner's test mode.
    /// Disabled by default.
    private static var _testMode = false
    public static var testMode: Bool {
        get {
            return _testMode
        }
        set {
            _testMode = newValue
//            ReferenceSdk.setTestMode(enabled: newValue)
            print("The Reference SDK's test mode is \(newValue ? "enabled" : "disabled").")
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
//            ReferenceSdk.setVerboseLogging(enabled: newValue)
            print("The Reference SDK's verbose logging is \(newValue ? "enabled" : "disabled").")
            
        }
    }
    
    /// Append any other properties that publishers can configure.
}

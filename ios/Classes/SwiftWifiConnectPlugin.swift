import Flutter
import plugin_scaffold
import UIKit
import SystemConfiguration.CaptiveNetwork
import NetworkExtension

public class SwiftWifiConnectPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let plugin = SwiftWifiConnectPlugin()
        let messenger = registrar.messenger()
        _ = createPluginScaffold(
            messenger: messenger,
            channelName: "wifi_connect",
            methodMap: [
                "getConnectedSSID": plugin.getConnectedSSID,
                "connect": plugin.connect,
                "connectedSSIDOnListen": plugin.connectedSSIDOnListen,
                "connectedSSIDOnCancel": plugin.connectedSSIDOnCancel
            ]
        )
    }
    
    var timers = [Int: Timer]()
    
    func connectedSSIDOnListen(id: Int, args: Any?, sink: @escaping FlutterEventSink) {
        timers[id] = Timer.scheduledTimer(withTimeInterval: args as! Double / 1000, repeats: true) {_ in
            sink(self._getConnectedSSID())
        }
    }
    
    func connectedSSIDOnCancel(id: Int, args: Any?) {
        timers.removeValue(forKey: id)?.invalidate()
    }
    
    
    func getConnectedSSID(call: FlutterMethodCall, result: @escaping FlutterResult) {
        result(_getConnectedSSID())
    }
    
    func _getConnectedSSID() -> String {
        let ifaces = CNCopySupportedInterfaces() as NSArray? ?? []
        var ssid: String? = nil
        
        for iface in ifaces {
            if let interfaceInfo = CNCopyCurrentNetworkInfo(iface as! CFString) as NSDictionary? {
                ssid = interfaceInfo[kCNNetworkInfoKeySSID as String] as? String
                break
            }
        }

        return ssid ?? ""
    }
    
    func connect(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as! [String: Any]
        let ssid = args["ssid"] as! String
        let password = args["password"] as! String
        
        let config = NEHotspotConfiguration.init(ssid: ssid, passphrase: password, isWEP: false)
        
        NEHotspotConfigurationManager.shared.apply(config) {error in
            if let error = error as NSError? {
                switch(error.code) {
                case NEHotspotConfigurationError.userDenied.rawValue:
                    trySend(result) { 1 }
                    break
                case NEHotspotConfigurationError.alreadyAssociated.rawValue:
                    trySend(result) { 0 }
                    break
                default:
                    trySendError(result, error)
                    break
                }             
            } else {
                trySend(result) { 0 }
            }
        }
    }
}

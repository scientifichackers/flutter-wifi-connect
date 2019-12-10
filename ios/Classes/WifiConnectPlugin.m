#import "WifiConnectPlugin.h"
#import <wifi_connect/wifi_connect-Swift.h>

@implementation WifiConnectPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftWifiConnectPlugin registerWithRegistrar:registrar];
}
@end

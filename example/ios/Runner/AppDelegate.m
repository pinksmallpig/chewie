#include "AppDelegate.h"
#include "GeneratedPluginRegistrant.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    FlutterViewController* controller = (FlutterViewController*)self.window.rootViewController;
    FlutterMethodChannel* setOrientationPortrait = [FlutterMethodChannel
                                            methodChannelWithName:@"chewie/setOrientationPortrait"
                                            binaryMessenger:controller];

    [setOrientationPortrait setMethodCallHandler:^(FlutterMethodCall* call, FlutterResult result) {
        if ([@"setOrientationPortrait" isEqualToString:call.method]) {
            [AppDelegate setOrientationPortrait];
        } else {
            result(FlutterMethodNotImplemented);
        }
    }];

    FlutterMethodChannel* setOrientationLandscapeRight = [FlutterMethodChannel
                                                    methodChannelWithName:@"chewie/setOrientationLandscapeRight"
                                                    binaryMessenger:controller];

    [setOrientationLandscapeRight setMethodCallHandler:^(FlutterMethodCall* call, FlutterResult result) {
        if ([@"setOrientationLandscapeRight" isEqualToString:call.method]) {
            [AppDelegate setOrientationLandscapeRight];
        } else {
            result(FlutterMethodNotImplemented);
        }
    }];

  [GeneratedPluginRegistrant registerWithRegistry:self];
  // Override point for customization after application launch.
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}


+ (void)setOrientationPortrait{
    [[UIDevice currentDevice] setValue:@(UIInterfaceOrientationUnknown) forKey:@"orientation"];
    [[UIDevice currentDevice] setValue:@(UIInterfaceOrientationPortrait) forKey:@"orientation"];
}

+ (void)setOrientationLandscapeRight{
    [[UIDevice currentDevice] setValue:@(UIInterfaceOrientationUnknown) forKey:@"orientation"];
    [[UIDevice currentDevice] setValue:@(UIInterfaceOrientationLandscapeRight) forKey:@"orientation"];
}

@end

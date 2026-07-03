#import "CHIdentityEngine.h"
#import "CHContainerManager.h"
#import <substrate.h>

static void (*orig_UIApplication)(id, SEL);
static void hooked_UIApplication(id self, SEL _cmd);

%ctor {
    @autoreleasepool {
        NSDictionary *defaultPrefs = @{
            @"Enabled": @YES, @"ShowPicker": @YES,
            @"SpoofUIDevice": @YES, @"SpoofMGCopyAnswer": @YES,
            @"SpoofASIdentifier": @YES, @"SpoofCanvas": @YES,
            @"SpoofSysctl": @YES, @"SpoofIOKit": @YES, @"SpoofNetwork": @YES,
        };
        [[[NSUserDefaults alloc] initWithSuiteName:@"com.chameleon.prefs"] registerDefaults:defaultPrefs];

        [CHContainerManager sharedManager];
        [CHIdentityEngine sharedEngine];

        MSHookMessageEx(
            objc_getClass("UIApplication"),
            @selector(setDelegate:),
            (IMP)hooked_UIApplication,
            (IMP *)&orig_UIApplication
        );
    }
}

static void hooked_UIApplication(id self, SEL _cmd) {
    orig_UIApplication(self, _cmd);

    CHIdentityEngine *engine = [CHIdentityEngine sharedEngine];
    NSString *bundleID = [engine currentBundleID];
    if (!bundleID) return;

    NSString *uuid = [[CHContainerManager sharedManager] activeContainerForBundleID:bundleID];
    CHDeviceIdentity *identity = [engine identityForBundleID:bundleID containerUUID:uuid];
    if (!identity) return;

    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    info[@"IDFV"] = identity.identifierForVendor ?: @"";
    info[@"IDFA"] = identity.advertisingIdentifier ?: @"";
    info[@"DeviceName"] = identity.deviceName ?: @"";
    info[@"Model"] = identity.deviceModel ?: @"";
    info[@"ProductType"] = identity.productType ?: @"";
    info[@"Serial"] = identity.serialNumber ?: @"";
    info[@"UDID"] = identity.uniqueDeviceID ?: @"";
    info[@"WiFi"] = identity.wifiAddress ?: @"";
    info[@"BT"] = identity.bluetoothAddress ?: @"";
    info[@"BootTime"] = @(identity.bootTimeEpoch);
    info[@"BatteryLevel"] = @(identity.batteryLevel);
    info[@"OSVersion"] = identity.systemVersion ?: @"";
    [[NSUserDefaults standardUserDefaults] setObject:info forKey:@"ChameleonIdentity"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

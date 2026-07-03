#import "CHIdentityEngine.h"

%hook UIDevice

- (NSString *)identifierForVendor {
    if (![CHIdentityEngine isHookEnabled:@"SpoofUIDevice"]) return %orig;
    CHDeviceIdentity *identity = [[CHIdentityEngine sharedEngine] currentIdentity];
    if (identity.identifierForVendor) return identity.identifierForVendor;
    return %orig;
}

- (NSString *)name {
    if (![CHIdentityEngine isHookEnabled:@"SpoofUIDevice"]) return %orig;
    CHDeviceIdentity *identity = [[CHIdentityEngine sharedEngine] currentIdentity];
    if (identity.deviceName) return identity.deviceName;
    return %orig;
}

- (NSString *)model {
    if (![CHIdentityEngine isHookEnabled:@"SpoofUIDevice"]) return %orig;
    CHDeviceIdentity *identity = [[CHIdentityEngine sharedEngine] currentIdentity];
    if (identity.deviceModel) return identity.deviceModel;
    return %orig;
}

- (NSString *)systemVersion {
    if (![CHIdentityEngine isHookEnabled:@"SpoofUIDevice"]) return %orig;
    CHDeviceIdentity *identity = [[CHIdentityEngine sharedEngine] currentIdentity];
    if (identity.systemVersion) return identity.systemVersion;
    return %orig;
}

- (float)batteryLevel {
    if (![CHIdentityEngine isHookEnabled:@"SpoofUIDevice"]) return %orig;
    CHDeviceIdentity *identity = [[CHIdentityEngine sharedEngine] currentIdentity];
    if (identity.batteryLevel > 0) return identity.batteryLevel;
    return %orig;
}

- (UIDeviceBatteryState)batteryState {
    if (![CHIdentityEngine isHookEnabled:@"SpoofUIDevice"]) return %orig;
    CHDeviceIdentity *identity = [[CHIdentityEngine sharedEngine] currentIdentity];
    if (identity.batteryState >= 0) return (UIDeviceBatteryState)identity.batteryState;
    return %orig;
}

%end

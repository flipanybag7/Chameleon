#import "CHIdentityEngine.h"
#import <AdSupport/AdSupport.h>

%hook ASIdentifierManager

- (NSUUID *)advertisingIdentifier {
    if (![CHIdentityEngine isHookEnabled:@"SpoofASIdentifier"]) return %orig;
    CHDeviceIdentity *identity = [[CHIdentityEngine sharedEngine] currentIdentity];
    if (identity.advertisingIdentifier) {
        return [[NSUUID alloc] initWithUUIDString:identity.advertisingIdentifier];
    }
    return %orig;
}

- (BOOL)isAdvertisingTrackingEnabled {
    if (![CHIdentityEngine isHookEnabled:@"SpoofASIdentifier"]) return %orig;
    return NO;
}

%end

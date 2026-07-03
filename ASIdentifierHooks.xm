#import "CHIdentityEngine.h"
#import <AdSupport/AdSupport.h>

%hook ASIdentifierManager

- (NSUUID *)advertisingIdentifier {
    CHDeviceIdentity *identity = [[CHIdentityEngine sharedEngine] currentIdentity];
    if (identity.advertisingIdentifier) {
        return [[NSUUID alloc] initWithUUIDString:identity.advertisingIdentifier];
    }
    return %orig;
}

- (BOOL)isAdvertisingTrackingEnabled {
    return NO;
}

%end

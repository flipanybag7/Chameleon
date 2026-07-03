#import "CHIdentityEngine.h"
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>

%hook CTTelephonyNetworkInfo

- (CTCarrier *)subscriberCellularProvider {
    if (![CHIdentityEngine isHookEnabled:@"SpoofNetwork"]) return %orig;
    CHDeviceIdentity *identity = [[CHIdentityEngine sharedEngine] currentIdentity];
    if (!identity) return %orig;

    CTCarrier *fakeCarrier = [[CTCarrier alloc] init];
    [fakeCarrier setValue:@"310" forKey:@"mobileCountryCode"];
    [fakeCarrier setValue:@"260" forKey:@"mobileNetworkCode"];
    [fakeCarrier setValue:@"Chameleon Mobile" forKey:@"carrierName"];
    [fakeCarrier setValue:@"US" forKey:@"isoCountryCode"];
    [fakeCarrier setValue:@YES forKey:@"allowsVOIP"];

    return fakeCarrier;
}

- (NSString *)currentRadioAccessTechnology {
    if (![CHIdentityEngine isHookEnabled:@"SpoofNetwork"]) return %orig;
    return @"CTRadioAccessTechnologyLTE";
}

- (NSDictionary *)serviceSubscriberCellularProviders {
    if (![CHIdentityEngine isHookEnabled:@"SpoofNetwork"]) return %orig;
    CHDeviceIdentity *identity = [[CHIdentityEngine sharedEngine] currentIdentity];
    if (!identity) return %orig;

    CTCarrier *fakeCarrier = [[CTCarrier alloc] init];
    [fakeCarrier setValue:@"310" forKey:@"mobileCountryCode"];
    [fakeCarrier setValue:@"260" forKey:@"mobileNetworkCode"];
    [fakeCarrier setValue:@"Chameleon Mobile" forKey:@"carrierName"];
    [fakeCarrier setValue:@"US" forKey:@"isoCountryCode"];
    [fakeCarrier setValue:@YES forKey:@"allowsVOIP"];

    return @{@"0000000100000001": fakeCarrier};
}

%end

%hook CTCarrier

- (NSString *)carrierName {
    if (![CHIdentityEngine isHookEnabled:@"SpoofNetwork"]) return %orig;
    return @"Chameleon Mobile";
}

- (NSString *)mobileCountryCode {
    if (![CHIdentityEngine isHookEnabled:@"SpoofNetwork"]) return %orig;
    return @"310";
}

- (NSString *)mobileNetworkCode {
    if (![CHIdentityEngine isHookEnabled:@"SpoofNetwork"]) return %orig;
    return @"260";
}

- (NSString *)isoCountryCode {
    if (![CHIdentityEngine isHookEnabled:@"SpoofNetwork"]) return %orig;
    return @"US";
}

%end

#import "CHIdentityEngine.h"
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>

%hook CTTelephonyNetworkInfo

- (CTCarrier *)subscriberCellularProvider {
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
    return @"CTRadioAccessTechnologyLTE";
}

- (NSDictionary *)serviceSubscriberCellularProviders {
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
    return @"Chameleon Mobile";
}

- (NSString *)mobileCountryCode {
    return @"310";
}

- (NSString *)mobileNetworkCode {
    return @"260";
}

- (NSString *)isoCountryCode {
    return @"US";
}

%end

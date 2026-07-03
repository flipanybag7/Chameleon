#import "CHIdentityEngine.h"
#import <MobileGestalt/MobileGestalt.h>
#import <substrate.h>

static CFTypeRef (*orig_MGCopyAnswer)(CFStringRef key);
static CFTypeRef hooked_MGCopyAnswer(CFStringRef key);

%ctor {
    MSHookFunction((void *)MGCopyAnswer, (void *)hooked_MGCopyAnswer, (void **)&orig_MGCopyAnswer);
}

static CFTypeRef hooked_MGCopyAnswer(CFStringRef key) {
    if (!key) {
        return orig_MGCopyAnswer(key);
    }

    NSString *keyStr = (__bridge NSString *)key;
    CHDeviceIdentity *identity = [[CHIdentityEngine sharedEngine] currentIdentity];

    if (!identity) {
        return orig_MGCopyAnswer(key);
    }

    NSDictionary *spoofMap = @{
        @"UniqueDeviceID":            identity.uniqueDeviceID ?: [NSNull null],
        @"SerialNumber":              identity.serialNumber ?: [NSNull null],
        @"MLBSerialNumber":           identity.serialNumber ?: [NSNull null],
        @"WifiAddress":               identity.wifiAddress ?: [NSNull null],
        @"BluetoothAddress":          identity.bluetoothAddress ?: [NSNull null],
        @"EthernetAddress":           identity.wifiAddress ?: [NSNull null],
        @"InternationalMobileEquipmentIdentity": identity.IMEI ?: [NSNull null],
        @"IntegratedCircuitCardIdentifier":       identity.ICCID ?: [NSNull null],
        @"BasebandSerialNumber":      identity.basebandSerial ?: [NSNull null],
        @"BasebandChipId":            identity.chipID ?: [NSNull null],
        @"ChipID":                    identity.chipID ?: [NSNull null],
        @"HardwarePlatform":          identity.productType ?: [NSNull null],
        @"ProductType":               identity.productType ?: [NSNull null],
        @"BoardId":                   identity.boardID ?: [NSNull null],
        @"UserAssignedDeviceName":    identity.deviceName ?: [NSNull null],
        @"ApRawProductTypes":         identity.productType ?: [NSNull null],
        @"DeviceColor":               @"#000000",
        @"DeviceEnclosureColor":      @"#000000",
    };

    id spoofedValue = spoofMap[keyStr];
    if (spoofedValue && spoofedValue != [NSNull null]) {
        if ([spoofedValue isKindOfClass:[NSString class]]) {
            return CFStringCreateCopy(kCFAllocatorDefault, (__bridge CFStringRef)spoofedValue);
        }
        if ([spoofedValue isKindOfClass:[NSData class]]) {
            return CFDataCreateCopy(kCFAllocatorDefault, (__bridge CFDataRef)spoofedValue);
        }
        if ([spoofedValue isKindOfClass:[NSNumber class]]) {
            CFNumberType numType = CFNumberGetType((CFNumberRef)(__bridge CFTypeRef)spoofedValue);
            double val = [spoofedValue doubleValue];
            return CFNumberCreate(kCFAllocatorDefault, numType, &val);
        }
    }

    id customValue = identity.additionalKeys[keyStr];
    if (customValue) {
        if ([customValue isKindOfClass:[NSString class]]) {
            return CFStringCreateCopy(kCFAllocatorDefault, (__bridge CFStringRef)customValue);
        }
        if ([customValue isKindOfClass:[NSData class]]) {
            return CFDataCreateCopy(kCFAllocatorDefault, (__bridge CFDataRef)customValue);
        }
    }

    return orig_MGCopyAnswer(key);
}

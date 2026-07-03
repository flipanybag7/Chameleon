#import "CHIdentityEngine.h"
#import <IOKit/IOKitLib.h>
#import <substrate.h>

static CFTypeRef (*orig_IORegistryEntryCreateCFProperty)(io_registry_entry_t, CFStringRef, CFAllocatorRef, IOOptionBits);
static CFTypeRef hooked_IORegistryEntryCreateCFProperty(io_registry_entry_t entry, CFStringRef key, CFAllocatorRef allocator, IOOptionBits options);

static io_registry_entry_t (*orig_IOServiceGetMatchingService)(mach_port_t, CFDictionaryRef);
static io_registry_entry_t hooked_IOServiceGetMatchingService(mach_port_t masterPort, CFDictionaryRef matching);

%ctor {
    MSHookFunction((void *)IORegistryEntryCreateCFProperty,
                   (void *)hooked_IORegistryEntryCreateCFProperty,
                   (void **)&orig_IORegistryEntryCreateCFProperty);
    MSHookFunction((void *)IOServiceGetMatchingService,
                   (void *)hooked_IOServiceGetMatchingService,
                   (void **)&orig_IOServiceGetMatchingService);
}

static CFTypeRef hooked_IORegistryEntryCreateCFProperty(io_registry_entry_t entry, CFStringRef key, CFAllocatorRef allocator, IOOptionBits options) {
    if (!key) {
        return orig_IORegistryEntryCreateCFProperty(entry, key, allocator, options);
    }

    NSString *keyStr = (__bridge NSString *)key;
    CHDeviceIdentity *identity = [[CHIdentityEngine sharedEngine] currentIdentity];

    if (!identity) {
        return orig_IORegistryEntryCreateCFProperty(entry, key, allocator, options);
    }

    NSDictionary *spoofMap = @{
        @"serial-number":              identity.serialNumber ?: [NSNull null],
        @"device-id":                  identity.chipID ?: [NSNull null],
        @"board-id":                   identity.boardID ?: [NSNull null],
        @"chip-id":                    identity.chipID ?: [NSNull null],
        @"unique-device-id":           identity.uniqueDeviceID ?: [NSNull null],
        @"wifi-address":               identity.wifiAddress ?: [NSNull null],
        @"bluetooth-address":          identity.bluetoothAddress ?: [NSNull null],
        @"ethernet-address":           identity.wifiAddress ?: [NSNull null],
        @"model":                      identity.productType ?: [NSNull null],
        @"product-name":               identity.productType ?: [NSNull null],
        @"product-type":               identity.productType ?: [NSNull null],
        @"mlb-serial-number":          identity.serialNumber ?: [NSNull null],
        @"rom":                        identity.uniqueDeviceID ?: [NSNull null],
        @"imei":                       identity.IMEI ?: [NSNull null],
        @"imei2":                      identity.IMEI ?: [NSNull null],
    };

    id spoofed = spoofMap[keyStr];
    if (spoofed && spoofed != [NSNull null]) {
        CFStringRef result = CFStringCreateCopy(kCFAllocatorDefault, (__bridge CFStringRef)spoofed);
        return result;
    }

    return orig_IORegistryEntryCreateCFProperty(entry, key, allocator, options);
}

static io_registry_entry_t hooked_IOServiceGetMatchingService(mach_port_t masterPort, CFDictionaryRef matching) {
    return orig_IOServiceGetMatchingService(masterPort, matching);
}

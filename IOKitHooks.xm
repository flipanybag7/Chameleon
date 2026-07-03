#import "CHIdentityEngine.h"
#import <substrate.h>
#import <dlfcn.h>

typedef unsigned int io_registry_entry_t;
typedef unsigned int IOOptionBits;

static CFTypeRef (*orig_IORegistryEntryCreateCFProperty)(io_registry_entry_t, CFStringRef, CFAllocatorRef, IOOptionBits);
static CFTypeRef hooked_IORegistryEntryCreateCFProperty(io_registry_entry_t entry, CFStringRef key, CFAllocatorRef allocator, IOOptionBits options);

%ctor {
    void *iokit = dlopen("/System/Library/Frameworks/IOKit.framework/IOKit", RTLD_NOLOAD);
    if (!iokit) {
        iokit = dlopen("/System/Library/Frameworks/IOKit.framework/IOKit", RTLD_LAZY | RTLD_LOCAL);
    }
    if (iokit) {
        void *IORegFunc = dlsym(iokit, "IORegistryEntryCreateCFProperty");
        if (IORegFunc) {
            MSHookFunction(IORegFunc, (void *)hooked_IORegistryEntryCreateCFProperty, (void **)&orig_IORegistryEntryCreateCFProperty);
        }
    }
}

static CFTypeRef hooked_IORegistryEntryCreateCFProperty(io_registry_entry_t entry, CFStringRef key, CFAllocatorRef allocator, IOOptionBits options) {
    if (!key) {
        return orig_IORegistryEntryCreateCFProperty(entry, key, allocator, options);
    }

    if (![CHIdentityEngine isHookEnabled:@"SpoofIOKit"]) {
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

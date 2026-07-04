#import <Foundation/Foundation.h>
#import <Security/Security.h>
#import <CommonCrypto/CommonCrypto.h>
#import <substrate.h>
#import <dlfcn.h>
#import "CHContainerManager.h"

static NSString *KeychainKey(CFDictionaryRef query) {
    NSDictionary *q = (__bridge NSDictionary *)query;
    return [NSString stringWithFormat:@"%@|%@|%@",
            q[(__bridge id)kSecAttrService] ?: @"",
            q[(__bridge id)kSecAttrAccount] ?: @"",
            q[(__bridge id)kSecAttrAccessGroup] ?: @""];
}

static NSData *SpoofedKeychainData(NSString *key, NSString *seed) {
    NSString *combined = [NSString stringWithFormat:@"kc:%@:%@", seed, key];
    const char *str = combined.UTF8String;
    unsigned char hash[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(str, (CC_LONG)strlen(str), hash);
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDBytes:*(uuid_t *)hash];
    return [[uuid UUIDString] dataUsingEncoding:NSUTF8StringEncoding];
}

static NSMutableDictionary *gKC;
static NSString *gKCSeed;

static OSStatus (*orig_SecItemCopyMatching)(CFDictionaryRef, CFTypeRef *);
static OSStatus my_SecItemCopyMatching(CFDictionaryRef query, CFTypeRef *result) {
    if (result && query) {
        NSString *key = KeychainKey(query);
        NSString *spoofed = [gKC objectForKey:key];
        if (!spoofed) {
            spoofed = [[NSString alloc] initWithData:SpoofedKeychainData(key, gKCSeed) encoding:NSUTF8StringEncoding];
            [gKC setObject:spoofed forKey:key];
        }
        NSDictionary *q = (__bridge NSDictionary *)query;
        if ([q[(__bridge id)kSecReturnData] boolValue]) {
            NSData *data = [spoofed dataUsingEncoding:NSUTF8StringEncoding];
            *result = CFBridgingRetain(data);
            return errSecSuccess;
        }
        if ([q[(__bridge id)kSecReturnAttributes] boolValue]) {
            *result = CFBridgingRetain(@{(__bridge id)kSecAttrAccount: spoofed});
            return errSecSuccess;
        }
        *result = NULL;
        return errSecSuccess;
    }
    return orig_SecItemCopyMatching(query, result);
}

static OSStatus (*orig_SecItemAdd)(CFDictionaryRef, CFTypeRef *);
static OSStatus my_SecItemAdd(CFDictionaryRef attrs, CFTypeRef *result) {
    if (attrs) {
        NSString *key = KeychainKey(attrs);
        NSDictionary *a = (__bridge NSDictionary *)attrs;
        NSData *val = a[(__bridge id)kSecValueData];
        if (val) {
            [gKC setObject:[[NSString alloc] initWithData:val encoding:NSUTF8StringEncoding] forKey:key];
        }
        if (result) *result = NULL;
        return errSecSuccess;
    }
    return orig_SecItemAdd(attrs, result);
}

static OSStatus (*orig_SecItemDelete)(CFDictionaryRef);
static OSStatus my_SecItemDelete(CFDictionaryRef query) {
    if (query) {
        [gKC removeObjectForKey:KeychainKey(query)];
        return errSecSuccess;
    }
    return orig_SecItemDelete(query);
}

%ctor {
    @autoreleasepool {
        gKC = [NSMutableDictionary dictionary];
        NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier] ?: @"unknown";
        NSString *uuid = [[CHContainerManager sharedManager] activeContainerForBundleID:bundleID];
        gKCSeed = [NSString stringWithFormat:@"%@|%@", bundleID, uuid ?: @"default"];

        NSString *path = [NSString stringWithFormat:@"%@/Library/Chameleon/keychain.plist", NSHomeDirectory()];
        NSDictionary *saved = [NSDictionary dictionaryWithContentsOfFile:path];
        if (saved) [gKC addEntriesFromDictionary:saved];

        void *handle = dlopen("/System/Library/Frameworks/Security.framework/Security", RTLD_NOLOAD);
        if (!handle) handle = dlopen("/System/Library/Frameworks/Security.framework/Security", RTLD_LAZY);
        if (handle) {
            MSHookFunction(dlsym(handle, "SecItemCopyMatching"), (void *)my_SecItemCopyMatching, (void **)&orig_SecItemCopyMatching);
            MSHookFunction(dlsym(handle, "SecItemAdd"), (void *)my_SecItemAdd, (void **)&orig_SecItemAdd);
            MSHookFunction(dlsym(handle, "SecItemDelete"), (void *)my_SecItemDelete, (void **)&orig_SecItemDelete);
        }
    }
}

#import "CHIdentityEngine.h"
#import <sys/sysctl.h>
#import <substrate.h>

static int (*orig_sysctl)(int *, u_int, void *, size_t *, void *, size_t);
static int hooked_sysctl(int *mib, u_int namelen, void *oldp, size_t *oldlenp, void *newp, size_t newlen);

static int (*orig_sysctlbyname)(const char *, void *, size_t *, void *, size_t);
static int hooked_sysctlbyname(const char *name, void *oldp, size_t *oldlenp, void *newp, size_t newlen);

%ctor {
    MSHookFunction((void *)sysctl, (void *)hooked_sysctl, (void **)&orig_sysctl);
    MSHookFunction((void *)sysctlbyname, (void *)hooked_sysctlbyname, (void **)&orig_sysctlbyname);
}

static int hooked_sysctl(int *mib, u_int namelen, void *oldp, size_t *oldlenp, void *newp, size_t newlen) {
    if (namelen >= 2 && mib[0] == CTL_HW && oldp && oldlenp) {
        CHDeviceIdentity *identity = [[CHIdentityEngine sharedEngine] currentIdentity];
        if (!identity) return orig_sysctl(mib, namelen, oldp, oldlenp, newp, newlen);

        switch (mib[1]) {
            case HW_MACHINE: {
                const char *val = [identity.productType UTF8String];
                size_t needed = strlen(val) + 1;
                if (*oldlenp >= needed) {
                    memcpy(oldp, val, needed);
                    *oldlenp = needed;
                    return 0;
                }
                break;
            }
            case HW_MODEL: {
                const char *val = [identity.hwModel UTF8String];
                size_t needed = strlen(val) + 1;
                if (*oldlenp >= needed) {
                    memcpy(oldp, val, needed);
                    *oldlenp = needed;
                    return 0;
                }
                break;
            }
            case HW_MEMSIZE: {
                uint64_t fakeMem = identity.fakeMemorySize;
                if (*oldlenp >= sizeof(fakeMem)) {
                    memcpy(oldp, &fakeMem, sizeof(fakeMem));
                    *oldlenp = sizeof(fakeMem);
                    return 0;
                }
                break;
            }
        }
    }

    if (namelen == 2 && mib[0] == CTL_KERN && mib[1] == KERN_BOOTTIME && oldp && oldlenp) {
        CHDeviceIdentity *identity = [[CHIdentityEngine sharedEngine] currentIdentity];
        if (identity && *oldlenp >= sizeof(struct timeval)) {
            struct timeval fakeBoot = {0};
            fakeBoot.tv_sec = (__darwin_time_t)identity.bootTimeEpoch;
            fakeBoot.tv_usec = 0;
            memcpy(oldp, &fakeBoot, sizeof(struct timeval));
            *oldlenp = sizeof(struct timeval);
            return 0;
        }
    }

    return orig_sysctl(mib, namelen, oldp, oldlenp, newp, newlen);
}

static int hooked_sysctlbyname(const char *name, void *oldp, size_t *oldlenp, void *newp, size_t newlen) {
    if (!name || !oldp || !oldlenp) {
        return orig_sysctlbyname(name, oldp, oldlenp, newp, newlen);
    }

    CHDeviceIdentity *identity = [[CHIdentityEngine sharedEngine] currentIdentity];

    if (!identity) {
        return orig_sysctlbyname(name, oldp, oldlenp, newp, newlen);
    }

    NSString *nameStr = [NSString stringWithUTF8String:name];

    if ([nameStr isEqualToString:@"hw.machine"]) {
        const char *val = [identity.productType UTF8String];
        size_t needed = strlen(val) + 1;
        if (*oldlenp >= needed) {
            memcpy(oldp, val, needed);
            *oldlenp = needed;
            return 0;
        }
    }

    if ([nameStr isEqualToString:@"hw.model"]) {
        const char *val = [identity.hwModel UTF8String];
        size_t needed = strlen(val) + 1;
        if (*oldlenp >= needed) {
            memcpy(oldp, val, needed);
            *oldlenp = needed;
            return 0;
        }
    }

    if ([nameStr isEqualToString:@"hw.memsize"]) {
        uint64_t fakeMem = identity.fakeMemorySize;
        if (*oldlenp >= sizeof(fakeMem)) {
            memcpy(oldp, &fakeMem, sizeof(fakeMem));
            *oldlenp = sizeof(fakeMem);
            return 0;
        }
    }

    if ([nameStr isEqualToString:@"kern.boottime"]) {
        if (*oldlenp >= sizeof(struct timeval)) {
            struct timeval fakeBoot = {0};
            fakeBoot.tv_sec = (__darwin_time_t)identity.bootTimeEpoch;
            fakeBoot.tv_usec = 0;
            memcpy(oldp, &fakeBoot, sizeof(struct timeval));
            *oldlenp = sizeof(struct timeval);
            return 0;
        }
    }

    if ([nameStr isEqualToString:@"kern.hostname"]) {
        NSString *hostname = identity.deviceName ?: @"iPhone";
        const char *val = [hostname UTF8String];
        size_t needed = strlen(val) + 1;
        if (*oldlenp >= needed) {
            memcpy(oldp, val, needed);
            *oldlenp = needed;
            return 0;
        }
    }

    return orig_sysctlbyname(name, oldp, oldlenp, newp, newlen);
}

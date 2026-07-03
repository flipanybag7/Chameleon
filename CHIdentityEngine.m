#import "CHIdentityEngine.h"
#import <CommonCrypto/CommonCrypto.h>
#import <sys/stat.h>
#import <dlfcn.h>

static CHIdentityEngine *sharedEngine = nil;

@implementation CHDeviceIdentity

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.identifierForVendor forKey:@"IDFV"];
    [coder encodeObject:self.advertisingIdentifier forKey:@"IDFA"];
    [coder encodeObject:self.deviceName forKey:@"deviceName"];
    [coder encodeObject:self.deviceModel forKey:@"deviceModel"];
    [coder encodeObject:self.systemVersion forKey:@"systemVersion"];
    [coder encodeObject:self.productType forKey:@"productType"];
    [coder encodeObject:self.hwModel forKey:@"hwModel"];
    [coder encodeObject:self.serialNumber forKey:@"serialNumber"];
    [coder encodeObject:self.uniqueDeviceID forKey:@"uniqueDeviceID"];
    [coder encodeObject:self.wifiAddress forKey:@"wifiAddress"];
    [coder encodeObject:self.bluetoothAddress forKey:@"bluetoothAddress"];
    [coder encodeObject:self.ethernetAddress forKey:@"ethernetAddress"];
    [coder encodeObject:self.boardID forKey:@"boardID"];
    [coder encodeObject:self.chipID forKey:@"chipID"];
    [coder encodeObject:self.IMEI forKey:@"IMEI"];
    [coder encodeObject:self.ICCID forKey:@"ICCID"];
    [coder encodeObject:self.basebandSerial forKey:@"basebandSerial"];
    [coder encodeDouble:self.screenWidth forKey:@"screenWidth"];
    [coder encodeDouble:self.screenHeight forKey:@"screenHeight"];
    [coder encodeDouble:self.screenScale forKey:@"screenScale"];
    [coder encodeDouble:self.screenBrightness forKey:@"screenBrightness"];
    [coder encodeDouble:self.bootTimeEpoch forKey:@"bootTimeEpoch"];
    [coder encodeInt64:self.fakeMemorySize forKey:@"fakeMemorySize"];
    [coder encodeFloat:self.batteryLevel forKey:@"batteryLevel"];
    [coder encodeInteger:self.batteryState forKey:@"batteryState"];
    [coder encodeObject:self.additionalKeys forKey:@"additionalKeys"];
    [coder encodeObject:self.seed forKey:@"seed"];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.identifierForVendor = [coder decodeObjectOfClass:[NSString class] forKey:@"IDFV"];
        self.advertisingIdentifier = [coder decodeObjectOfClass:[NSString class] forKey:@"IDFA"];
        self.deviceName = [coder decodeObjectOfClass:[NSString class] forKey:@"deviceName"];
        self.deviceModel = [coder decodeObjectOfClass:[NSString class] forKey:@"deviceModel"];
        self.systemVersion = [coder decodeObjectOfClass:[NSString class] forKey:@"systemVersion"];
        self.productType = [coder decodeObjectOfClass:[NSString class] forKey:@"productType"];
        self.hwModel = [coder decodeObjectOfClass:[NSString class] forKey:@"hwModel"];
        self.serialNumber = [coder decodeObjectOfClass:[NSString class] forKey:@"serialNumber"];
        self.uniqueDeviceID = [coder decodeObjectOfClass:[NSString class] forKey:@"uniqueDeviceID"];
        self.wifiAddress = [coder decodeObjectOfClass:[NSString class] forKey:@"wifiAddress"];
        self.bluetoothAddress = [coder decodeObjectOfClass:[NSString class] forKey:@"bluetoothAddress"];
        self.ethernetAddress = [coder decodeObjectOfClass:[NSString class] forKey:@"ethernetAddress"];
        self.boardID = [coder decodeObjectOfClass:[NSString class] forKey:@"boardID"];
        self.chipID = [coder decodeObjectOfClass:[NSString class] forKey:@"chipID"];
        self.IMEI = [coder decodeObjectOfClass:[NSString class] forKey:@"IMEI"];
        self.ICCID = [coder decodeObjectOfClass:[NSString class] forKey:@"ICCID"];
        self.basebandSerial = [coder decodeObjectOfClass:[NSString class] forKey:@"basebandSerial"];
        self.screenWidth = [coder decodeDoubleForKey:@"screenWidth"];
        self.screenHeight = [coder decodeDoubleForKey:@"screenHeight"];
        self.screenScale = [coder decodeDoubleForKey:@"screenScale"];
        self.screenBrightness = [coder decodeDoubleForKey:@"screenBrightness"];
        self.bootTimeEpoch = [coder decodeDoubleForKey:@"bootTimeEpoch"];
        self.fakeMemorySize = [coder decodeInt64ForKey:@"fakeMemorySize"];
        self.batteryLevel = [coder decodeFloatForKey:@"batteryLevel"];
        self.batteryState = [coder decodeIntegerForKey:@"batteryState"];
        self.additionalKeys = [coder decodeObjectOfClasses:[NSSet setWithObjects:[NSMutableDictionary class], [NSString class], [NSData class], [NSNumber class], nil] forKey:@"additionalKeys"];
        self.seed = [coder decodeObjectOfClass:[NSString class] forKey:@"seed"];
    }
    return self;
}

+ (instancetype)identityWithSeed:(NSString *)seed {
    CHDeviceIdentity *identity = [[CHDeviceIdentity alloc] init];
    identity.seed = seed;
    identity.additionalKeys = [NSMutableDictionary dictionary];

    NSData *seedData = [seed dataUsingEncoding:NSUTF8StringEncoding];

    identity.identifierForVendor = [CHDeviceIdentity uuidFromSeed:seedData subkey:"IDFV"];
    identity.advertisingIdentifier = [CHDeviceIdentity uuidFromSeed:seedData subkey:"IDFA"];
    identity.deviceName = [CHDeviceIdentity randomNameFromSeed:seedData];
    identity.serialNumber = [CHDeviceIdentity randomSerialFromSeed:seedData];
    identity.uniqueDeviceID = [CHDeviceIdentity randomUDIDFromSeed:seedData];
    identity.wifiAddress = [CHDeviceIdentity randomMACFromSeed:seedData withPrefix:0x00];
    identity.bluetoothAddress = [CHDeviceIdentity randomMACFromSeed:seedData withPrefix:0x01];
    identity.ethernetAddress = [CHDeviceIdentity randomMACFromSeed:seedData withPrefix:0x02];
    identity.boardID = [CHDeviceIdentity randomHexStringFromSeed:seedData length:8 subkey:"BRD"];
    identity.chipID = [CHDeviceIdentity randomHexStringFromSeed:seedData length:8 subkey:"CHP"];
    identity.IMEI = [CHDeviceIdentity randomIMEIFromSeed:seedData];
    identity.ICCID = [CHDeviceIdentity randomICCIDFromSeed:seedData];
    identity.basebandSerial = [CHDeviceIdentity randomSerialFromSeed:seedData];

    NSArray *models = @[
        @"iPhone14,2", @"iPhone14,3", @"iPhone14,4", @"iPhone14,5",
        @"iPhone15,2", @"iPhone15,3", @"iPhone15,4", @"iPhone15,5",
        @"iPhone16,1", @"iPhone16,2"
    ];
    NSArray *hwModels = @[
        @"D73AP", @"D74AP", @"D75AP", @"D76AP",
        @"D83AP", @"D84AP", @"D85AP", @"D86AP",
        @"D37AP", @"D38AP"
    ];
    NSArray *deviceNames = @[
        @"iPhone", @"iPhone", @"my iPhone", @"phone",
        @"iPhone Pro", @"iPhone Max", @"device"
    ];

    CC_SHA256_CTX modelCtx;
    unsigned char modelHash[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256_Init(&modelCtx);
    CC_SHA256_Update(&modelCtx, [seedData bytes], (CC_LONG)[seedData length]);
    CC_SHA256_Update(&modelCtx, "model", 5);
    CC_SHA256_Final(modelHash, &modelCtx);

    NSUInteger modelIdx = *(NSUInteger *)modelHash % models.count;
    identity.productType = models[modelIdx];
    identity.hwModel = hwModels[modelIdx];

    CC_SHA256_CTX verCtx;
    unsigned char versionHash[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256_Init(&verCtx);
    CC_SHA256_Update(&verCtx, [seedData bytes], (CC_LONG)[seedData length]);
    CC_SHA256_Update(&verCtx, "vers", 4);
    CC_SHA256_Final(versionHash, &verCtx);

    int minor = *(int *)versionHash % 10 + 1;
    int patch = *(int *)(versionHash + 4) % 10;
    identity.systemVersion = [NSString stringWithFormat:@"%d.%d.%d", 16, minor, patch];

    CC_SHA256_CTX nameCtx;
    unsigned char nameHash[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256_Init(&nameCtx);
    CC_SHA256_Update(&nameCtx, [seedData bytes], (CC_LONG)[seedData length]);
    CC_SHA256_Update(&nameCtx, "name", 4);
    CC_SHA256_Final(nameHash, &nameCtx);

    NSUInteger nameIdx = *(NSUInteger *)nameHash % deviceNames.count;
    int nameSuffix = *(int *)(nameHash + 4) % 9999;
    identity.deviceName = [NSString stringWithFormat:@"%@ %d", deviceNames[nameIdx], nameSuffix];

    identity.screenWidth = 390.0;
    identity.screenHeight = 844.0;
    identity.screenScale = 3.0;

    CC_SHA256_CTX brightCtx;
    unsigned char brightnessHash[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256_Init(&brightCtx);
    CC_SHA256_Update(&brightCtx, [seedData bytes], (CC_LONG)[seedData length]);
    CC_SHA256_Update(&brightCtx, "bright", 6);
    CC_SHA256_Final(brightnessHash, &brightCtx);
    identity.screenBrightness = (*(float *)brightnessHash * 0.1f + 0.3f);

    identity.bootTimeEpoch = [[NSDate date] timeIntervalSince1970] - (86400 * (*(int *)versionHash % 30 + 1));

    identity.fakeMemorySize = (uint64_t)(6LL * 1024 * 1024 * 1024 + *(int64_t *)versionHash % (1024LL * 1024 * 1024));

    CC_SHA256_CTX battCtx;
    unsigned char batteryHash[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256_Init(&battCtx);
    CC_SHA256_Update(&battCtx, [seedData bytes], (CC_LONG)[seedData length]);
    CC_SHA256_Update(&battCtx, "batt", 4);
    CC_SHA256_Final(batteryHash, &battCtx);
    identity.batteryLevel = (*(float *)batteryHash * 0.0001f);
    if (identity.batteryLevel < 0) identity.batteryLevel = -identity.batteryLevel;
    identity.batteryLevel = fmodf(identity.batteryLevel, 0.95f) + 0.05f;
    identity.batteryState = *(int *)batteryHash % 4;

    identity.deviceModel = CHDeviceiPhoneModelForProductType(identity.productType);

    double screenDim[2] = {identity.screenWidth, identity.screenHeight};
    identity.additionalKeys[@"screenDimensions"] = [NSData dataWithBytes:screenDim length:16];

    return identity;
}

+ (NSString *)uuidFromSeed:(NSData *)seed subkey:(const char *)subkey {
    unsigned char hash[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256_CTX ctx;
    CC_SHA256_Init(&ctx);
    CC_SHA256_Update(&ctx, [seed bytes], (CC_LONG)[seed length]);
    CC_SHA256_Update(&ctx, subkey, (CC_LONG)strlen(subkey));
    CC_SHA256_Final(hash, &ctx);

    return [NSString stringWithFormat:@"%02X%02X%02X%02X-%02X%02X-%02X%02X-%02X%02X-%02X%02X%02X%02X%02X%02X",
            hash[0], hash[1], hash[2], hash[3],
            hash[4], hash[5],
            hash[6], hash[7],
            hash[8], hash[9],
            hash[10], hash[11], hash[12], hash[13], hash[14], hash[15]];
}

+ (NSString *)randomNameFromSeed:(NSData *)seed {
    NSArray *adjectives = @[@"Local", @"Mine", @"My", @"Home", @"Main", @"Office", @"Travel", @"Work"];
    unsigned char hash[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256_CTX ctx;
    CC_SHA256_Init(&ctx);
    CC_SHA256_Update(&ctx, [seed bytes], (CC_LONG)[seed length]);
    CC_SHA256_Update(&ctx, "name", 4);
    CC_SHA256_Final(hash, &ctx);
    NSUInteger idx = *(NSUInteger *)hash % adjectives.count;
    int num = *(int *)(hash + 4) % 10000;
    return [NSString stringWithFormat:@"%@'s iPhone %d", adjectives[idx], num];
}

+ (NSString *)randomSerialFromSeed:(NSData *)seed {
    unsigned char hash[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256_CTX ctx;
    CC_SHA256_Init(&ctx);
    CC_SHA256_Update(&ctx, [seed bytes], (CC_LONG)[seed length]);
    CC_SHA256_Update(&ctx, "serial", 6);
    CC_SHA256_Final(hash, &ctx);
    const char *chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    char serial[13];
    for (int i = 0; i < 12; i++) {
        serial[i] = chars[hash[i] % 36];
    }
    serial[12] = '\0';
    return [NSString stringWithUTF8String:serial];
}

+ (NSString *)randomUDIDFromSeed:(NSData *)seed {
    unsigned char hash[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256_CTX ctx;
    CC_SHA256_Init(&ctx);
    CC_SHA256_Update(&ctx, [seed bytes], (CC_LONG)[seed length]);
    CC_SHA256_Update(&ctx, "udid", 4);
    CC_SHA256_Final(hash, &ctx);
    NSMutableString *udid = [NSMutableString string];
    for (int i = 0; i < 20; i++) {
        [udid appendFormat:@"%02X", hash[i]];
    }
    return [udid copy];
}

+ (NSString *)randomMACFromSeed:(NSData *)seed withPrefix:(int)prefix {
    unsigned char hash[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256_CTX ctx;
    CC_SHA256_Init(&ctx);
    CC_SHA256_Update(&ctx, [seed bytes], (CC_LONG)[seed length]);
    CC_SHA256_Update(&ctx, &prefix, sizeof(prefix));
    CC_SHA256_Final(hash, &ctx);
    return [NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X",
            prefix, (hash[0] & 0xFE) | 0x02, hash[1], hash[2], hash[3], hash[4]];
}

+ (NSString *)randomHexStringFromSeed:(NSData *)seed length:(int)length subkey:(const char *)subkey {
    unsigned char hash[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256_CTX ctx;
    CC_SHA256_Init(&ctx);
    CC_SHA256_Update(&ctx, [seed bytes], (CC_LONG)[seed length]);
    CC_SHA256_Update(&ctx, subkey, (CC_LONG)strlen(subkey));
    CC_SHA256_Final(hash, &ctx);
    NSMutableString *str = [NSMutableString string];
    for (int i = 0; i < length && i < 32; i++) {
        [str appendFormat:@"%02X", hash[i]];
    }
    return [str copy];
}

+ (NSString *)randomIMEIFromSeed:(NSData *)seed {
    unsigned char hash[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256_CTX ctx;
    CC_SHA256_Init(&ctx);
    CC_SHA256_Update(&ctx, [seed bytes], (CC_LONG)[seed length]);
    CC_SHA256_Update(&ctx, "imei", 4);
    CC_SHA256_Final(hash, &ctx);
    NSMutableString *imei = [NSMutableString string];
    for (int i = 0; i < 15; i++) {
        [imei appendFormat:@"%d", hash[i] % 10];
    }
    return [imei copy];
}

+ (NSString *)randomICCIDFromSeed:(NSData *)seed {
    unsigned char hash[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256_CTX ctx;
    CC_SHA256_Init(&ctx);
    CC_SHA256_Update(&ctx, [seed bytes], (CC_LONG)[seed length]);
    CC_SHA256_Update(&ctx, "iccid", 5);
    CC_SHA256_Final(hash, &ctx);
    NSMutableString *iccid = [NSMutableString stringWithString:@"8901"];
    for (int i = 0; i < 16; i++) {
        [iccid appendFormat:@"%d", hash[i] % 10];
    }
    return [iccid copy];
}

static NSString *CHDeviceiPhoneModelForProductType(NSString *productType) {
    NSDictionary *map = @{
        @"iPhone14,2": @"iPhone 13 Pro",
        @"iPhone14,3": @"iPhone 13 Pro Max",
        @"iPhone14,4": @"iPhone 13 mini",
        @"iPhone14,5": @"iPhone 13",
        @"iPhone15,2": @"iPhone 14 Pro",
        @"iPhone15,3": @"iPhone 14 Pro Max",
        @"iPhone15,4": @"iPhone 14",
        @"iPhone15,5": @"iPhone 14 Plus",
        @"iPhone16,1": @"iPhone 15 Pro",
        @"iPhone16,2": @"iPhone 15 Pro Max",
    };
    return map[productType] ?: @"iPhone";
}

@end

@implementation CHIdentityEngine

+ (BOOL)isHookEnabled:(NSString *)hookKey {
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.chameleon.prefs"];
    if (![defaults boolForKey:@"Enabled"]) return NO;
    if (!hookKey) return YES;
    return [defaults boolForKey:hookKey];
}

+ (instancetype)sharedEngine {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedEngine = [[CHIdentityEngine alloc] initPrivate];
    });
    return sharedEngine;
}

- (instancetype)initPrivate {
    self = [super init];
    if (self) {
        _identities = [NSMutableDictionary dictionary];
        _containerSeeds = [NSMutableDictionary dictionary];
        _identitiesPath = @"/var/mobile/Library/Preferences/com.chameleon.identities.plist";
        [self loadIdentities];
    }
    return self;
}

- (instancetype)init {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (CHDeviceIdentity *)identityForBundleID:(NSString *)bundleID {
    return [self identityForBundleID:bundleID containerSeed:nil];
}

- (CHDeviceIdentity *)identityForBundleID:(NSString *)bundleID containerSeed:(NSString *)containerSeed {
    if (!bundleID) return nil;

    if (!containerSeed) {
        containerSeed = self.containerSeeds[bundleID];
        if (!containerSeed) {
            containerSeed = [CHIdentityEngine generateSeed];
            self.containerSeeds[bundleID] = containerSeed;
        }
    }

    NSString *identityKey = [NSString stringWithFormat:@"%@|%@", bundleID, containerSeed];
    CHDeviceIdentity *identity = self.identities[identityKey];

    if (!identity) {
        identity = [CHDeviceIdentity identityWithSeed:identityKey];
        self.identities[identityKey] = identity;
        [self saveIdentities];
    }

    return identity;
}

- (CHDeviceIdentity *)currentIdentity {
    NSString *bundleID = [self currentBundleID];
    if (!bundleID) return nil;
    return [self identityForBundleID:bundleID];
}

- (NSString *)currentBundleID {
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *bundleID = [mainBundle bundleIdentifier];
    if (bundleID) return bundleID;

    NSDictionary *infoDict = [mainBundle infoDictionary];
    return infoDict[@"CFBundleIdentifier"];
}

- (void)resetIdentityForBundleID:(NSString *)bundleID {
    NSString *containerSeed = self.containerSeeds[bundleID];
    if (containerSeed) {
        NSString *identityKey = [NSString stringWithFormat:@"%@|%@", bundleID, containerSeed];
        [self.identities removeObjectForKey:identityKey];
        [self.containerSeeds removeObjectForKey:bundleID];
        [self saveIdentities];
    }
}

+ (NSString *)generateSeed {
    NSUUID *uuid = [NSUUID UUID];
    return [uuid UUIDString];
}

- (void)saveIdentities {
    NSError *error = nil;
    NSMutableDictionary *saveDict = [NSMutableDictionary dictionary];
    saveDict[@"identities"] = self.identities;
    saveDict[@"containerSeeds"] = self.containerSeeds;

    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:saveDict requiringSecureCoding:NO error:&error];
    if (data && !error) {
        [data writeToFile:self.identitiesPath atomically:YES];
    }
}

- (void)loadIdentities {
    NSData *data = [NSData dataWithContentsOfFile:self.identitiesPath];
    if (!data) return;

    NSError *error = nil;
    NSSet *classes = [NSSet setWithObjects:
                      [NSMutableDictionary class],
                      [NSDictionary class],
                      [CHDeviceIdentity class],
                      [NSString class],
                      nil];
    NSDictionary *loaded = [NSKeyedUnarchiver unarchivedObjectOfClasses:classes fromData:data error:&error];

    if (loaded && !error) {
        NSDictionary *identitiesDict = loaded[@"identities"];
        if (identitiesDict) {
            [self.identities addEntriesFromDictionary:identitiesDict];
        }
        NSDictionary *seedsDict = loaded[@"containerSeeds"];
        if (seedsDict) {
            [self.containerSeeds addEntriesFromDictionary:seedsDict];
        }
    }
}

@end

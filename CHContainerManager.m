#import "CHContainerManager.h"

NSString *const CHContainerDidSwitchNotification = @"CHContainerDidSwitchNotification";
static CHContainerManager *sharedManager = nil;

@implementation CHContainerManager

+ (instancetype)sharedManager {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedManager = [[self alloc] initPrivate];
    });
    return sharedManager;
}

- (instancetype)initPrivate {
    self = [super init];
    if (self) {
        NSString *base = [NSString stringWithFormat:@"%@/Library/Chameleon", NSHomeDirectory()];
        _containersPath = [base stringByAppendingPathComponent:@"Containers"];
        _statePath = [base stringByAppendingPathComponent:@"state.plist"];
        [[NSFileManager defaultManager] createDirectoryAtPath:_containersPath
                                  withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return self;
}

- (instancetype)init { [self doesNotRecognizeSelector:_cmd]; return nil; }

- (NSDictionary *)state {
    return [NSDictionary dictionaryWithContentsOfFile:self.statePath] ?: @{};
}

- (void)saveState:(NSDictionary *)state {
    [state writeToFile:self.statePath atomically:YES];
}

- (NSArray<NSString *> *)containerUUIDsForBundleID:(NSString *)bundleID {
    NSString *dir = [self.containersPath stringByAppendingPathComponent:bundleID];
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dir error:nil];
    if (!contents) return @[@"default"];
    NSMutableArray *uuids = [NSMutableArray array];
    for (NSString *item in contents) {
        if (![item hasPrefix:@"."]) [uuids addObject:item];
    }
    if (uuids.count == 0) [uuids addObject:@"default"];
    return uuids;
}

- (NSDictionary *)containerInfoForBundleID:(NSString *)bundleID uuid:(NSString *)uuid {
    NSString *path = [self.containersPath stringByAppendingPathComponent:
                      [NSString stringWithFormat:@"%@/%@/info.plist", bundleID, uuid]];
    return [NSDictionary dictionaryWithContentsOfFile:path] ?: @{@"name": uuid, @"uuid": uuid};
}

- (NSString *)activeContainerForBundleID:(NSString *)bundleID {
    NSDictionary *state = [self state];
    return state[bundleID] ?: @"default";
}

- (BOOL)hasMultipleContainersForBundleID:(NSString *)bundleID {
    return [self containerUUIDsForBundleID:bundleID].count > 1;
}

- (BOOL)setActiveContainer:(NSString *)uuid forBundleID:(NSString *)bundleID {
    NSMutableDictionary *state = [[self state] mutableCopy];
    state[bundleID] = uuid;
    [self saveState:state];
    [[NSNotificationCenter defaultCenter] postNotificationName:CHContainerDidSwitchNotification
                                                        object:self userInfo:@{@"bundleID": bundleID, @"uuid": uuid}];
    return YES;
}

- (NSString *)createContainerForBundleID:(NSString *)bundleID name:(NSString *)name {
    NSString *uuid = [[NSUUID UUID] UUIDString];
    NSString *dir = [self.containersPath stringByAppendingPathComponent:
                     [NSString stringWithFormat:@"%@/%@", bundleID, uuid]];
    [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES
                                              attributes:nil error:nil];
    NSDictionary *info = @{@"name": name ?: uuid, @"uuid": uuid, @"created": [NSDate date]};
    [info writeToFile:[dir stringByAppendingPathComponent:@"info.plist"] atomically:YES];

    NSString *defaultDir = [self.containersPath stringByAppendingPathComponent:
                            [NSString stringWithFormat:@"%@/default", bundleID]];
    if (![[NSFileManager defaultManager] fileExistsAtPath:defaultDir]) {
        [[NSFileManager defaultManager] copyItemAtPath:dir toPath:defaultDir error:nil];
        NSMutableDictionary *defaultInfo = [@{@"name": @"Default", @"uuid": @"default"} mutableCopy];
        [defaultInfo writeToFile:[defaultDir stringByAppendingPathComponent:@"info.plist"] atomically:YES];
    }

    return uuid;
}

- (BOOL)deleteContainerForBundleID:(NSString *)bundleID uuid:(NSString *)uuid {
    if ([uuid isEqualToString:@"default"]) return NO;
    NSString *dir = [self.containersPath stringByAppendingPathComponent:
                     [NSString stringWithFormat:@"%@/%@", bundleID, uuid]];
    return [[NSFileManager defaultManager] removeItemAtPath:dir error:nil];
}

- (BOOL)renameContainerForBundleID:(NSString *)bundleID uuid:(NSString *)uuid name:(NSString *)name {
    NSString *path = [self.containersPath stringByAppendingPathComponent:
                      [NSString stringWithFormat:@"%@/%@/info.plist", bundleID, uuid]];
    NSMutableDictionary *info = [[self containerInfoForBundleID:bundleID uuid:uuid] mutableCopy];
    info[@"name"] = name;
    return [info writeToFile:path atomically:YES];
}

- (NSString *)containerDataPathForBundleID:(NSString *)bundleID uuid:(NSString *)uuid {
    return [self.containersPath stringByAppendingPathComponent:
            [NSString stringWithFormat:@"%@/%@/data", bundleID, uuid]];
}

- (NSUserDefaults *)containerDefaultsForBundleID:(NSString *)bundleID uuid:(NSString *)uuid {
    NSString *suite = [NSString stringWithFormat:@"chameleon.%@.%@", bundleID, uuid];
    return [[NSUserDefaults alloc] initWithSuiteName:suite];
}

@end

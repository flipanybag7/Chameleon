#import <Foundation/Foundation.h>

extern NSString *const CHContainerDidSwitchNotification;

@interface CHContainerManager : NSObject

@property (nonatomic, readonly, copy) NSString *containersPath;
@property (nonatomic, readonly, copy) NSString *statePath;

+ (instancetype)sharedManager;

- (NSArray<NSString *> *)containerUUIDsForBundleID:(NSString *)bundleID;
- (NSDictionary *)containerInfoForBundleID:(NSString *)bundleID uuid:(NSString *)uuid;
- (NSString *)activeContainerForBundleID:(NSString *)bundleID;
- (BOOL)hasMultipleContainersForBundleID:(NSString *)bundleID;
- (BOOL)setActiveContainer:(NSString *)uuid forBundleID:(NSString *)bundleID;
- (NSString *)createContainerForBundleID:(NSString *)bundleID name:(NSString *)name;
- (BOOL)deleteContainerForBundleID:(NSString *)bundleID uuid:(NSString *)uuid;
- (BOOL)renameContainerForBundleID:(NSString *)bundleID uuid:(NSString *)uuid name:(NSString *)name;

- (NSString *)containerDataPathForBundleID:(NSString *)bundleID uuid:(NSString *)uuid;
- (NSUserDefaults *)containerDefaultsForBundleID:(NSString *)bundleID uuid:(NSString *)uuid;

@end

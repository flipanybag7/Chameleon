#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface CHDeviceIdentity : NSObject <NSSecureCoding>

@property (nonatomic, copy) NSString *identifierForVendor;
@property (nonatomic, copy) NSString *advertisingIdentifier;
@property (nonatomic, copy) NSString *deviceName;
@property (nonatomic, copy) NSString *deviceModel;
@property (nonatomic, copy) NSString *systemVersion;
@property (nonatomic, copy) NSString *productType;
@property (nonatomic, copy) NSString *hwModel;
@property (nonatomic, copy) NSString *serialNumber;
@property (nonatomic, copy) NSString *uniqueDeviceID;
@property (nonatomic, copy) NSString *wifiAddress;
@property (nonatomic, copy) NSString *bluetoothAddress;
@property (nonatomic, copy) NSString *ethernetAddress;
@property (nonatomic, copy) NSString *boardID;
@property (nonatomic, copy) NSString *chipID;
@property (nonatomic, copy) NSString *IMEI;
@property (nonatomic, copy) NSString *ICCID;
@property (nonatomic, copy) NSString *basebandSerial;

@property (nonatomic, assign) CGFloat screenWidth;
@property (nonatomic, assign) CGFloat screenHeight;
@property (nonatomic, assign) CGFloat screenScale;
@property (nonatomic, assign) double screenBrightness;
@property (nonatomic, assign) double bootTimeEpoch;
@property (nonatomic, assign) uint64_t fakeMemorySize;
@property (nonatomic, assign) float batteryLevel;
@property (nonatomic, assign) NSInteger batteryState;

@property (nonatomic, strong) NSMutableDictionary *additionalKeys;
@property (nonatomic, copy) NSString *seed;

+ (instancetype)identityWithSeed:(NSString *)seed;

@end

@interface CHIdentityEngine : NSObject

@property (nonatomic, strong) NSMutableDictionary<NSString *, CHDeviceIdentity *> *identities;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *containerSeeds;
@property (nonatomic, copy) NSString *identitiesPath;

+ (instancetype)sharedEngine;
- (CHDeviceIdentity *)identityForBundleID:(NSString *)bundleID;
- (CHDeviceIdentity *)identityForBundleID:(NSString *)bundleID containerSeed:(NSString *)containerSeed;
- (CHDeviceIdentity *)currentIdentity;
- (void)resetIdentityForBundleID:(NSString *)bundleID;
- (void)saveIdentities;
- (void)loadIdentities;

@end

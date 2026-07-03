#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import "CHContainerManager.h"
#import "CHIdentityEngine.h"

@interface CHProfileListController : PSListController
@property (nonatomic, copy) NSString *bundleID;
@end

@implementation CHProfileListController

- (NSArray *)specifiers {
    if (!_specifiers) {
        NSString *bundleID = [self propertyForKey:@"bundleID"];

        NSMutableArray *specs = [NSMutableArray array];
        [specs addObject:[PSSpecifier groupSpecifierWithName:
                          [NSString stringWithFormat:@"Profiles for %@", bundleID]]];

        CHContainerManager *cm = [CHContainerManager sharedManager];
        NSArray *uuids = [cm containerUUIDsForBundleID:bundleID];

        for (NSString *uuid in uuids) {
            NSDictionary *info = [cm containerInfoForBundleID:bundleID uuid:uuid];
            NSString *name = info[@"name"] ?: uuid;
            NSString *active = [cm activeContainerForBundleID:bundleID];
            BOOL isActive = [uuid isEqualToString:active];

            PSSpecifier *spec = [PSSpecifier preferenceSpecifierNamed:
                isActive ? [NSString stringWithFormat:@"%@ (Active)", name] : name
                target:self set:NULL get:NULL detail:nil cell:PSLinkCell edit:nil];
            [spec setProperty:bundleID forKey:@"bundleID"];
            [spec setProperty:uuid forKey:@"uuid"];
            [spec setProperty:isActive ? @"switch" : @"select" forKey:@"action"];

            if (!isActive) {
                [spec setProperty:@selector(activateProfile:) forKey:@"lazyAltAction"];
            }
            [specs addObject:spec];

            CHDeviceIdentity *ident = [[CHIdentityEngine sharedEngine] identityForBundleID:bundleID
                                                                              containerUUID:uuid];
            if (ident) {
                [specs addObject:[self staticSpec:@"IDFV" value:ident.identifierForVendor]];
                [specs addObject:[self staticSpec:@"IDFA" value:ident.advertisingIdentifier]];
            }
        }

        [specs addObject:[PSSpecifier groupSpecifierWithName:@"Actions"]];
        [specs addObject:[self buttonSpec:@"Create New Profile" action:@selector(createProfile)]];

        _specifiers = specs;
    }
    return _specifiers;
}

- (PSSpecifier *)staticSpec:(NSString *)label value:(NSString *)value {
    PSSpecifier *spec = [PSSpecifier preferenceSpecifierNamed:label target:self set:NULL get:NULL
                                                       detail:nil cell:PSStaticTextCell edit:nil];
    [spec setProperty:value forKey:@"value"];
    return spec;
}

- (PSSpecifier *)buttonSpec:(NSString *)label action:(SEL)action {
    return [PSSpecifier preferenceSpecifierNamed:label target:self set:NULL get:NULL
                                          detail:nil cell:PSButtonCell edit:nil];
}

- (void)activateProfile:(PSSpecifier *)spec {
    NSString *bundleID = [spec propertyForKey:@"bundleID"];
    NSString *uuid = [spec propertyForKey:@"uuid"];
    if (bundleID && uuid) {
        [[CHContainerManager sharedManager] setActiveContainer:uuid forBundleID:bundleID];
        _specifiers = nil;
        [self reloadSpecifiers];
    }
}

- (void)createProfile {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"New Profile"
        message:@"Enter a name for this profile" preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) {
        tf.placeholder = @"Profile name";
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Create" style:UIAlertActionStyleDefault
        handler:^(UIAlertAction *action) {
        NSString *name = alert.textFields.firstObject.text ?: @"New Profile";
        NSString *bundleID = [self propertyForKey:@"bundleID"];
        if (bundleID) {
            [[CHContainerManager sharedManager] createContainerForBundleID:bundleID name:name];
            _specifiers = nil;
            [self reloadSpecifiers];
        }
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (id)readPreferenceValue:(PSSpecifier *)spec { return nil; }
- (void)setPreferenceValue:(id)v specifier:(PSSpecifier *)s {}

@end

#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import "CHContainerManager.h"
#import "CHIdentityEngine.h"

@interface CHProfileDetailsController : PSListController
@end

@implementation CHProfileDetailsController

- (NSArray *)specifiers {
    if (!_specifiers) {
        NSString *bundleID = [[self specifier] propertyForKey:@"bundleID"];
        NSString *uuid = [[self specifier] propertyForKey:@"uuid"];
        NSString *profileName = [[self specifier] propertyForKey:@"profileName"];
        BOOL isActive = [[[self specifier] propertyForKey:@"isActive"] boolValue];

        CHDeviceIdentity *ident = [[CHIdentityEngine sharedEngine] identityForBundleID:bundleID containerUUID:uuid];

        NSMutableArray *specs = [NSMutableArray array];

        [specs addObject:[PSSpecifier groupSpecifierWithName:profileName]];

        if (!isActive) {
            PSSpecifier *setActiveSpec = [PSSpecifier preferenceSpecifierNamed:@"Set as Active"
                target:self set:NULL get:NULL detail:nil cell:PSButtonCell edit:nil];
            [setActiveSpec setTarget:self];
            [setActiveSpec setButtonAction:@selector(setActive)];
            [setActiveSpec setProperty:bundleID forKey:@"bundleID"];
            [setActiveSpec setProperty:uuid forKey:@"uuid"];
            [specs addObject:setActiveSpec];
        }

        [specs addObject:[PSSpecifier groupSpecifierWithName:@"Spoofed Identifiers"]];

        NSArray *items = @[
            @{@"key": @"identifierForVendor", @"label": @"Identifier for Vendor (IDFV)"},
            @{@"key": @"advertisingIdentifier", @"label": @"Advertising ID (IDFA)"},
            @{@"key": @"deviceName", @"label": @"Device Name"},
            @{@"key": @"deviceModel", @"label": @"Device Model"},
            @{@"key": @"systemVersion", @"label": @"System Version"},
            @{@"key": @"productType", @"label": @"Product Type"},
            @{@"key": @"serialNumber", @"label": @"Serial Number"},
            @{@"key": @"uniqueDeviceID", @"label": @"UDID"},
            @{@"key": @"wifiAddress", @"label": @"WiFi MAC"},
            @{@"key": @"bluetoothAddress", @"label": @"Bluetooth MAC"},
            @{@"key": @"boardID", @"label": @"Board ID"},
            @{@"key": @"chipID", @"label": @"Chip ID"},
            @{@"key": @"IMEI", @"label": @"IMEI"},
            @{@"key": @"ICCID", @"label": @"ICCID"},
            @{@"key": @"basebandSerial", @"label": @"Baseband Serial"},
        ];

        for (NSDictionary *item in items) {
            NSString *value = [ident valueForKey:item[@"key"]] ?: @"—";
            PSSpecifier *spec = [PSSpecifier preferenceSpecifierNamed:item[@"label"]
                target:self set:NULL get:NULL detail:nil cell:PSStaticTextCell edit:nil];
            [spec setProperty:value forKey:@"value"];
            [specs addObject:spec];
        }

        [specs addObject:[PSSpecifier groupSpecifierWithName:@"Actions"]];
        PSSpecifier *renameSpec = [PSSpecifier preferenceSpecifierNamed:@"Rename Profile"
            target:self set:NULL get:NULL detail:nil cell:PSButtonCell edit:nil];
        [renameSpec setTarget:self];
        [renameSpec setButtonAction:@selector(renameProfile)];
        [renameSpec setProperty:bundleID forKey:@"bundleID"];
        [renameSpec setProperty:uuid forKey:@"uuid"];
        [renameSpec setProperty:profileName forKey:@"profileName"];
        [specs addObject:renameSpec];

        PSSpecifier *resetSpec = [PSSpecifier preferenceSpecifierNamed:@"Reset Identity"
            target:self set:NULL get:NULL detail:nil cell:PSButtonCell edit:nil];
        [resetSpec setTarget:self];
        [resetSpec setButtonAction:@selector(resetIdentity)];
        [resetSpec setProperty:bundleID forKey:@"bundleID"];
        [resetSpec setProperty:uuid forKey:@"uuid"];
        [specs addObject:resetSpec];

        if (![uuid isEqualToString:@"default"]) {
            PSSpecifier *deleteSpec = [PSSpecifier preferenceSpecifierNamed:@"Delete Profile"
                target:self set:NULL get:NULL detail:nil cell:PSButtonCell edit:nil];
            [deleteSpec setTarget:self];
            [deleteSpec setButtonAction:@selector(deleteProfile)];
            [deleteSpec setProperty:bundleID forKey:@"bundleID"];
            [deleteSpec setProperty:uuid forKey:@"uuid"];
            [deleteSpec setProperty:@YES forKey:@"destructive"];
            [specs addObject:deleteSpec];
        }

        _specifiers = specs;
    }
    return _specifiers;
}

- (void)setActive {
    NSString *bundleID = [[self specifier] propertyForKey:@"bundleID"];
    NSString *uuid = [[self specifier] propertyForKey:@"uuid"];
    [[CHContainerManager sharedManager] setActiveContainer:uuid forBundleID:bundleID];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)renameProfile {
    NSString *bundleID = [[self specifier] propertyForKey:@"bundleID"];
    NSString *uuid = [[self specifier] propertyForKey:@"uuid"];
    NSString *currentName = [[self specifier] propertyForKey:@"profileName"];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Rename"
        message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) { tf.text = currentName; }];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Save" style:UIAlertActionStyleDefault
        handler:^(UIAlertAction *a) {
            [[CHContainerManager sharedManager] renameContainerForBundleID:bundleID
                uuid:uuid name:alert.textFields.firstObject.text ?: currentName];
            [self.navigationController popViewControllerAnimated:YES];
        }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)resetIdentity {
    NSString *bundleID = [[self specifier] propertyForKey:@"bundleID"];
    NSString *uuid = [[self specifier] propertyForKey:@"uuid"];
    [[CHIdentityEngine sharedEngine] resetIdentityForBundleID:bundleID containerUUID:uuid];
    _specifiers = nil;
    [self reloadSpecifiers];
}

- (void)deleteProfile {
    NSString *bundleID = [[self specifier] propertyForKey:@"bundleID"];
    NSString *uuid = [[self specifier] propertyForKey:@"uuid"];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Delete Profile?"
        message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive
        handler:^(UIAlertAction *a) {
            [[CHContainerManager sharedManager] deleteContainerForBundleID:bundleID uuid:uuid];
            [self.navigationController popViewControllerAnimated:YES];
        }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (id)readPreferenceValue:(PSSpecifier *)spec { return nil; }
- (void)setPreferenceValue:(id)v specifier:(PSSpecifier *)s {}

@end

#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import "CHContainerManager.h"
#import "CHIdentityEngine.h"

@interface CHProfileDetailsController : PSListController
@property (nonatomic, copy) NSString *bundleID;
@property (nonatomic, copy) NSString *uuid;
@end

@implementation CHProfileDetailsController

- (void)setSpecifier:(PSSpecifier *)spec {
    [super setSpecifier:spec];
    self.bundleID = [spec propertyForKey:@"bundleID"];
    self.uuid = [spec propertyForKey:@"uuid"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self reloadSpecifiers];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    PSSpecifier *spec = _specifiers[indexPath.section][indexPath.row];
    NSString *val = [spec propertyForKey:@"chameleonValue"];
    if (val) {
        cell.detailTextLabel.text = val;
        cell.detailTextLabel.font = [UIFont systemFontOfSize:12];
        cell.detailTextLabel.textColor = [UIColor grayColor];
    }
    return cell;
}

- (NSArray *)specifiers {
    if (!_specifiers) {
        NSString *bundleID = self.bundleID ?: [[self specifier] propertyForKey:@"bundleID"];
        NSString *uuid = self.uuid ?: [[self specifier] propertyForKey:@"uuid"];

        if (!bundleID) bundleID = @"com.unknown";
        if (!uuid) uuid = @"default";

        CHDeviceIdentity *ident = [[CHIdentityEngine sharedEngine] identityForBundleID:bundleID containerUUID:uuid];
        NSString *profileName = [[self specifier] propertyForKey:@"profileName"] ?: uuid;
        BOOL isActive = [[[self specifier] propertyForKey:@"isActive"] boolValue];

        NSMutableArray *specs = [NSMutableArray array];
        [specs addObject:[PSSpecifier groupSpecifierWithName:profileName]];

        if (!isActive) {
            PSSpecifier *activateSpec = [PSSpecifier preferenceSpecifierNamed:@"Set as Active"
                target:self set:NULL get:NULL detail:nil cell:PSButtonCell edit:nil];
            [activateSpec setTarget:self];
            [activateSpec setButtonAction:@selector(setActive)];
            [activateSpec setProperty:bundleID forKey:@"bundleID"];
            [activateSpec setProperty:uuid forKey:@"uuid"];
            [specs addObject:activateSpec];
        }

        [specs addObject:[PSSpecifier groupSpecifierWithName:@"Spoofed Identifiers"]];

        void (^addItem)(NSString *, NSString *) = ^(NSString *label, NSString *valueKey) {
            NSString *val = [ident valueForKey:valueKey] ?: @"—";
            if ([val isKindOfClass:[NSNull class]] || [val length] == 0) val = @"—";
            PSSpecifier *s = [PSSpecifier preferenceSpecifierNamed:label
                target:self set:NULL get:NULL detail:nil cell:PSTitleValueCell edit:nil];
            [s setProperty:val forKey:@"chameleonValue"];
            [specs addObject:s];
        };

        addItem(@"Identifier for Vendor (IDFV)", @"identifierForVendor");
        addItem(@"Advertising ID (IDFA)", @"advertisingIdentifier");
        addItem(@"Device Name", @"deviceName");
        addItem(@"Device Model", @"deviceModel");
        addItem(@"System Version", @"systemVersion");
        addItem(@"Product Type", @"productType");
        addItem(@"Serial Number", @"serialNumber");
        addItem(@"UDID", @"uniqueDeviceID");
        addItem(@"WiFi MAC", @"wifiAddress");
        addItem(@"Bluetooth MAC", @"bluetoothAddress");
        addItem(@"Board ID", @"boardID");
        addItem(@"Chip ID", @"chipID");
        addItem(@"IMEI", @"IMEI");
        addItem(@"ICCID", @"ICCID");
        addItem(@"Baseband Serial", @"basebandSerial");

        [specs addObject:[PSSpecifier groupSpecifierWithName:@"Actions"]];

        PSSpecifier *randomizeSpec = [PSSpecifier preferenceSpecifierNamed:@"Randomize Identity"
            target:self set:NULL get:NULL detail:nil cell:PSButtonCell edit:nil];
        [randomizeSpec setTarget:self];
        [randomizeSpec setButtonAction:@selector(randomize)];
        [specs addObject:randomizeSpec];

        PSSpecifier *renameSpec = [PSSpecifier preferenceSpecifierNamed:@"Rename Profile"
            target:self set:NULL get:NULL detail:nil cell:PSButtonCell edit:nil];
        [renameSpec setTarget:self];
        [renameSpec setButtonAction:@selector(renameProfile)];
        [renameSpec setProperty:bundleID forKey:@"bundleID"];
        [renameSpec setProperty:uuid forKey:@"uuid"];
        [specs addObject:renameSpec];

        if (![uuid isEqualToString:@"default"]) {
            PSSpecifier *deleteSpec = [PSSpecifier preferenceSpecifierNamed:@"Delete Profile"
                target:self set:NULL get:NULL detail:nil cell:PSButtonCell edit:nil];
            [deleteSpec setTarget:self];
            [deleteSpec setButtonAction:@selector(deleteProfile)];
            [deleteSpec setProperty:bundleID forKey:@"bundleID"];
            [deleteSpec setProperty:uuid forKey:@"uuid"];
            [specs addObject:deleteSpec];
        }

        _specifiers = specs;
    }
    return _specifiers;
}

- (void)setActive {
    NSString *bID = [[self specifier] propertyForKey:@"bundleID"] ?: self.bundleID;
    NSString *u = [[self specifier] propertyForKey:@"uuid"] ?: self.uuid;
    [[CHContainerManager sharedManager] setActiveContainer:u forBundleID:bID];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)randomize {
    NSString *bID = [[self specifier] propertyForKey:@"bundleID"] ?: self.bundleID;
    NSString *u = [[self specifier] propertyForKey:@"uuid"] ?: self.uuid;
    [[CHIdentityEngine sharedEngine] resetIdentityForBundleID:bID containerUUID:u];
    _specifiers = nil;
    [self reloadSpecifiers];
}

- (void)renameProfile {
    NSString *bID = [[self specifier] propertyForKey:@"bundleID"] ?: self.bundleID;
    NSString *u = [[self specifier] propertyForKey:@"uuid"] ?: self.uuid;
    NSString *currentName = [[self specifier] propertyForKey:@"profileName"] ?: u;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Rename"
        message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) { tf.text = currentName; }];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Save" style:UIAlertActionStyleDefault
        handler:^(UIAlertAction *a) {
            [[CHContainerManager sharedManager] renameContainerForBundleID:bID
                uuid:u name:alert.textFields.firstObject.text ?: currentName];
            [self.navigationController popViewControllerAnimated:YES];
        }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)deleteProfile {
    NSString *bID = [[self specifier] propertyForKey:@"bundleID"] ?: self.bundleID;
    NSString *u = [[self specifier] propertyForKey:@"uuid"] ?: self.uuid;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Delete Profile?"
        message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive
        handler:^(UIAlertAction *a) {
            [[CHContainerManager sharedManager] deleteContainerForBundleID:bID uuid:u];
            [self.navigationController popViewControllerAnimated:YES];
        }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (id)readPreferenceValue:(PSSpecifier *)spec { return nil; }
- (void)setPreferenceValue:(id)v specifier:(PSSpecifier *)s {}

@end

#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import "CHContainerManager.h"
#import "CHIdentityEngine.h"

@interface CHProfileListController : PSListController
@end

@implementation CHProfileListController

- (NSArray *)specifiers {
    if (!_specifiers) {
        NSString *bundleID = [[self specifier] propertyForKey:@"bundleID"];
        NSMutableArray *specs = [NSMutableArray array];
        [specs addObject:[PSSpecifier groupSpecifierWithName:[NSString stringWithFormat:@"Profiles for %@", bundleID]]];

        CHContainerManager *cm = [CHContainerManager sharedManager];
        NSArray *uuids = [cm containerUUIDsForBundleID:bundleID];

        for (NSString *uuid in uuids) {
            NSDictionary *info = [cm containerInfoForBundleID:bundleID uuid:uuid];
            NSString *name = info[@"name"] ?: uuid;
            NSString *active = [cm activeContainerForBundleID:bundleID];
            BOOL isActive = [uuid isEqualToString:active];

            NSString *label = isActive ? [NSString stringWithFormat:@"%@ (Active)", name] : name;

            PSSpecifier *spec = [PSSpecifier preferenceSpecifierNamed:label
                target:self set:NULL get:NULL
                detail:nil cell:PSLinkCell edit:nil];
            [spec setProperty:bundleID forKey:@"bundleID"];
            [spec setProperty:uuid forKey:@"uuid"];
            [spec setProperty:@(isActive) forKey:@"isActive"];
            [spec setProperty:name forKey:@"profileName"];

            if (!isActive) {
                [spec setTarget:self];
                [spec setButtonAction:@selector(profileTapped:)];
            }
            [specs addObject:spec];
        }

        [specs addObject:[PSSpecifier groupSpecifierWithName:@"Actions"]];
        PSSpecifier *btnSpec = [PSSpecifier preferenceSpecifierNamed:@"Create New Profile"
            target:self set:NULL get:NULL detail:nil cell:PSButtonCell edit:nil];
        [btnSpec setTarget:self];
        [btnSpec setButtonAction:@selector(createProfile)];
        [specs addObject:btnSpec];

        _specifiers = specs;
    }
    return _specifiers;
}

- (void)profileTapped:(PSSpecifier *)spec {
    NSString *bundleID = [spec propertyForKey:@"bundleID"];
    NSString *uuid = [spec propertyForKey:@"uuid"];
    NSString *name = [spec propertyForKey:@"profileName"];
    if (!bundleID || !uuid) return;

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:name
        message:nil preferredStyle:UIAlertControllerStyleActionSheet];

    [alert addAction:[UIAlertAction actionWithTitle:@"Set as Active" style:UIAlertActionStyleDefault
        handler:^(UIAlertAction *a) {
            [[CHContainerManager sharedManager] setActiveContainer:uuid forBundleID:bundleID];
            _specifiers = nil;
            [self reloadSpecifiers];
        }]];

    [alert addAction:[UIAlertAction actionWithTitle:@"Rename" style:UIAlertActionStyleDefault
        handler:^(UIAlertAction *a) {
            [self renameProfile:bundleID uuid:uuid currentName:name];
        }]];

    [alert addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive
        handler:^(UIAlertAction *a) {
            [[CHContainerManager sharedManager] deleteContainerForBundleID:bundleID uuid:uuid];
            _specifiers = nil;
            [self reloadSpecifiers];
        }]];

    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];

    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        alert.popoverPresentationController.sourceView = self.view;
        alert.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds), 0, 0, 0);
    }

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)renameProfile:(NSString *)bundleID uuid:(NSString *)uuid currentName:(NSString *)currentName {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Rename Profile"
        message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) { tf.text = currentName; }];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Save" style:UIAlertActionStyleDefault
        handler:^(UIAlertAction *a) {
            NSString *newName = alert.textFields.firstObject.text ?: currentName;
            [[CHContainerManager sharedManager] renameContainerForBundleID:bundleID uuid:uuid name:newName];
            _specifiers = nil;
            [self reloadSpecifiers];
        }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)createProfile {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"New Profile"
        message:@"Enter a name" preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) { tf.placeholder = @"Profile name"; }];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Create" style:UIAlertActionStyleDefault
        handler:^(UIAlertAction *a) {
            NSString *name = alert.textFields.firstObject.text ?: @"New Profile";
            NSString *bundleID = [[self specifier] propertyForKey:@"bundleID"];
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

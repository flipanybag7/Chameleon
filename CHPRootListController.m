#include <Preferences/PSListController.h>
#include <Preferences/PSSpecifier.h>

@interface CHPRootListController : PSListController
- (void)resetIdentity;
- (void)resetAllIdentities;
@end

@implementation CHPRootListController

- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"specifiers" target:self];
    }
    return _specifiers;
}

- (void)resetIdentity {
    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:@"Reset Identity"
        message:@"This will generate a new identity for the current app. Respring required."
        preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Reset" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        NSString *bundleID = [NSBundle mainBundle].bundleIdentifier;
        if (bundleID) {
            [[CHIdentityEngine sharedEngine] resetIdentityForBundleID:bundleID];
        }
    }]];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)resetAllIdentities {
    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:@"Reset All Identities"
        message:@"This will generate new identities for ALL apps. Respring required."
        preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Reset All" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        NSString *path = @"/var/mobile/Library/Preferences/com.chameleon.identities.plist";
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }]];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.titleView = [UIView new];
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"Chameleon";
    titleLabel.font = [UIFont boldSystemFontOfSize:17];
    [titleLabel sizeToFit];
    self.navigationItem.titleView = titleLabel;
}

@end

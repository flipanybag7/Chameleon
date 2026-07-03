#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import "CHIdentityEngine.h"

@interface CHPRootListController : PSListController
@end

@implementation CHPRootListController

- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"Specifiers" target:self];
    }
    return _specifiers;
}

- (id)readPreferenceValue:(PSSpecifier *)spec {
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.chameleon.prefs"];
    return [defaults objectForKey:[spec propertyForKey:@"key"]] ?: @YES;
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)spec {
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.chameleon.prefs"];
    [defaults setObject:value forKey:[spec propertyForKey:@"key"]];
    [defaults synchronize];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    PSSpecifier *spec = self.specifiers[indexPath.section][indexPath.row];
    NSString *action = [spec propertyForKey:@"action"];
    if ([action isEqualToString:@"reset"]) {
        NSString *bundleID = [NSBundle mainBundle].bundleIdentifier;
        if (bundleID) [[CHIdentityEngine sharedEngine] resetIdentityForBundleID:bundleID];
    } else if ([action isEqualToString:@"resetAll"]) {
        NSString *path = @"/var/mobile/Library/Preferences/com.chameleon.identities.plist";
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
}

@end

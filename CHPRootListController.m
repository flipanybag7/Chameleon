#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import "CHContainerManager.h"
#import "CHIdentityEngine.h"

@interface CHPRootListController : PSListController
@end

@implementation CHPRootListController

- (NSArray *)specifiers {
    if (!_specifiers) {
        NSMutableArray *specs = [NSMutableArray array];
        [specs addObject:[PSSpecifier groupSpecifierWithName:@"Chameleon"]];
        [specs addObject:[PSSpecifier preferenceSpecifierNamed:@"Installed Apps"
            target:self set:NULL get:NULL detail:objc_getClass("CHAppListController")
            cell:PSLinkCell edit:nil]];

        [specs addObject:[PSSpecifier groupSpecifierWithName:@"Spoofed APIs"]];
        NSArray *toggles = @[
            @{@"key": @"SpoofUIDevice", @"label": @"UIDevice"},
            @{@"key": @"SpoofMGCopyAnswer", @"label": @"MobileGestalt"},
            @{@"key": @"SpoofASIdentifier", @"label": @"Advertising ID"},
            @{@"key": @"SpoofCanvas", @"label": @"Canvas / WebGL"},
            @{@"key": @"SpoofSysctl", @"label": @"Sysctl"},
            @{@"key": @"SpoofIOKit", @"label": @"IOKit"},
            @{@"key": @"SpoofNetwork", @"label": @"Carrier Info"},
        ];
        for (NSDictionary *item in toggles) {
            PSSpecifier *spec = [PSSpecifier preferenceSpecifierNamed:item[@"label"]
                target:self set:@selector(setPreferenceValue:specifier:)
                get:@selector(readPreferenceValue:) detail:nil cell:PSSwitchCell edit:nil];
            [spec setProperty:item[@"key"] forKey:@"key"];
            [spec setProperty:@YES forKey:@"default"];
            [specs addObject:spec];
        }

        [specs addObject:[PSSpecifier groupSpecifierWithName:@"Profile Manager"]];
        PSSpecifier *pickerSpec = [PSSpecifier preferenceSpecifierNamed:@"Show profile picker on launch"
            target:self set:@selector(setPreferenceValue:specifier:)
            get:@selector(readPreferenceValue:) detail:nil cell:PSSwitchCell edit:nil];
        [pickerSpec setProperty:@"ShowPicker" forKey:@"key"];
        [pickerSpec setProperty:@YES forKey:@"default"];
        [specs addObject:pickerSpec];

        _specifiers = specs;
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

@end

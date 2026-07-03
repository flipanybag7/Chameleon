#import "CHIdentityEngine.h"
#import <substrate.h>
#include <notify.h>

static void showSettingsPanel(void);

%hook UIApplication

- (void)applicationDidFinishLaunching:(id)application {
    %orig;

    static dispatch_once_t once;
    dispatch_once(&once, ^{
        int token;
        notify_register_dispatch("com.chameleon.openSettings", &token, dispatch_get_main_queue(), ^(int t) {
            showSettingsPanel();
        });
    });
}

%end

%hook UIWindow

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    %orig;
    if (motion == UIEventSubtypeMotionShake) {
        showSettingsPanel();
    }
}

%end

static void showSettingsPanel(void) {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Chameleon"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];

    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.chameleon.prefs"];
    [defaults registerDefaults:@{
        @"Enabled": @YES,
        @"SpoofUIDevice": @YES,
        @"SpoofMGCopyAnswer": @YES,
        @"SpoofASIdentifier": @YES,
        @"SpoofCanvas": @YES,
        @"SpoofSysctl": @YES,
        @"SpoofIOKit": @YES,
        @"SpoofNetwork": @YES,
    }];

    NSArray *toggles = @[
        @{@"key": @"Enabled", @"label": @"Chameleon Enabled"},
        @{@"key": @"SpoofUIDevice", @"label": @"Spoof UIDevice"},
        @{@"key": @"SpoofMGCopyAnswer", @"label": @"Spoof MobileGestalt"},
        @{@"key": @"SpoofASIdentifier", @"label": @"Spoof Advertising ID"},
        @{@"key": @"SpoofCanvas", @"label": @"Spoof Canvas / WebGL"},
        @{@"key": @"SpoofSysctl", @"label": @"Spoof Sysctl"},
        @{@"key": @"SpoofIOKit", @"label": @"Spoof IOKit"},
        @{@"key": @"SpoofNetwork", @"label": @"Spoof Carrier Info"},
    ];

    for (NSDictionary *item in toggles) {
        NSString *key = item[@"key"];
        NSString *label = item[@"label"];
        BOOL on = [defaults boolForKey:key];
        NSString *status = on ? @"✅" : @"❌";

        [alert addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:@"%@  %@", status, label]
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {
            [defaults setBool:!on forKey:key];
            [defaults synchronize];
        }]];
    }

    [alert addAction:[UIAlertAction actionWithTitle:@"Reset Identity (current app)"
                                              style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction *action) {
        NSString *bundleID = [NSBundle mainBundle].bundleIdentifier;
        if (bundleID) {
            [[CHIdentityEngine sharedEngine] resetIdentityForBundleID:bundleID];
        }
    }]];

    [alert addAction:[UIAlertAction actionWithTitle:@"Reset All Identities"
                                              style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction *action) {
        NSString *path = @"/var/mobile/Library/Preferences/com.chameleon.identities.plist";
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }]];

    [alert addAction:[UIAlertAction actionWithTitle:@"Close"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];

    UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (rootVC.presentedViewController) {
        rootVC = rootVC.presentedViewController;
    }

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        alert.popoverPresentationController.sourceView = rootVC.view;
        alert.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(rootVC.view.bounds), CGRectGetMidY(rootVC.view.bounds), 0, 0);
        alert.popoverPresentationController.permittedArrowDirections = 0;
    }

    [rootVC presentViewController:alert animated:YES completion:nil];
}

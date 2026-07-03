#import "CHContainerManager.h"
#import "CHIdentityEngine.h"
#import <UIKit/UIKit.h>
#import <substrate.h>
#import <objc/runtime.h>

static void showProfilePicker(NSString *bundleID);

%hook UIApplication

- (void)applicationDidFinishLaunching:(id)application {
    %orig;
    if (![CHIdentityEngine isHookEnabled:@"Enabled"]) return;

    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    if (!bundleID) return;

    CHContainerManager *cm = [CHContainerManager sharedManager];
    if (![cm hasMultipleContainersForBundleID:bundleID]) return;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        showProfilePicker(bundleID);
    });
}

%end

static void showProfilePicker(NSString *bundleID) {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Select Profile"
                                                                   message:bundleID
                                                            preferredStyle:UIAlertControllerStyleActionSheet];

    CHContainerManager *cm = [CHContainerManager sharedManager];
    NSArray *uuids = [cm containerUUIDsForBundleID:bundleID];

    for (NSString *uuid in uuids) {
        NSDictionary *info = [cm containerInfoForBundleID:bundleID uuid:uuid];
        NSString *name = info[@"name"] ?: uuid;
        NSString *active = [cm activeContainerForBundleID:bundleID];
        NSString *label = [uuid isEqualToString:active] ? [NSString stringWithFormat:@"%@ ✓", name] : name;

        [alert addAction:[UIAlertAction actionWithTitle:label style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {
            [cm setActiveContainer:uuid forBundleID:bundleID];
        }]];
    }

    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];

    UIViewController *root = nil;
    if (@available(iOS 13, *)) {
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                root = [(UIWindowScene *)scene windows].firstObject.rootViewController;
                break;
            }
        }
    }
    if (!root) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        root = [UIApplication sharedApplication].keyWindow.rootViewController;
#pragma clang diagnostic pop
    }
    while (root.presentedViewController) root = root.presentedViewController;

    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        alert.popoverPresentationController.sourceView = root.view;
        alert.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(root.view.bounds), 0, 0, 0);
        alert.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp;
    }

    [root presentViewController:alert animated:YES completion:nil];
}

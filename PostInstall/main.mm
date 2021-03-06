/**
 * Description: Post install script for IconSupport
 * Author: Lance Fetters (aka. ashikase)
 * Last-modified: 2012-01-25 15:27:24
 */

#define kCFCoreFoundationVersionNumber_iPhoneOS_4_0 550.32
#define isPreIOS4 (kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iPhoneOS_4_0)

#define APP_ID "com.chpwn.iconsupport"
#define STALE_FILE_KEY "hasOldStateFile"

int main(int argc, char *argv[]) {
    // Move old "IconSupportState-*****.plist" file to "IconSupportState.plist"
    // NOTE: This conversion is only needed for iOS 4.x+, as the 3.x code for
    //       IconSupport still uses hash-postfixed plist files.
    if (!isPreIOS4) {
        // NOTE: This program is run as root during install; must switch the
        //       effective user to mobile (501).
        seteuid(501);

        // Create pool
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

        // Make sure that a plist using the new name does not already exist
        NSString *basePath = @"/var/mobile/Library/SpringBoard/";
        NSString *newPath = [basePath stringByAppendingString:@"IconSupportState.plist"];
        NSFileManager *manager = [NSFileManager defaultManager];
        if (![manager fileExistsAtPath:newPath]) {
            // Get the last used IconSupport hash (if it exists)
            NSDictionary *defaults = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.apple.springboard"];
            NSString *hash = [defaults objectForKey:@"ISLastUsed"];
            if ([hash length] != 0) {
                // If a state file with this hash as part of its name exists, rename it
                NSString *oldPath = [basePath stringByAppendingFormat:@"IconSupportState%@.plist", hash];
                if ([manager fileExistsAtPath:oldPath]) {
                    // Move old state file to new path
                    // NOTE: Must do in two steps: copy file to new path, then remove old file.
                    // NOTE: If IconSupporState.plist already exists (it should not), it will not be overwritten.
                    BOOL success = [manager copyItemAtPath:oldPath toPath:newPath error:NULL];
                    if (success) {
                        [manager removeItemAtPath:oldPath error:NULL];
                        printf("Moved %s to %s\n", [oldPath UTF8String], [newPath UTF8String]);
                    }
                }
            }
        }

        // If this is a fresh install (and not an upgrade), note if an old state file exists
        if (argc > 1 && strcmp(argv[1], "install") == 0) {
            if ([manager fileExistsAtPath:newPath]) {
                CFPreferencesSetAppValue(CFSTR(STALE_FILE_KEY), [NSNumber numberWithBool:YES], CFSTR(APP_ID));
                CFPreferencesAppSynchronize(CFSTR(APP_ID));
            }
        }

        // Cleanup
        [pool release];
    }

    return 0;
}

/* vim: set filetype=objc sw=4 ts=4 sts=4 expandtab textwidth=80 ff=unix: */

/*
 Copyright (C) 2012-2014 Soomla Inc.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "SoomlaUtils.h"
#import "SoomlaConfig.h"
#import <UIKit/UIKit.h>

@implementation SoomlaUtils

static NSString* TAG = @"SOOMLA SoomlaUtils";

static NSString *const SOOMLA_DEVICE_KEY = @"soomlaDeviceId";
static NSString *const SOOMLA_GENERATED_KEY = @"soomlaGeneratedId";

+ (void)LogDebug:(NSString*)tag withMessage:(NSString*)msg {
    if (DEBUG_LOG) {
        NSLog(@"[Debug] %@: %@", tag, msg);
    }
}

+ (void)LogError:(NSString*)tag withMessage:(NSString*)msg {
    NSLog(@"[*** ERROR ***] %@: %@", tag, msg);
}

+ (NSString*)deviceIdPreferVendor {
    NSString *soomlaDeviceId = [[NSUserDefaults standardUserDefaults] stringForKey:SOOMLA_DEVICE_KEY];
    if (!soomlaDeviceId) {
        soomlaDeviceId = [SoomlaUtils vendorId];
        [[NSUserDefaults standardUserDefaults] setObject:soomlaDeviceId forKey:SOOMLA_DEVICE_KEY];
    }
    return soomlaDeviceId;
}

/* We check for UDID_SOOMLA to support devices with older versions of ios-store */
+ (NSString*)deviceId {
    NSString* udid = [[NSUserDefaults standardUserDefaults] stringForKey:@"UDID_SOOMLA"];
    if (!udid || [udid length] == 0) {
	return [self deviceIdPreferVendor];
    }
    return udid;
}

+ (NSString*)vendorId {
    NSString *vendorId;
    if ([[UIDevice currentDevice] respondsToSelector:@selector(identifierForVendor)]) {
        vendorId = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    } else {
        vendorId = [SoomlaUtils generateSoomlaId];
    }
    return vendorId;
}

+ (NSString*)generateSoomlaId {
    NSString *soomlaGeneratedId = [[NSUserDefaults standardUserDefaults] stringForKey:SOOMLA_GENERATED_KEY];
    if (!soomlaGeneratedId) {
        soomlaGeneratedId = [NSString stringWithFormat:@"SOOMLA_ID_i%05d%05d", arc4random_uniform(100000), arc4random_uniform(100000)];
        [[NSUserDefaults standardUserDefaults] setObject:soomlaGeneratedId forKey:SOOMLA_GENERATED_KEY];
    }
    return soomlaGeneratedId;
}


+ (NSString*)keyFromSecret:(NSString*)secret {
    return [secret stringByAppendingString:[SoomlaUtils deviceId]];
}

+ (NSMutableDictionary*)jsonStringToDict:(NSString*)str {
    NSError* error = NULL;
    NSMutableDictionary *dict =
    [NSJSONSerialization JSONObjectWithData: [str dataUsingEncoding:NSUTF8StringEncoding]
                                    options: NSJSONReadingMutableContainers
                                      error: &error];
    if (error) {
        LogError(TAG, ([NSString stringWithFormat:@"There was a problem parsing the given JSON string: %@ error: %@", str, [error localizedDescription]]));

        return NULL;
    }

    return dict;
}

+ (NSMutableArray*)jsonStringToArray:(NSString*)str {
    NSError* error = NULL;
    NSMutableArray *arr =
    [NSJSONSerialization JSONObjectWithData: [str dataUsingEncoding:NSUTF8StringEncoding]
                                    options: NSJSONReadingMutableContainers
                                      error: &error];
    if (error) {
        LogError(TAG, ([NSString stringWithFormat:@"There was a problem parsing the given JSON string: %@ error: %@", str, [error localizedDescription]]));

        return NULL;
    }

    return arr;
}

+ (NSString*)dictToJsonString:(NSDictionary*)dict {
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];

    if (! jsonData) {
        LogError(TAG, ([NSString stringWithFormat:@"There was a problem parsing the given NSDictionary. error: %@", [error localizedDescription]]));

        return NULL;
    }

    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

+ (NSString*)arrayToJsonString:(NSArray*)arr {
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:arr
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];

    if (! jsonData) {
        LogError(TAG, ([NSString stringWithFormat:@"There was a problem parsing the given NSArray. error: %@", [error localizedDescription]]));

        return NULL;
    }

    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

+ (NSString *) applicationDirectory
{
    static NSString* appDir = nil;

    if (appDir == nil) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
        if ([paths count] == 0)
        {
            // *** creation and return of error object omitted for space
            return nil;
        }

        NSString *basePath = paths[0];
        NSError *error;

        NSFileManager *fManager = [NSFileManager defaultManager];
        if (![fManager fileExistsAtPath:basePath]) {
            if (![fManager createDirectoryAtPath:basePath
                     withIntermediateDirectories:YES
                                      attributes:nil
                                           error:&error])
            {
                LogError(TAG, ([NSString stringWithFormat:@"Create directory error: %@", error]));
                return nil;
            }
        }
        appDir = [basePath copy];
    }
    return appDir;
}

+ (BOOL)addSkipBackupAttributeToItemAtURL:(NSURL *)URL
{
    assert([[NSFileManager defaultManager] fileExistsAtPath: [URL path]]);

    NSError *error = nil;
    BOOL success = [URL setResourceValue: [NSNumber numberWithBool: YES]
                                  forKey: NSURLIsExcludedFromBackupKey error: &error];
    if(!success){
        NSLog(@"Error excluding %@ from backup %@", [URL lastPathComponent], error);
    }
    return success;
}

+ (void)setLoggingEnabled:(BOOL)logEnabled {
    DEBUG_LOG = logEnabled;
}

+ (NSString *)getClassName:(id)target {
    return NSStringFromClass([target class]);
}

+ (BOOL)isEmpty:(NSString *)target {
    return (!target || target.length == 0);
}

@end

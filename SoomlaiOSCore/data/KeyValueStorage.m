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

#import "KeyValueStorage.h"
#import "KeyValDatabase.h"
#import "SoomlaEncryptor.h"
#import "KeyValDatabase.h"
#import "SoomlaConfig.h"
#import "SoomlaUtils.h"

@implementation KeyValueStorage

+ (KeyValDatabase*)kvDatabase {
    static KeyValDatabase* dbInstance;
    if (!dbInstance) {
        dbInstance = [[KeyValDatabase alloc] init];
    }
    return dbInstance;
}

- (id)init{
    self = [super init];
    if (self){
        
    }
    
    return self;
}

+ (NSString*)getValueForKey:(NSString*)key {
    return [self getValueForKey:key withEncryptionKey:nil];
}

+ (NSString*)getValueForKey:(NSString*)key withEncryptionKey:(NSString *)encryptionKey {
    key = [SoomlaEncryptor encryptString:key withKey:encryptionKey];
    NSString* val = [[self kvDatabase] getValForKey:key];
    if (val && [val length]>0){
        return [SoomlaEncryptor decryptToString:val withKey:encryptionKey];
    }
    
    return NULL;
}

+ (void)setValue:(NSString*)val forKey:(NSString*)key {
    [self setValue:val forKey:key withEncryptionKey:nil];
}

+ (void)setValue:(NSString*)val forKey:(NSString*)key withEncryptionKey:(NSString *)encryptionKey {
    key = [SoomlaEncryptor encryptString:key withKey:encryptionKey];
    [[self kvDatabase] setVal:[SoomlaEncryptor encryptString:val withKey:encryptionKey] forKey:key];
}

+ (void)deleteValueForKey:(NSString*)key {
    [self deleteValueForKey:key withEncryptionKey:nil];
}

+ (void)deleteValueForKey:(NSString*)key withEncryptionKey:(NSString *)encryptionKey {
    key = [SoomlaEncryptor encryptString:key withKey:encryptionKey];
    [[self kvDatabase] deleteKeyValWithKey:key];
}

+ (NSDictionary*)getKeysValuesForNonEncryptedQuery:(NSString*)query {
    return [self getKeysValuesForNonEncryptedQuery:query withEncryptionKey:nil];
}

+ (NSDictionary*)getKeysValuesForNonEncryptedQuery:(NSString*)query withEncryptionKey:(NSString *)encryptionKey {
    NSDictionary* dbResults = [[self kvDatabase] getKeysValsForQuery:query];
    NSMutableDictionary* results = [NSMutableDictionary dictionary];
    NSArray* keys = [dbResults allKeys];
    for (NSString* key in keys) {
        NSString* val = dbResults[key];
        if (val && [val length]>0){
            NSString* valDec = [SoomlaEncryptor decryptToString:val withKey:encryptionKey];
            if (valDec && [valDec length]>0){
                [results setObject:valDec forKey:key];
            }
        }
    }
    
    return results;
}

+ (NSArray*)getValuesForNonEncryptedQuery:(NSString*)query {
    return [self getValuesForNonEncryptedQuery:query withLimit:0 withEncryptionKey:nil];
}

+ (NSArray*)getValuesForNonEncryptedQuery:(NSString*)query withEncryptionKey:(NSString *)encryptionKey {
    return [self getValuesForNonEncryptedQuery:query withLimit:0 withEncryptionKey:encryptionKey];
}

+ (NSArray*)getValuesForNonEncryptedQuery:(NSString*)query withLimit:(int)limit {
    return [self getValuesForNonEncryptedQuery:query withLimit:limit withEncryptionKey:nil];
}

+ (NSArray*)getValuesForNonEncryptedQuery:(NSString*)query withLimit:(int)limit withEncryptionKey:(NSString *)encryptionKey {
    NSArray* vals = [[self kvDatabase] getValsForQuery:query withLimit:limit];
    NSMutableArray* results = [NSMutableArray array];
    for (NSString* val in vals) {
        if (val && [val length]>0){
            NSString* valDec = [SoomlaEncryptor decryptToString:val withKey:encryptionKey];
            if (valDec && [valDec length]>0){
                [results addObject:valDec];
            }
        }
    }
    
    return results;
}

+ (NSString*)getOneForNonEncryptedQuery:(NSString*)query {
    return [self getOneForNonEncryptedQuery:query withEncryptionKey:nil];
}

+ (NSString*)getOneForNonEncryptedQuery:(NSString*)query withEncryptionKey:(NSString *)encryptionKey {
    NSString* val = [[self kvDatabase] getOneForQuery:query];
    if (val && [val length]>0){
        NSString* valDec = [SoomlaEncryptor decryptToString:val withKey:encryptionKey];
        if (valDec && [valDec length]>0){
            return valDec;
        }
    }
    
    return NULL;
}

+ (int)getCountForNonEncryptedQuery:(NSString*)query {
    return [[self kvDatabase] getCountForQuery:query];
}

+ (NSString*)getValueForNonEncryptedKey:(NSString*)key {
    return [self getValueForNonEncryptedKey:key withEncryptionKey:nil];
}

+ (NSString*)getValueForNonEncryptedKey:(NSString*)key withEncryptionKey:(NSString *)encryptionKey {
    NSString* val = [[self kvDatabase] getValForKey:key];
    if (val && [val length]>0){
        return [SoomlaEncryptor decryptToString:val withKey:encryptionKey];
    }
    
    return NULL;
}

+ (NSArray *)getEncryptedKeys {
    return [self getEncryptedKeysWithEncryptionKey:nil];
}

+ (NSArray *)getEncryptedKeysWithEncryptionKey:(NSString *)encryptionKey {
    NSArray *encryptedKeys = [[self kvDatabase] getAllKeys];
    NSMutableArray *resultKeys = [NSMutableArray array];
    
    for (NSString *encryptedKey in encryptedKeys) {
        @try {
            NSString *unencryptedKey = [SoomlaEncryptor decryptToString:encryptedKey withKey:encryptionKey];
            if (unencryptedKey) {
                [resultKeys addObject:unencryptedKey];
            }
        }
        @catch (NSException *exception) {
            LogDebug(TAG, ([NSString stringWithFormat:@"Exception while decrypting all keys: %@", exception.description]));
        }
    }
    
    return resultKeys;
}

+ (void)setValue:(NSString*)val forNonEncryptedKey:(NSString*)key {
    [self setValue:val forNonEncryptedKey:key withEncryptionKey:nil];
}

+ (void)setValue:(NSString*)val forNonEncryptedKey:(NSString*)key withEncryptionKey:(NSString *)encryptionKey {
    [[self kvDatabase] setVal:[SoomlaEncryptor encryptString:val withKey:encryptionKey] forKey:key];
}

+ (void)deleteValueForNonEncryptedKey:(NSString*)key {
    [[self kvDatabase] deleteKeyValWithKey:key];
}

+ (void)purge {
    [[self kvDatabase] purgeDatabase];
}

static NSString* TAG = @"SOOMLA KeyValueStorage";

@end

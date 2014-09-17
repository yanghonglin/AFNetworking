//
//  MOImageDiskCache.m
//  Pods
//
//  Created by Honglin Young on 14-6-25.
//
//

#import "MOImageDiskCache.h"

#import <CommonCrypto/CommonDigest.h>

static char * const imageDiskCacheQueue = "com.immomo.imageDiskCacheQueue";

static NSString * const appSupportPath = @"Application Support";

static unsigned char kPNGSignatureBytes[8] = {0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A};
static NSData *kPNGSignatureData = nil;

@implementation MOImageDiskCache


- (instancetype)initWithRelativePath:(NSString *)relativePath
{
    self = [super init];
    if (self) {
        kPNGSignatureData = [NSData dataWithBytes:kPNGSignatureBytes length:8];
        
        _ioQueue = dispatch_queue_create(imageDiskCacheQueue, NULL);
        
        _fileManager = [[NSFileManager alloc] init];
        
        dispatch_sync(_ioQueue, ^{
            BOOL isDirectory = YES;
            NSArray *arr = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
            NSString *string = [NSString stringWithString:[arr firstObject]];
            if (!string) {
                string = [NSString stringWithFormat:@"%@/%@",NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0], appSupportPath];
            }
            
            if (![_fileManager fileExistsAtPath:string isDirectory:&isDirectory]) {
                NSError *error = nil;
                [_fileManager createDirectoryAtPath:string withIntermediateDirectories:NO attributes:NULL error:&error];
                if (error) {
                    NSLog(@"create directory file at path :%@ error :%@", string, error);
                }
            }
            self.path = [NSString stringWithFormat:@"%@/%@", string, relativePath];
            if (![_fileManager fileExistsAtPath:self.path isDirectory:&isDirectory]) {
                NSError *error = nil;
                [_fileManager createDirectoryAtPath:self.path withIntermediateDirectories:NO attributes:NULL error:&error];
                if (error) {
                    NSLog(@"create directory file at path :%@ error :%@", self.path, error);
                } else {

                }
            }
        });
    }
    
    return self;
}

- (BOOL)imageExistOnDiskForKey:(NSString *)key
{
    if (!key) {
        return NO;
    }
    
    __block BOOL exist = NO;
    dispatch_sync(_ioQueue, ^{
        NSString *filePath = [self.path stringByAppendingFormat:@"%@/%@", self.path, key];
        exist = [_fileManager fileExistsAtPath:filePath isDirectory:NO];
    });
    return exist;
}

- (void)asynQueryDiskImageForKey:(NSString *)key done:(void (^)(UIImage *image))doneBlock fail:(void (^)(void))failBlock
{
    if (key) {
        dispatch_async(_ioQueue, ^{
            NSString *path = [self cachePathForKey:key];
            NSData *data = [[NSData alloc] initWithContentsOfFile:path];
            if (data) {
                UIImage *img = [UIImage imageWithData:data];
                if (img) {
                    doneBlock(img);
                } else {
                    failBlock();
                }
            }
        });
    } else {
        failBlock();
    }
}

- (void)synQueryDiskImageForKey:(NSString *)key done:(void (^)(UIImage *image))doneBlock fail:(void (^)(void))failBlock
{
    if (key) {
        NSString *path = [self cachePathForKey:key];
        NSData *data = [[NSData alloc] initWithContentsOfFile:path];
        if (data) {
            UIImage *img = [UIImage imageWithData:data];
            if (img) {
                doneBlock(img);
            } else {
                failBlock();
            }
        }
    } else {
        failBlock();
    }
}

- (UIImage *)synQueryDiskImageForKey:(NSString *)key
{
    UIImage *img = nil;
    if (key) {
        NSString *path = [self cachePathForKey:key];
        NSData *data = [[NSData alloc] initWithContentsOfFile:path];
        if (data) {
            img = [UIImage imageWithData:data];
        }
    }
    
    return img;
}

- (void)saveImage:(UIImage *)image onDiskForKey:(NSString *)key;
{
    if (key && image) {
        dispatch_async(_ioQueue, ^{
            NSString *path = [self cachePathForKey:key];
            NSData *data = UIImagePNGRepresentation(image);
            [data writeToFile:path atomically:NO];
        });
    }
}

- (void)saveImageData:(NSData *)data onDiskForKey:(NSString *)key
{
    if (key && data) {
        dispatch_async(_ioQueue, ^{
            NSString *path = [self cachePathForKey:key];
            [data writeToFile:path atomically:NO];
        });
    }
}

- (NSString *)cachePathForKey:(NSString *)key
{
    NSString *name = [self cacheNameForKey:key];
    return [NSString stringWithFormat:@"%@/%@", _path, name];
}

- (NSString *)cacheNameForKey:(NSString *)key
{
    const char *str = [key UTF8String];
    if (str == NULL) {
        str = "";
    }
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), r);
    NSString *filename = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                          r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10], r[11], r[12], r[13], r[14], r[15]];
    
    return filename;
}

@end

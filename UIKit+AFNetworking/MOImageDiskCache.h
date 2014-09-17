//
//  MOImageDiskCache.h
//  Pods
//
//  Created by Honglin Young on 14-6-25.
//
//

#import <Foundation/Foundation.h>

#import <UIKit/UIKit.h>

//In iOS 5.0.1 and later, put support files in the <Application_Home>/Library/Application Support directory
//and apply the com.apple.MobileBackup extended attribute to them.

@interface MOImageDiskCache : NSObject

@property (strong, nonatomic) dispatch_queue_t ioQueue;
@property (strong, nonatomic) NSFileManager *fileManager;
@property (strong, nonatomic) NSString *path;

//relativepath should has none slash
- (instancetype)initWithRelativePath:(NSString *)relativePath;

- (BOOL)imageExistOnDiskForKey:(NSString *)key;
- (void)saveImage:(UIImage *)image onDiskForKey:(NSString *)key;
- (void)saveImageData:(NSData *)data onDiskForKey:(NSString *)key;
- (void)asynQueryDiskImageForKey:(NSString *)key done:(void (^)(UIImage *image))doneBlock fail:(void (^)(void))failBlock;
- (void)synQueryDiskImageForKey:(NSString *)key done:(void (^)(UIImage *image))doneBlock fail:(void (^)(void))failBlock;
- (UIImage *)synQueryDiskImageForKey:(NSString *)key;

@end

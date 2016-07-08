//
//  ViewController.m
//  ImageDownLoader
//
//  Created by ywl on 16/7/7.
//  Copyright © 2016年 ywl. All rights reserved.
//

#import "ViewController.h"
#import "SDWebImageDownloader.h"
#import "Model.h"
@interface ViewController () <NSStreamDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self retryFailImage];
}

+ (void)initialize {
    
    // Set user agent (the only problem is that we can't modify the User-Agent later in the program)
    
    NSDictionary *dictionnary = [[NSDictionary alloc] initWithObjectsAndKeys:@"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/50.0.2661.102 Safari/537.36", @"UserAgent", nil];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:dictionnary];
    
    
}

- (void)retryFailImage
{
     NSArray *allarray = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"downloadList.plist" ofType:nil]];
    NSMutableArray *models = [NSMutableArray array];
    
    for (NSDictionary *dic in allarray) {
        Model *model = [[Model alloc] init];
        model.uId = dic[@"id"];
        model.icon = dic[@"icon"];
        model.startIndex = dic[@"endIndex"];
        model.endIndex = dic[@"startIndex"];
        model.app = dic[@"app"];
        model.url = dic[@"url"];
        [models addObject:model];
    }
    
    NSMutableArray *failedURLs = [NSMutableArray array];
    NSString *failedString = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"failed.data" ofType:nil] encoding:NSUTF8StringEncoding error:nil];
    // 每行
    NSArray *rowComponents = [failedString componentsSeparatedByString:@"\n"];
    NSInteger index = 0;
    for (NSString *rowComponent in rowComponents) {
        if (index != rowComponents.count - 1) {
            NSArray *rowComponetArray = [rowComponent componentsSeparatedByString:@" "];
//            NSLog(@"%@", rowComponetArray);
            if ([rowComponetArray[3] isEqualToString:@"failed"]) {
                [failedURLs addObject:rowComponetArray[4]];
            }
        }

        index++;
    }
    
    
    NSMutableArray *retryFailedArray = [NSMutableArray array];
    __block NSInteger retryRecordIndex = 0;
    for (NSString *url in failedURLs) {
//        NSLog(@"%@",url);
         NSArray *urlComponet = [url componentsSeparatedByString:@"/"];
//        NSLog(@"%@", urlComponet);
        Model *model = [models filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.uId == %@", urlComponet[3]]].firstObject;
        // 找到路径下载图片
        NSString *path = [[@"/Users/ywl/Desktop/LiuLi" stringByAppendingPathComponent:model.app] stringByAppendingPathComponent:@"screenshoot"];
        [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:[NSURL URLWithString:model.url] options:0 progress:nil completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished) {
            if (data && !error) {
                [data writeToFile:[path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_screenshoot_%@", model.app, urlComponet[4]]] atomically:YES];
                NSLog(@"success %@", url);
            } else {
                [retryFailedArray addObject:url];
                NSLog(@"failed %@", url);
            }
            
            if (retryRecordIndex == failedURLs.count - 1) {
                // 失败日志写入本地文件
                [retryFailedArray writeToFile:@"/Users/ywl/Desktop/retryFaild.data" atomically:YES];
            }
            retryRecordIndex++;
            
        }];
    }
    
//    NSInputStream *inStream = [[NSInputStream alloc] initWithURL:[[NSBundle mainBundle] URLForResource:@"failed.data" withExtension:nil]];
//   
//    [inStream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
//    inStream.delegate = self;
//     [inStream open];
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    
//    NSInputStream *iSream = (NSInputStream *)aStream;
//    switch (eventCode) {
//        case NSStreamEventEndEncountered:
//            
//            break;
//     case NSStreamEventHasBytesAvailable:
//            uint8_t
//            iSream read:<#(nonnull uint8_t *)#> maxLength:<#(NSUInteger)#>
//            
//            break;
//        default:
//            break;
//    }
}

- (void)downloadFormPattern
{
    NSArray *array = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"downloadList.plist" ofType:nil]];
    //    NSLog(@"%@", array);
    //    NSString *path = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject.absoluteString;
    //    NSLog(@"doc path %@", path);
    
    NSMutableArray *errorArrays = [NSMutableArray array];
    for (NSDictionary *appDic in array) {
        NSString *path = [@"/Users/ywl/Desktop/LiuLi" stringByAppendingPathComponent:appDic[@"app"]];
        if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
            NSError *error = nil;
            [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:&error];
            
        }
        // 下载logo
        [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:[NSURL URLWithString:appDic[@"icon"]] options:0 progress:nil completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished) {
            if (data && !error) {
                [data writeToFile:[path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_icon.png", appDic[@"app"]]] atomically:YES];
            }
            
        }];
        
        NSString *screenShotPath = [path stringByAppendingPathComponent:@"screenshoot"];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:screenShotPath]) {
            NSError *error = nil;
            [[NSFileManager defaultManager] createDirectoryAtPath:screenShotPath withIntermediateDirectories:NO attributes:nil error:&error];
            
        }
        
        // 下载图片
        NSInteger startIndex = [appDic[@"endIndex"] integerValue];
        NSInteger endIndex = [appDic[@"startIndex"] integerValue];
        for (NSInteger index = startIndex; index <= endIndex; index++) {
            NSString *imageCdnPath = [NSString stringWithFormat:@"http://cdn.pttrns.com/%@/%ld_f.jpg", appDic[@"id"], (long)index];
            [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:[NSURL URLWithString:imageCdnPath] options:0 progress:nil completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished) {
                if (data && !error) {
                    [data writeToFile:[screenShotPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_screenshoot_%ld.png", appDic[@"app"], (long)index]] atomically:YES];
                    NSLog(@"success %@", imageCdnPath);
                } else {
                    [errorArrays addObject:appDic];
                    NSLog(@"failed %@", imageCdnPath);
                }
                
            }];
        }
        
        
    }
    
    [errorArrays writeToFile:@"/Users/ywl/Desktop/LiuLi/faild.plist" atomically:YES];
    //    NSDictionary *dic = array.firstObject;
    //    NSError *error = nil;
    //    NSString *path = [@"/Users/ywl/Desktop/LiuLi" stringByAppendingPathComponent:dic[@"app"]];
    //    [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:&error];
    //    NSLog(@"%@", error);
    //
    //    [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:[NSURL URLWithString:dic[@"icon"]] options:0 progress:nil completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished) {
    //        [data writeToFile:[path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_icon.png", dic[@"app"]]] atomically:YES];
    //    }];

}


@end

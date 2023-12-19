//
//  ViewController.m
//  LearningFFmpeg
//
//  Created by 张雄飞 on 2023/12/16.
//

#import "ViewController.h"
#import <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libavdevice/avdevice.h>
#import <AVFoundation/AVFoundation.h>
#include <SDL2/SDL.h>

#define FMT_NAME "avfoundation"
#define DEVICE_NAME ":0"

@interface ViewController()

@property (nonatomic, assign) BOOL stop;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    NSLog(@"%s", av_version_info());
    
    SDL_version v;
    NSLog(@"%hhu,%hhu,%hhu", v.major, v.minor, v.patch);
    
    // 初始化Audio子系统
    if (SDL_Init(SDL_INIT_AUDIO)) {
        // 返回值不是0， 代表失败
        NSLog(@"SDL_INIT_ERROR:%s", SDL_GetError());
    }
}

- (void)record {
    
    // 获取输入格式对象
    const AVInputFormat *pInputFmt = av_find_input_format("avfoundation");
    
    if (!pInputFmt) {
        NSLog(@"找不到输入格式");
        return;
    }
    
    // 格式上下文(后面通过格式上下文操作设备)
    AVFormatContext *ctx = avformat_alloc_context();;
    // 打开设备
    int ret = avformat_open_input(&ctx, ":0", pInputFmt, nil);

    if (ret < 0) {
        
        char errBuf[1024] = {0};
        av_strerror(ret, errBuf, sizeof(errBuf));
        
        NSLog(@"打开设备失败");
        return;
    }
    
    AVPacket *packet = av_packet_alloc();
    NSString *filePath = @"/Users/a58/Desktop/audio/qt_record/1.pcm";
        
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:filePath]) {
        NSError *error;
        BOOL success = [fileManager createFileAtPath:filePath contents:nil attributes:nil];
        if (!success) {
            NSLog(@"创建文件失败: %@", [error localizedDescription]);
            // 在此处可以进一步处理错误，例如尝试使用其他路径或者其他方法创建文件等
        } else {
            NSLog(@"文件创建成功");
        }
    }

    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
    if (!fileHandle) {
        NSLog(@"无法打开文件");
    }
    
    while (!self->_stop) {
        int ret = av_read_frame(ctx, packet);
        if (ret == 0) {
            NSData *data = [NSData dataWithBytes:packet->data length:packet->size];
            [fileHandle writeData:data];
            NSLog(@"写入文件: %d", packet->size);
        }else if (ret == AVERROR(EAGAIN)){
            continue;
        }else {
            char errorBuf[1024];
            av_strerror(ret, errorBuf, 1024);
            
            NSLog(@"====");
            break;
        }
        av_packet_unref(packet);
    }
    
    // 关闭文件
    NSLog(@"关闭文件");
    [fileHandle synchronizeFile];
    [fileHandle closeFile];
    
    // 释放资源
    av_packet_free(&packet);
    
    // 关闭设备
    avformat_close_input(&ctx);
}

- (IBAction)start:(id)sender {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
            if (granted) {
                [self record];
            }
        }];
        
    });
}

- (IBAction)stop:(id)sender {
    
    _stop = YES;
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    
    // Update the view, if already loaded.
}


@end

//
//  RecordPCM.m
//  LearningFFmpeg
//
//  Created by 张雄飞 on 2023/12/20.
//

#import "RecordPCM.h"
#import <libavcodec/avcodec.h>
#import <libavformat/avformat.h>
#import <libavdevice/avdevice.h>
#import <AVFoundation/AVFoundation.h>
#import <SDL2/SDL.h>
#import <libavutil/samplefmt.h>

@implementation RecordPCM

BOOL _record_stop;

+ (void)record {
    
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
        if (granted) {
            // 获取输入格式对象
            const AVInputFormat *pInputFmt = av_find_input_format("avfoundation");
            
            if (!pInputFmt) {
                NSLog(@"找不到输入格式");
                return;
            }
            
            // 格式上下文(后面通过格式上下文操作设备)
            AVFormatContext *ctx = avformat_alloc_context();;

            
//            // 获取输入流
//            AVStream *stream = ctx->streams[0];
//            // 获取音频参数
//            AVCodecParameters *params = stream->codecpar;
//            // 声道数
//            NSLog(@"声道数: %d",params->channels);
//
//            // 采样率
//            NSLog(@"采样率: %d",params->sample_rate);
//
//            // 采样格式
//            NSLog(@"采样格式: %d",params->format);
//            // 每一个样本的一个声道占用多少个字节
//            NSLog(@"每一个样本的一个声道占用多少个字节: %d",av_get_bytes_per_sample((AVSampleFormat) params->format));


            // 打开设备
            int ret = avformat_open_input(&ctx, ":1", pInputFmt, nil);
            
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
            
            while (!_record_stop) {
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
    }];
    
}

+ (void)stop{
    _record_stop = YES;
}

@end

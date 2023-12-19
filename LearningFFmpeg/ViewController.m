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


/* 一些宏定义 */
// 采样率
#define SAMPLE_RATE 16000
// 采样格式
#define SAMPLE_FORMAT AUDIO_S16LSB
// 采样大小
#define SAMPLE_SIZE SDL_AUDIO_BITSIZE(SAMPLE_FORMAT)
// 声道数
#define CHANNELS 1
// 音频缓冲区的样本数量
#define SAMPLES 1024


// 每个样本占用多少个字节
#define BYTES_PER_SAMPLE ((SAMPLE_SIZE * CHANNELS) / 8)
// 文件缓冲区的大小
#define BUFFER_SIZE (SAMPLES * BYTES_PER_SAMPLE)


@interface ViewController()

@property (nonatomic, assign) BOOL stop;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    NSLog(@"%s", av_version_info());
    
    SDL_version v;
    SDL_VERSION(&v);
    NSLog(@"%hhu,%hhu,%hhu", v.major, v.minor, v.patch);
    
    // 初始化Audio子系统
    if (SDL_Init(SDL_INIT_AUDIO)) {
        // 返回值不是0， 代表失败
        NSLog(@"SDL_INIT_ERROR:%s", SDL_GetError());
    }
    
    // 音频参数
    SDL_AudioSpec spec;

    // 采样率
    spec.freq = SAMPLE_RATE;

    // 采样格式
    spec.format = SAMPLE_FORMAT;

    // 声道数
    spec.channels = CHANNELS;

    // 音频缓冲区的样本数量（这个值必须是2的幂）
    spec.samples = SAMPLES;

    // 回调拉取播放的数据
    spec.callback = pull_audio_data;

    // 传递给回调的参数
    AudioBuffer buffer;
    spec.userdata = &buffer;

    if (SDL_OpenAudio(&spec, nil)) {
        NSLog(@"SDL_OpenAudio 错误");
        return;
    }
    
    NSString *filePath = @"/Users/a58/Desktop/audio/qt_record/1.pcm";
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:filePath];

    // 开始播放
    SDL_PauseAudio(0);

    // 存放文件数据
    Uint8 data[BUFFER_SIZE];

    while (true) {
        // 只要从文件中读取的音频数据，还没有填充完毕，就跳过
        if (buffer.mDataByteSize > 0) continue;

        buffer.mData = (__bridge void * _Nullable)([fileHandle readDataOfLength:BUFFER_SIZE]);

        // 文件数据已经读取完毕
        if (buffer.mDataByteSize <= 0) {
            // 剩余的样本数量
            int samples = buffer.pullLen / BYTES_PER_SAMPLE;
            int ms = samples * 1000 / SAMPLE_RATE;
            SDL_Delay(ms);
            break;
        }

        // 读取到了文件数据
        buffer.data = data;
    }
}

// userdata：SDL_AudioSpec.userdata
// stream：音频缓冲区（需要将音频数据填充到这个缓冲区）
// len：音频缓冲区的大小（SDL_AudioSpec.samples * 每个样本的大小）
void pull_audio_data(void *userdata, Uint8 *stream, int len) {
    // 清空stream
    SDL_memset(stream, 0, len);

    // 取出缓冲信息
    AudioBuffer *buffer = (AudioBuffer *) userdata;
    if (buffer->len == 0) return;

    // 取len、bufferLen的最小值（为了保证数据安全，防止指针越界）
    buffer->pullLen = (len > buffer->len) ? buffer->len : len;

    // 填充数据
    SDL_MixAudio(stream,
                 buffer->data,
                 buffer->pullLen,
                 SDL_MIX_MAXVOLUME);
    buffer->data += buffer->pullLen;
    buffer->len -= buffer->pullLen;
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

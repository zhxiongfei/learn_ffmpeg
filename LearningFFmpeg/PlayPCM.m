//
//  PlayPCM.m
//  LearningFFmpeg
//
//  Created by 张雄飞 on 2023/12/20.
//

#import "PlayPCM.h"
#import <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libavdevice/avdevice.h>
#include <SDL2/SDL.h>

#define FMT_NAME "avfoundation"
#define DEVICE_NAME ":0"

#define FILE_NAME @"/Users/a58/Desktop/audio/chujian.pcm"

// 采样率
#define SAMPLE_RATE 16000
// 采样格式
#define SAMPLE_FORMAT AUDIO_S16LSB
// 采样大小
#define SAMPLE_SIZE SDL_AUDIO_BITSIZE(SAMPLE_FORMAT)
// 声道数
#define CHANNELS 2
// 音频缓冲区的样本数量
#define SAMPLES 1024


// 每个样本占用多少个字节
#define BYTES_PER_SAMPLE ((SAMPLE_SIZE * CHANNELS) / 8)
// 文件缓冲区的大小
#define BUFFER_SIZE (SAMPLES * BYTES_PER_SAMPLE)


@implementation PlayPCM

typedef struct {
    int len;
    int pullLen;
    char *data;
} AudioBuffer;

BOOL _play_stop;

// userdata：SDL_AudioSpec.userdata
// stream：音频缓冲区（需要将音频数据填充到这个缓冲区）
// len：音频缓冲区的大小（SDL_AudioSpec.samples * 每个样本的大小）
void pull_audio_data(void *userdata, Uint8 *stream, int len) {
    // 清空stream
    SDL_memset(stream, 0, len);
    
    AudioBuffer *buffer = (AudioBuffer *)userdata;

    // 文件数据还没准备好
    if (buffer->data <= 0) return;

    // 取len、bufferLen的最小值（为了保证数据安全，防止指针越界）
    len = len > buffer->len ? buffer->len : len;
    
    // 填充数据
    SDL_MixAudio(stream,
                 (Uint8 *)buffer->data,
                 len,
                 SDL_MIX_MAXVOLUME);

    buffer->data += len;
    buffer->len -= len;
}

+ (void)play{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self _play];
    });
}

+ (void)_play{
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

    int openCode = SDL_OpenAudio(&spec, nil);
    if (openCode) {
        NSLog(@"SDL_OpenAudio 错误");
        // 清除所有子系统
        SDL_Quit();
        return;
    }

    NSString *filePath = FILE_NAME;
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:filePath];
    
    if (fileHandle == nil) {
        NSLog(@"fileHandle 为空");
        
        // 关闭设备
        SDL_CloseAudio();
        // 清除所有子系统
        SDL_Quit();
        
        return;
    }

    // 开始播放
    SDL_PauseAudio(0);
    
    while (!_play_stop) {
        // 只要从文件中读取的音频数据，还没有填充完毕，就跳过
        if (buffer.len > 0) continue;

        NSData *d = [fileHandle readDataOfLength:BUFFER_SIZE];
        
        buffer.data = (char *)[d bytes];
        buffer.len = (int)[d length];
    }
}

@end

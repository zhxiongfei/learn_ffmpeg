//
//  PcmToWav.m
//  LearningFFmpeg
//
//  Created by 张雄飞 on 2023/12/21.
//

#import "PcmToWav.h"
#define AUDIO_FORMAT_PCM 1
#define AUDIO_FORMAT_FLOAT 3

// WAV文件头（44字节）
typedef struct WAVHeader {
    // RIFF chunk的id
    uint8_t riffChunkId[4] = {'R', 'I', 'F', 'F'};
    // RIFF chunk的data大小，即文件总长度减去8字节
    uint32_t riffChunkDataSize;

    // "WAVE"
    uint8_t format[4] = {'W', 'A', 'V', 'E'};

    /* fmt chunk */
    // fmt chunk的id
    uint8_t fmtChunkId[4] = {'f', 'm', 't', ' '};
    // fmt chunk的data大小：存储PCM数据时，是16
    uint32_t fmtChunkDataSize = 16;
    // 音频编码，1表示PCM，3表示Floating Point
    uint16_t audioFormat = AUDIO_FORMAT_PCM;
    // 声道数
    uint16_t numChannels = 2;
    // 采样率
    uint32_t sampleRate = 16000;
    // 字节率 = sampleRate * blockAlign
    uint32_t byteRate;
    // 一个样本的字节数 = bitsPerSample * numChannels >> 3
    uint16_t blockAlign;
    // 位深度
    uint16_t bitsPerSample = 16;

    /* data chunk */
    // data chunk的id
    uint8_t dataChunkId[4] = {'d', 'a', 't', 'a'};
    // data chunk的data大小：音频数据的总长度，即文件总长度减去文件头的长度(一般是44)
    uint32_t dataChunkDataSize;
} WAVHeader;

@implementation PcmToWav

+ (void)startTransition{
    WAVHeader header = WAVHeader{};
    header.sampleRate = 16000;
    [self pcm2wavWithHeader:header pcmFile:@"/Users/a58/Desktop/audio/chujian.pcm" wavFile:@"/Users/a58/Desktop/audio/cj_xcode.wav"];
}

+(void)pcm2wavWithHeader:(WAVHeader)header pcmFile:(NSString*)pcmFilePath wavFile:(NSString*)wavFilePath {
    
    header.blockAlign = header.bitsPerSample * header.numChannels >> 3;
    header.byteRate = header.sampleRate * header.blockAlign;
    
    NSFileHandle *pcmFileHandle = [NSFileHandle fileHandleForReadingAtPath:pcmFilePath];
    
    if (pcmFileHandle == nil) {
        NSLog(@"文件打开失败");
        return;
    }
    
    header.riffChunkDataSize = header.dataChunkDataSize
                               + sizeof (WAVHeader)
                               - sizeof (header.riffChunkId)
                               - sizeof (header.riffChunkDataSize);
    
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:wavFilePath]) {
        NSError *error;
        BOOL success = [fileManager createFileAtPath:wavFilePath contents:nil attributes:nil];
        if (!success) {
            NSLog(@"创建文件失败: %@", [error localizedDescription]);
        } else {
            NSLog(@"文件创建成功");
        }
    }
    
    NSFileHandle *wavFileHandle = [NSFileHandle fileHandleForWritingAtPath:wavFilePath];
    
    if (wavFileHandle == nil) {
        NSLog(@"文件打开失败");
        return;
    }
    
    // 写入头部
    NSData *data = [NSData dataWithBytes:&header length:sizeof(WAVHeader)];
    [wavFileHandle writeData: data];

    // 写入pcm数据
    char buff[1024];
    BOOL _stop = false;
    while (!_stop) {
        NSData *data = [pcmFileHandle readDataOfLength:sizeof(buff)];
        [wavFileHandle writeData:data];
        _stop = [data length] <= 0;
    }

    // 关闭文件
    [pcmFileHandle closeFile];
    [wavFileHandle closeFile];
}

@end

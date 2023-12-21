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
#import "PlayPCM.h"
#import "RecordPCM.h"
#import "PcmToWav.h"

@interface ViewController()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    NSLog(@"%s", av_version_info());
    
    SDL_version v;
    SDL_VERSION(&v);
    NSLog(@"%hhu,%hhu,%hhu", v.major, v.minor, v.patch);
}

- (IBAction)start:(id)sender {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [RecordPCM record];
    });
}

- (IBAction)play:(id)sender {
    [PlayPCM play];
}

- (IBAction)stop:(id)sender {
    [RecordPCM stop];
}

- (IBAction)pcmToWav:(id)sender {
    
    [PcmToWav startTransition];
}

@end

//
//  AppDelegate.m
//  LearningFFmpeg
//
//  Created by 张雄飞 on 2023/12/16.
//

#import "AppDelegate.h"
#include <libavdevice/avdevice.h>

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    avdevice_register_all(); // 注册所有设备
    
    // Insert code here to initialize your application
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
    return YES;
}


@end

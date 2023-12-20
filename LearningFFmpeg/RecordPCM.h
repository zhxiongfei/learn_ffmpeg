//
//  RecordPCM.h
//  LearningFFmpeg
//
//  Created by 张雄飞 on 2023/12/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RecordPCM : NSObject

+ (void)record;

+ (void)stop;

@end

NS_ASSUME_NONNULL_END

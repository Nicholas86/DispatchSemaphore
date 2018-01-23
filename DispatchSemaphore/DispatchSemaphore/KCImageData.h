//
//  KCImageData.h
//  DispatchSemaphore
//
//  Created by a on 2018/1/22.
//  Copyright © 2018年 a. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KCImageData : NSObject
#pragma mark 索引
@property (nonatomic,assign) int index;

#pragma mark 图片数据
@property (nonatomic,strong) NSData *data;
@end

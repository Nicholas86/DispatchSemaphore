//
//  ViewController.m
//  DispatchSemaphore
//
//  Created by a on 2018/1/22.
//  Copyright © 2018年 a. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self  dispatchSemaphore];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 我们来思考一下这种情况:不考虑顺序,将所有数据追加到NSMutableArray中
 */
- (void)dispatchSemaphore
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    NSMutableArray *array = [[NSMutableArray alloc] init];
    for (int i = 0; i < 100000; i++) {
        dispatch_async(queue, ^{
            NSLog(@"i:%d", i);
            [array addObject:[NSNumber numberWithInt:i]];
        });
    }
}

@end







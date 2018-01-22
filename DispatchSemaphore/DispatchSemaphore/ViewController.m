//
//  ViewController.m
//  DispatchSemaphore
//
//  Created by a on 2018/1/22.
//  Copyright © 2018年 a. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UILabel *semaphoreLabel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //dispatch_apply
    [self  dispatchApply];
    [self  dispatchArray];
    
    //信号量
    //[self  dispatchSemaphore];
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



/*
  dispatchApply:
    dispatchApply函数是dispatch_sync(同步,不要看成异步了)函数和Dispatch Group的关联API。
    该函数按指定的次数将指定的Block追加到指定的Dispatch Queue中,并等待全部处理执行结束。
 */
- (void)dispatchApply
{
    /*
     1.因为在Global Dispatch Queue中执行处理,所以各个处理的执行时间不定。但是输出结果中的NSLog(@"Done")
     必定在最后的位置上。这是因为dispatch_apply函数会等待全部处理执行结束。
     */
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_apply(10, queue, ^(size_t index) {
        NSLog(@"%lu", index);
    });
    
    NSLog(@"Done");
    
}

- (void)dispatchArray
{
    /*
     2.对NSArray类对象的所有元素执行处理时,不必一个一个编写for循环部分。
     */
    
    NSArray *array = @[@"子", @"线", @"程", @"要", @"多", @"用"];
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_apply([array count], queue, ^(size_t index) {
        NSLog(@"%lu, %@", index, [array  objectAtIndex:index]);
    });
    
    //上面源代码可简单地在Global Dispatch Queue中对所有元素执行Block。
    
    
    
    /*
     3.另外, 由于 dispatch_apply函数也与dispatch_sync函数相同, 会等待处理执行结束, 因此推荐在
     dispatch_async函数中非同步地执行dispatch_apply函数。
     */
    
    //在Global Dispatch Queue中非同步执行
    __block NSString *string = nil;
    dispatch_async(queue, ^{
       /*
        Global Dispatch Queue
        等待dispatch_apply函数中全部处理执行结束
        */
        
        dispatch_apply([array count], queue, ^(size_t index) {
            /*
             并列处理包含在NSArray对象的全部对象
             */
            NSLog(@"%lu, %@", index, [array  objectAtIndex:index]);
            if (index == 3) {
                string = [array  objectAtIndex:index];
            }
        });
        
        /*
         dispatch_apply函数中的处理全部执行结束
         */
        
        /*
         在 Main Dispatch Queue中非同步执行
         */
        
        dispatch_async(dispatch_get_main_queue(), ^{
            /*
             在 Main Dispatch Queue中执行处理
             用户界面更新等
             */
            self.semaphoreLabel.text = string;
            NSLog(@"用户界面更新");
        });
        
    });
    
    
}


@end







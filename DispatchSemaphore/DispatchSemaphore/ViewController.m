//
//  ViewController.m
//  DispatchSemaphore
//
//  Created by a on 2018/1/22.
//  Copyright © 2018年 a. All rights reserved.
//

#import "ViewController.h"

#import "KCImageData.h"

#define ROW_COUNT 5
#define COLUMN_COUNT 3
#define ROW_HEIGHT 100
#define ROW_WIDTH ROW_HEIGHT
#define CELL_SPACING 10
#define IMAGE_COUNT 9

#pragma mark 参考文章: https://www.jianshu.com/p/a84c2bf0d77b

@interface ViewController ()
{
    NSMutableArray *_imageViews;
    NSLock *_lock;
}

@property (weak, nonatomic) IBOutlet UILabel *semaphoreLabel;

@property (atomic,strong) NSMutableArray *imageNames;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //dispatch_apply
    //[self  dispatchApply];
    //[self  dispatchArray];
    
    //信号量
    //[self  dispatchSemaphore];
    //保持线程同步
    //[self  dispatchSerialWithSemaphore];
    //为线程加锁
    [self  dispatchLockWithSemaphore];
    
    //线程同步(解决资源抢夺)
    //[self layoutUI];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark 信号量
/*
 首先，我理解的dispatch_semaphore有两个主要应用 ：
 1. 保持线程同步
 2. 为线程加锁 **
 */

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

//1. 保持线程同步
- (void)dispatchSerialWithSemaphore
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    //创建信号量:(默认为0)
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    NSLog(@"semaphore1:%@", semaphore);

    __block int i = 0;
    dispatch_async(queue, ^{
        i = 100;
        NSLog(@"前:%d", i);
        dispatch_semaphore_signal(semaphore);
        NSLog(@"后:%d", i);
    });
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    NSLog(@"i:%d", i);
    NSLog(@"semaphore2:%@", semaphore);
    
    /*
     注释:由于是将block异步添加到一个并行队列里面，所以程序在主线程跃过block直接到dispatch_semaphore_wait这一行，因为semaphore信号量为0，时间值为DISPATCH_TIME_FOREVER，所以当前线程会一直阻塞，直到block在子线程执行到dispatch_semaphore_signal，使信号量+1，此时semaphore信号量为1了，所以程序继续往下执行。这就保证了线程间同步了。
     */
}

//2. 为线程加锁
- (void)dispatchLockWithSemaphore
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    //创建信号量:(默认为1)
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
    
    for (int i = 0; i < 100; i++) {
        dispatch_async(queue, ^{
            // 相当于加锁
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            //主线程刷新UI
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"i = %zd semaphore = %@", i, semaphore);
                self.semaphoreLabel.text = [NSString stringWithFormat:@"%d", i];
            });
            // 相当于解锁
            dispatch_semaphore_signal(semaphore);
        });
    }
    
    NSLog(@"完成啦");
    
    /*
     注释：当线程1执行到dispatch_semaphore_wait这一行时，semaphore的信号量为1，所以使信号量-1变为0，并且线程1继续往下执行；
     如果当在线程1NSLog这一行代码还没执行完的时候，又有线程2来访问，执行dispatch_semaphore_wait时由于此时信号量为0，且时间为DISPATCH_TIME_FOREVER,所以会一直阻塞线程2（此时线程2处于等待状态），直到线程1执行完NSLog并执行完dispatch_semaphore_signal使信号量为1后，线程2才能解除阻塞继续住下执行。
     以上可以保证同时只有一个线程执行NSLog这一行代码。
     */
}


#pragma mark dispatchApply
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


#pragma mark 资源抢夺 && 界面布局 && 加锁

-(void)layoutUI{
    //创建多个图片控件用于显示图片
    _imageViews = [NSMutableArray array];
    
    for (int r = 0; r < 5; r++) {
        for (int c = 0; c < 3; c++) {
            UIImageView *imageView=[[UIImageView alloc]initWithFrame:CGRectMake(c*ROW_WIDTH+(c*CELL_SPACING), r*ROW_HEIGHT+(r*CELL_SPACING), ROW_WIDTH, ROW_HEIGHT)];
            imageView.contentMode = UIViewContentModeScaleAspectFit;
            //imageView.backgroundColor = [UIColor redColor];
            [self.view  addSubview:imageView];
            [_imageViews addObject:imageView];
        }
    }
    
    UIButton *button=[UIButton buttonWithType:UIButtonTypeRoundedRect];
    button.frame=CGRectMake(50, 500, 220, 25);
    [button setTitle:@"加载图片" forState:UIControlStateNormal];
    //添加方法
    [button addTarget:self action:@selector(loadImageWithMultiThread) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    
    //创建图片链接
    _imageNames = [NSMutableArray array];
    for (int i = 0; i < 9; i++) {
        UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"%d.png", i]];
        [_imageNames addObject:image];
    }
    
    //初始化锁对象
    _lock = [[NSLock alloc]init];
    
}

#pragma mark 多线程下载图片
-(void)loadImageWithMultiThread{
    int count = 5 * 3;
    
    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    //创建多个(15)线程用于填充图片
    for (int i = 0; i < count; ++i) {
        //异步执行队列任务
        dispatch_async(globalQueue, ^{
            //NSLog(@"线程编号:%d", i);
            [self loadImage:[NSNumber numberWithInt:i]];
        });
    }
    
}

#pragma mark 加载图片
-(void)loadImage:(NSNumber *)index{
    int i = [index intValue];
    //NSLog(@"线程编号:%d", i);
    //请求数据
    UIImage *data = [self requestData:i];
    //更新UI界面,此处调用了GCD主线程队列的方法
    dispatch_queue_t mainQueue= dispatch_get_main_queue();
    dispatch_async(mainQueue, ^{
        [self updateImageWithData:data andIndex:i];
    });
}

#pragma mark 请求图片数据
-(UIImage *)requestData:(int )index{
    UIImage *data;
        //加锁
        [_lock lock];
    if (_imageNames.count > 0) {
        /*
         不适用:data = [_imageNames objectAtIndex:index];
         因为前面开了15个异步子线程,而图片数组(_imageNames)只有9张图片
         如果根据子线程的编号去图片数组(_imageNames)中取,会造成数组越界。
         越界原因是:子线程是并发的,有可能下标10比下标3先进来,这样下标10就在图片数组(_imageNames)中
         找不到元素,而崩溃。
         */
        data = [_imageNames lastObject];
        [_imageNames  removeObject:data];
    }
        //使用完解锁
        [_lock unlock];
    
    if (data) {
        return data;
    }
    return nil;
}

#pragma mark 将图片显示到界面
-(void)updateImageWithData:(UIImage *)data andIndex:(int )index{
    //NSLog(@"index:%d", index);
    
    /*
     以为是并发执行的,所以
     NSLog(@"index:%d", index);
     打印的下标不一定是按照0,1,2,3,4,5,6,7,8顺序执行的。
     有可能是3,6,2,0,1,5,4,8,7等乱序更新UI的。
    */
    UIImageView *imageView= _imageViews[index];
    imageView.image = data;
}

@end







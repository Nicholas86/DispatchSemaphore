dispatchApply:
    dispatchApply函数是dispatch_sync(同步,不要看成异步了)函数和Dispatch Group的关联API。
    该函数按指定的次数将指定的Block追加到指定的Dispatch Queue中,并等待全部处理执行结束。

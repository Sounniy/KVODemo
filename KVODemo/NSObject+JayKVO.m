//
//  NSObject+JayKVO.m
//  dictionary
//
//  Created by Jaydon on 2019/7/11.
//  Copyright © 2019 Jaydon. All rights reserved.
//

#import "NSObject+JayKVO.h"
#import <objc/runtime.h>
#import <objc/message.h>

NSString *const kJayKVOClassPrefix = @"JayKVOClassPrefix_";
NSString *const kJayKVOAssociatedObservers = @"JayKVOAssociatedObservers";
@interface JayObservationInfo : NSObject
@property (nonatomic , weak)NSObject *oberver;
@property (nonatomic, copy)NSString *key;
@property (nonatomic,copy)JayObservingBlock block;

@end

@implementation JayObservationInfo
- (instancetype)initWithObserver:(NSObject *)observer key:(NSString *)key block:(JayObservingBlock)block
{
    self = [super init];
    if (self) {
        _oberver = observer;
        _key = key;
        _block = block;
    }
    return self;
}

@end



static NSString *getterForSetter(NSString *setter){
    if (setter.length <= 0 || ![setter hasPrefix:@"set"] || ![setter hasSuffix:@":"]) {
        return nil;
    }
    NSRange range = NSMakeRange(3, setter.length - 4);
    NSString *key = [setter substringWithRange:range];
    NSString *firstLetter = [[key substringToIndex:1]lowercaseString];
    key = [key stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:firstLetter];
    return key;
}

static NSString * setterForGetter(NSString *getter){
    if (getter.length <= 0) {
        return nil;
    }
    NSString *firstLetter = [[getter substringToIndex:1]uppercaseString];
    NSString *remainingLetters = [getter substringFromIndex:1];
    NSString *setter = [NSString stringWithFormat:@"set%@%@:",firstLetter,remainingLetters];
    return setter;
    
}

static void kvo_setter(id self, SEL _cmd, id newValue){
    NSString *setterName = NSStringFromSelector(_cmd);
    NSString *getterName =getterForSetter(setterName);
    if (!getterName) {
        NSString *reason = [NSString stringWithFormat:@"Objecrt %@ does not have setter %@",self,setterName];
        return;
    }
    id oldValue = [self valueForKey:getterName];
    struct objc_super superClazz = {
        .receiver = self,
        .super_class = class_getSuperclass(object_getClass(self))
    };
    void (*objc_msgSendSuperCasted)(void *,SEL,id) = (void *)objc_msgSendSuper;
    objc_msgSendSuperCasted(&superClazz,_cmd,newValue);
    NSMutableArray *observersArr = objc_getAssociatedObject(self, (__bridge const void *)(kJayKVOAssociatedObservers));
    for (JayObservationInfo *info in observersArr) {
        if ([info.key isEqualToString:getterName]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                info.block(self, getterName, oldValue, newValue);
            });
        }
    }
    
}


//重写class方法[self class]为原始类;object_getClass(self)为JayKVOClassPrefix_class
static Class kvo_class(id self,SEL _cmd){
    
    return class_getSuperclass(object_getClass(self));
}
@implementation NSObject (JayKVO)
- (void)Jay_addObserver:(NSObject *)observer forKey:(NSString *)key withBlock:(JayObservingBlock)block{
    SEL setterSelector = NSSelectorFromString(setterForGetter(key));
    Method setterMetod = class_getInstanceMethod([self class], setterSelector);
    if (!setterMetod) {
        NSString *reason = [NSString stringWithFormat:@"Object %@ does not have a setter for key %@",self,key];
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:reason userInfo:nil];
        return;
    }
    Class clazz = object_getClass(self);
    NSString *clazzName = NSStringFromClass(clazz);
    if (![clazzName hasPrefix:kJayKVOClassPrefix]) {
        clazz = [self makeKVOClassWithOriginalClassName:clazzName];
        object_setClass(self, clazz);
    }
    if (![self hasSelector:setterSelector]) {
        const char *types = method_getTypeEncoding(setterMetod);
        class_addMethod(clazz, setterSelector, (IMP)kvo_setter, types);
    }
    
    JayObservationInfo *infoObj = [[JayObservationInfo alloc]initWithObserver:observer key:key block:block];
    NSMutableArray *observersArr = objc_getAssociatedObject(self, (__bridge const void *)(kJayKVOAssociatedObservers));
    if (!observersArr) {
        observersArr = [NSMutableArray array];
        objc_setAssociatedObject(self, (__bridge const void *)(kJayKVOAssociatedObservers), observersArr, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    [observersArr addObject:infoObj];
    
}
- (Class)makeKVOClassWithOriginalClassName:(NSString *)originClazzName{
    NSString *KVOClassName = [kJayKVOClassPrefix stringByAppendingString:originClazzName];
    Class KVOClass = NSClassFromString(KVOClassName);
    if (KVOClass) {
        return KVOClass;
    }
    Class originalClass = object_getClass(self);
    //开辟内存空间
    KVOClass = objc_allocateClassPair(originalClass, KVOClassName.UTF8String, 0);
    Method classMethod = class_getInstanceMethod(originalClass, @selector(class));
    const char *types = method_getTypeEncoding(classMethod);
    //重写class方法
    class_addMethod(KVOClass, @selector(class),(IMP)kvo_class,types);
    //注册类信息
    objc_registerClassPair(KVOClass);
    return KVOClass;
}
- (void)Jay_removeObserver:(NSObject *)observer forKey:(NSString *)key {
    NSMutableArray *observersArr = objc_getAssociatedObject(self, (__bridge const void *)(kJayKVOAssociatedObservers));
    for (JayObservationInfo *info in observersArr) {
        if (info.oberver == observer && [info.key isEqual:key]) {
            [observersArr removeObject:info];
            break;
        }
    }
}

- (BOOL)hasSelector:(SEL)selector{
    Class clazz = object_getClass(self);
    unsigned int methodNum = 0;
    Method *methodList = class_copyMethodList(clazz, &methodNum);
    for (unsigned int i = 0; i < methodNum; i++) {
        SEL thisSelector = method_getName(methodList[i]);
        if (thisSelector == selector) {
            free(methodList);
            return YES;
        }
        
    }
    
    free(methodList);
    return NO;
}


@end

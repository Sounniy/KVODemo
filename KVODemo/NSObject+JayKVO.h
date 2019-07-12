//
//  NSObject+JayKVO.h
//  dictionary
//
//  Created by Jaydon on 2019/7/11.
//  Copyright © 2019 Jaydon. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef void(^JayObservingBlock)(id observedObj,NSString *obsevedKey,id oldValue,id newValue);

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (JayKVO)
- (void)Jay_addObserver:(NSObject *)observer forKey:(NSString *)key withBlock:(JayObservingBlock)block;
- (void)Jay_removeObserver:(NSObject *)observer forKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END

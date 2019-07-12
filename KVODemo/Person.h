//
//  Person.h
//  KVODemo
//
//  Created by qinjiandong on 2019/7/12.
//  Copyright © 2019 qinjiandong. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Person : NSObject
@property (nonatomic,copy)NSString *name;
@property (nonatomic,assign)NSInteger age;
@property (nonatomic,assign)NSInteger sex;

@end

NS_ASSUME_NONNULL_END

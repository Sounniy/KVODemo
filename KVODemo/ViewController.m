//
//  ViewController.m
//  KVODemo
//
//  Created by Jaydon on 2019/7/12.
//  Copyright © 2019 Jaydon. All rights reserved.
//

#import "ViewController.h"
#import "Person.h"
#import "NSObject+JayKVO.h"

@interface ViewController ()
@property(nonatomic,strong)Person *person;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    Person *person = [Person new];
    
    self.person = person;
    [self.person Jay_addObserver:self forKey:@"name" withBlock:^(id observedObj, NSString *obsevedKey, id oldValue, id newValue) {
        NSLog(@"oldValue:%@,newValue:%@,key:%@",oldValue,newValue,obsevedKey);
    }];
    
}


@end

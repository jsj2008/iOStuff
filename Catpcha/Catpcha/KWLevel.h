//
//  KWField.h
//  Catpcha
//
//  Created by Mason on 7/17/12.
//  Copyright (c) 2012 Masonsoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KWObject.h"

@class KWObject, KWKitten;

@interface KWLevel : CAShapeLayer

@property (nonatomic, readonly, assign) int level;
@property (nonatomic, readonly, assign) NSUInteger timelimit;
@property (nonatomic, readonly, strong) NSArray* objects;
@property (nonatomic, readonly, strong) NSArray* kittens;

@property (nonatomic, assign) CGPoint bias;

- (id) initLevel:(int)lvl;

- (void) tick:(CGFloat)dt;

- (NSArray*) sight:(KWObject*)obj;

- (NSTimeInterval) remaining;

- (BOOL) complete;

- (void) drop:(KWObject*)object;

- (BOOL) vacant:(CGPoint)rect excluding:(KWObject*)obj;

- (NSArray*) touched:(CGPoint)point;

@end
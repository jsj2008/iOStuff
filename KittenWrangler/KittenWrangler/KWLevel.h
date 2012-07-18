//
//  KWField.h
//  KittenWrangler
//
//  Created by Mason on 7/17/12.
//  Copyright (c) 2012 Masonsoft. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KWObject;

@interface KWLevel : NSObject

@property (nonatomic, readonly, assign) NSUInteger level;
@property (nonatomic, readonly, assign) CGRect bounds;

@property (nonatomic, readonly, strong) NSArray* baskets;
@property (nonatomic, readonly, strong) NSArray* kittens;
@property (nonatomic, readonly, strong) NSArray* toys;

- (id) initLevel:(NSUInteger)lvl;

- (void) tick:(CGFloat)dt;

- (NSArray*) visible:(KWObject*)obj;

- (BOOL) complete;

@end

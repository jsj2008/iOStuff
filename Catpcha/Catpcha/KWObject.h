//
//  KWObject.h
//  Catpcha
//
//  Created by Mason Glaves on 7/8/12.
//  Copyright (c) 2012 Masonsoft. All rights reserved.
//

#import "KWRectangle.h"

@class KWLevel;

typedef enum {
    KWObjectTypeBasket,
    KWObjectTypeKitten,
    KWObjectTypeMouse,
    KWObjectTypeYarn,
} KWObjectType;

typedef enum {
    KWObjectVelocityMotionless = 0,
    KWObjectVelocityVerySlow   = 15,
    KWObjectVelocitySlow       = 100,
    KWObjectVelocityAverage    = 200,
    KWObjectVelocityFast       = 250,
    KWObjectVelocityVeryFast   = 350,
} KWObjectVelocity;

@interface KWObject : KWRectangle

@property (nonatomic, assign) unsigned char oid;
@property (nonatomic, assign) KWObjectType type;

@property (nonatomic, assign) CGFloat allure;

@property (nonatomic, assign) BOOL touchable;
@property (nonatomic, assign) BOOL catchable;

@property (nonatomic, weak) UITouch* touch;
@property (nonatomic, readonly, weak) KWLevel* level;
@property (nonatomic, assign) CGFloat heading;
@property (nonatomic, assign) KWObjectVelocity velocity;

- (id) initWithLevel:(KWLevel*)lvl andSize:(CGSize)size;

//xxxz - (UIBezierPath*) shape;

- (BOOL) moving;

- (BOOL) tick:(CGFloat)dt;

- (CGFloat) direction:(KWObject*)other;

- (void) grab;
- (void) drop;


@end

//
//  KWYarn.m
//  Catpcha
//
//  Created by Mason Glaves on 7/8/12.
//  Copyright (c) 2012 Masonsoft. All rights reserved.
//

#import "KWYarn.h"
#import "KWLevel.h"
#import "KWKitten.h"

#define KWRollTime 10.0f;

@implementation KWYarn {
    NSDate* start;
    CGFloat roll;
}

- (id) initWithLevel:(KWLevel*)lvl {
    if (self = [super initWithLevel:lvl andSize:KWYarnSize]) {
        self.type = KWObjectTypeYarn;
//xxxz        
//        self.strokeColor = nil;//[UIColor cyanColor].CGColor;
//        self.fillColor = [UIColor colorWithRed:0.2f green:0.1f blue:0.8f alpha:0.5f].CGColor;
        self.touchable = YES;
        self.catchable = NO;        
        self.allure = 0.05f;
    }
    return self;
}

//xxxz- (UIBezierPath*) shape { return [UIBezierPath bezierPathWithOvalInRect:self.bounds]; }

- (void) grab {
    start = [NSDate date];    
}

- (void) drop {
    roll = [[NSDate date] timeIntervalSinceDate:start] * KWRollTime;
    start = nil;        
    self.velocity = KWObjectVelocityFast;
}

- (BOOL) tick:(CGFloat)dt {
//xxxz    
//    CGSize size = self.bounds.size;
//    if (size.width < KWMinToySize.width || size.height < KWMinToySize.height) {
//        self.fillColor = UIColor.cyanColor.CGColor;
//        self.catchable = YES;
//        self.touchable = NO;
//    } else {
//        roll -= dt;
//        if (roll < 0 || self.velocity < dt) {
//            self.velocity = KWObjectVelocityMotionless;
//        } else {
//            self.velocity -= dt;
//            [self shrink:dt];
//        }
//    }
//    
//    if (self.moving) {
//        [self.level.kittens enumerateObjectsUsingBlock:^(KWKitten* kitten, NSUInteger idx, BOOL *stop) {
//            [kitten show:self];
//        }];
//    }
//    
//    return [super tick:dt];
}

- (void) shrink:(CGFloat)dt {
//xxxz    
//    self.transform = CATransform3DIdentity;
//    self.frame = CGRectInset(self.frame, dt, dt);
//    self.path = self.shape.CGPath;
}

@end

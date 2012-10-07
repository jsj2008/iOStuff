//
//  NSData+LL.h
//  LL
//
//  Created by Mason on 10/7/12.
//  Copyright (c) 2012 CasuaLlama. All rights reserved.
//

@interface NSData (LL)

- (BOOL) empty;
- (NSUInteger) count;
- (NSUInteger) size;

+ (NSData *)dataFromBase64String:(NSString *)aString;
- (NSString *)base64EncodedString;

- (NSString*) MD5Hash;

@end

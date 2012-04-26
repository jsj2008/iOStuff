//
//  MaSONKit.m
//  MaSONKit
//
//  Created by Mason Glaves on 4/24/12.
//  Copyright (c) 2012 Masonsoft. All rights reserved.
//

#import "MaSONKit.h"

#define MaInitialCapacity 32

static NSUInteger arrayCapacityWindow = MaInitialCapacity;
static NSUInteger hashCapacityWindow = MaInitialCapacity;

typedef enum { MaNullType, MaBoolType, MaStringType, MaNumberType, MaArrayType, MaHashType } MaType;

typedef struct { 
    MaType type; 
} MaNull;

typedef struct { 
    MaType type; 
    BOOL value; 
} MaBool;

typedef struct { 
    MaType type; 
    NSUInteger start; 
    NSUInteger length; 
} MaString;

typedef struct { 
    MaType type; 
    NSUInteger start;           
    NSUInteger length;                             
} MaNumber;

typedef struct { 
    MaType type; 
    NSUInteger capacity;               
    NSUInteger length; 
    union MaObjectU** items; 
} MaArray;

typedef struct { 
    MaType type; 
    NSUInteger capacity; 
    NSUInteger length; 
    MaString** keys; 
    union MaObjectU** values; 
} MaHash;

typedef union MaObjectU { MaNull null; MaBool b; MaString s; MaNumber n; MaArray a; MaHash h; } MaObject;

static const MaNull Mnull  = { MaNullType        };
static const MaBool Mtrue  = { MaBoolType, true  };
static const MaBool Mfalse = { MaBoolType, false };

static inline MaString* MaStringMake(const NSUInteger start, const NSUInteger length) { 
    MaString* s = malloc(sizeof(MaString));
    s->type = MaStringType; 
    s->start = start; 
    s->length = length; 
    return s;
}

static inline MaNumber* MaNumberMake(const NSUInteger start, const NSUInteger length) { 
    MaNumber* n = malloc(sizeof(MaNumber));
    n->type = MaNumberType; 
    n->start = start; 
    n->length = length; 
    return n;
}

static inline MaArray* MaArrayMake() { 
    MaArray* a  = malloc(sizeof(MaArray));
    a->type     = MaArrayType;
    a->capacity = arrayCapacityWindow;    
    a->items    = malloc(a->capacity * sizeof(MaObject)); 
    a->length   = 0;
    return a;
}

static inline MaHash* MaHashMake() { 
    MaHash* h   = malloc(sizeof(MaHash));
    h->type     = MaHashType;
    h->capacity = hashCapacityWindow;    
    h->keys     = malloc(h->capacity * sizeof(MaString*));
    h->values   = malloc(h->capacity * sizeof(MaObject*)); 
    h->length   = 0;
    return h;
}

static inline void MaSet(MaObject* const o, MaString* const key, MaObject* const value) {
    
    switch (o->null.type) {
        case MaHashType:
            if (o->h.length == o->h.capacity) {
                o->h.capacity *= 2;
                hashCapacityWindow = MAX(hashCapacityWindow, o->h.capacity);                
                o->h.keys = realloc(o->h.keys, o->h.capacity * sizeof(MaString*));
                o->h.values = realloc(o->h.values, o->h.capacity * sizeof(MaObject*)); 
            }
            
            o->h.keys[o->h.length] = key;            
            o->h.values[o->h.length] = value;        
            o->h.length++;                            
            break;
        case MaArrayType:
            if (o->a.length == o->a.capacity) {
                o->a.capacity *= 2;
                arrayCapacityWindow = MAX(arrayCapacityWindow, o->h.capacity);
                o->a.items = realloc(o->a.items, o->a.capacity * sizeof(MaObject)); 
            }
            
            o->a.items[o->a.length++] = value;                                                
            break;
        default:
            break;
    }    
    
}

static void MaFree(MaObject* const o) {
  
    switch (o->null.type) {
        case MaHashType:
            
            for (int i=0;i < o->h.length;i++) {
                MaFree((MaObject*)o->h.keys[i]);
                MaFree(o->h.values[i]);
            }
            
            free(o->h.keys);
            free(o->h.values);
            
            free(o);
            
            break;
        case MaArrayType:
            for (int i =0;i<o->a.length;i++) {
                MaFree(o->a.items[i]);
            }
            free(o->a.items);
            free(o);
            break;
        case MaNumberType:
        case MaStringType:
            free(o);
            break;
        default:
            break;
    }    
    
}

@interface MaEnumerator : NSEnumerator
@end
@interface MaNumberWrapper: NSNumber
- (id) initWithMaObject:(MaObject*)obj andData:(NSData*)d;
@end
@interface MaStringWrapper: NSString
- (id) initWithMaObject:(MaObject*)obj andData:(NSData*)d;
@end
@interface MaArrayWrapper: NSArray
- (id) initWithMaObject:(MaObject*)obj andData:(NSData*)d;
@end
@interface MaDictionaryWrapper: NSDictionary
- (id) initWithMaObject:(MaObject*)obj andData:(NSData*)d;
@end

inline static id NSObjectFromMaObject(MaObject* o, NSData* backing) {
    
    if (o == nil) { return nil; }
    
    switch (o->null.type) {
        case MaNullType:
            return nil;
        case MaBoolType:   
        case MaNumberType:
            return [[MaNumberWrapper alloc] initWithMaObject:o andData:backing];
        case MaStringType: 
            return [[MaStringWrapper alloc] initWithMaObject:o andData:backing];
        case MaArrayType: 
            return [[MaArrayWrapper alloc] initWithMaObject:o andData:backing];
        case MaHashType:  
            return [[MaDictionaryWrapper alloc] initWithMaObject:o andData:backing];
    }    
}

@implementation MaEnumerator { NSUInteger at; MaObject* wrapped; NSData* data; }
- (id) initWithMaObject:(MaObject*)obj andData:(NSData*)d {
    if (self = [super init]) { at = 0; wrapped = obj; data = d; }
    return self;
}
- (id) nextObject {    
    switch (wrapped->null.type) {
        case MaArrayType: 
            return (at < wrapped->a.length) ? NSObjectFromMaObject((MaObject*)wrapped->a.items[at++], data) : nil;                                
        case MaHashType:  
            return (at < wrapped->h.length) ? NSObjectFromMaObject((MaObject*)wrapped->h.keys[at++], data) : nil;                
        default:
            return nil;
    }    
}
@end

@implementation MaNumberWrapper { NSNumber* wrapped; }
- (id) initWithMaObject:(MaObject*)obj andData:(NSData*)d {
    if (self = [super init]) {         
        if (obj->n.type == MaBoolType) {
            wrapped = [NSNumber numberWithBool:obj->b.value];
        } else {
            NSString* num = [[NSString alloc] initWithData:[d subdataWithRange:NSMakeRange(obj->n.start, obj->n.length)] encoding:NSUTF8StringEncoding];            
            if ([num rangeOfString:@"."].location == NSNotFound) {
                wrapped = [NSNumber numberWithInt:[num intValue]];                                    
            } else {
                wrapped = [NSNumber numberWithDouble:[num doubleValue]];                                                    
            }            
        }        
    }
    return self;
}
- (void)getValue:(void *)value { [wrapped getValue:value]; }
- (const char *)objCType { return [wrapped objCType]; }
- (NSString*) description { return [wrapped description]; }
- (NSString*) descriptionWithLocale:(id)locale { return [wrapped descriptionWithLocale:locale]; }
@end

@implementation MaStringWrapper { NSString* wrapped; }
- (id) initWithMaObject:(MaObject*)obj andData:(NSData*)d {
    if (self = [super init]) { 
        wrapped = [[NSString alloc] initWithData:[d subdataWithRange:NSMakeRange(obj->s.start, obj->s.length)] encoding:NSUTF8StringEncoding];            
    }
    return self;
}
- (NSUInteger)length { return [wrapped length]; }
- (unichar)characterAtIndex:(NSUInteger)index { return [wrapped characterAtIndex:index]; }
- (NSString*) description { return [wrapped description]; }
@end

@implementation MaArrayWrapper { MaObject* wrapped; NSData* data; }
- (id) initWithMaObject:(MaObject*)obj andData:(NSData*)d {
    if (self = [super init]) { wrapped = obj; data = d; }
    return self;
}
- (NSUInteger)count { return wrapped->h.length; }
- (id)objectAtIndex:(NSUInteger)index { return NSObjectFromMaObject(wrapped->a.items[index], data); }
@end

@implementation MaDictionaryWrapper { BOOL root; MaObject* wrapped; NSData* data; }
- (id) initRootWithMaObject:(MaObject*)obj andData:(NSData*)d {
    if (self = [super init]) { root = YES; wrapped = obj; data = d; }
    return self;
}
- (id) initWithMaObject:(MaObject*)obj andData:(NSData*)d {
    if (self = [super init]) { root = NO; wrapped = obj; data = d; }
    return self;
}
//xxx - (void) dealloc { if (root) { MaFree(wrapped); } }
- (NSUInteger)count { return wrapped->h.length; }
- (NSEnumerator*) keyEnumerator { return [[MaEnumerator alloc] initWithMaObject:wrapped andData:data]; }
- (id) objectForKey:(id)key {
    for (int i = 0; i < wrapped->h.length; i++) {
        NSString* k = NSObjectFromMaObject((MaObject*)wrapped->h.keys[i], data);
        if ([k isEqualToString:key]) { return NSObjectFromMaObject(wrapped->h.values[i], data); }
    }
    return nil;
}
@end

@implementation MaSONKit

static const char* bytes;
static NSUInteger length;
static NSUInteger pos;
static MaObject* root;

static inline void fill(MaObject* const object) {
    
    MaObject* value;
    
    register NSUInteger start;
    register MaType type = object->null.type;
    
    MaString* key = nil;
    
    for (;pos < length; pos++) {
        switch (bytes[pos]) {         
            case 93:
            case 125:
                return;                
                
            case 34: 
                start = ++pos;
                for (;bytes[++pos] != 34;) { 
                    if (bytes[pos] == 92) { ++pos; } else if (bytes[pos] > 127) { ++pos; if (bytes[pos] > 127) { ++pos; if (bytes[pos] > 127) { pos += 2; } } }
                }
                
                if (key == nil && type == MaHashType) {
                    key = MaStringMake(start, pos - start);                                       
                    for (;bytes[++pos] != 58;);
                } else {
                    MaSet(object, key, (MaObject*)MaStringMake(start, pos - start)); 
                    key = nil;
                }                                                
                break;  
                
            case 45:
            case 46:
            case 48:
            case 49:
            case 50:
            case 51:
            case 52:
            case 53:
            case 54:
            case 55:
            case 56:
            case 57: 
                start = pos;
                for (;bytes[pos] >= 45 && bytes[pos] <= 57;++pos);                
                MaSet(object, key, (MaObject*)MaNumberMake(start, pos - start));                      
                key = nil;
                break;   
                
            case 123:            
                ++pos;
                value = (MaObject*)MaHashMake();     
                MaSet(object, key, value);
                fill(value); 
                key = nil;
                break;            
                
            case 91: 
                ++pos;
                value = (MaObject*)MaArrayMake();
                MaSet(object, key, value);
                fill(value); 
                key = nil;
                break;                            
                
            case 110:
                pos += 3;
                MaSet(object, key, (MaObject*)&Mnull);
                key = nil;
                break;
                
            case 116:
                pos += 3;
                MaSet(object, key, (MaObject*)&Mtrue);
                key = nil;
                break;
                
            case 102:
                pos += 4;
                MaSet(object, key, (MaObject*)&Mfalse);
                key = nil;
                break;
                
        }        
    }
}

+ (NSDictionary*) parse:(NSData*)data {
        
    bytes = [data bytes];
    length = [data length];
    for (pos = 0;bytes[pos++] != '{';);
    root = (MaObject*)MaHashMake();
    
    fill(root);        
            
    bytes = nil;
    length = 0;
    pos = 0;
    
    return [[MaDictionaryWrapper alloc] initRootWithMaObject:root andData:data];        
}

+ (void) freeRoot {
    if (root != nil) {
        MaFree(root);
    }
    root = nil;
}

@end


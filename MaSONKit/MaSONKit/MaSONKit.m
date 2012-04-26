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

static inline MaString* MaStringMake(NSUInteger start, NSUInteger length) { 
    MaString* s = malloc(sizeof(MaString));
    s->type = MaStringType; 
    s->start = start; 
    s->length = length; 
    return s;
}

static inline MaNumber* MaNumberMake(NSUInteger start, NSUInteger length) { 
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

static inline void MaSet(MaObject* o, MaString* key, MaObject* value) {
    
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

static void MaFree(MaObject* o) {
  
//xxx do this better    
//    switch (o->null.type) {
//        case MaHashType:
//            
//            for (int i=0;i < o->h.length;i++) {
//                MaFree((MaObject*)o->h.keys[i]);
//                MaFree(o->h.values[i]);
//            }
//            
//            free(o->h.keys);
//            free(o->h.values);
//            
//            free(o);
//            
//            break;
//        case MaArrayType:
//            for (int i =0;i<o->a.length;i++) {
//                MaFree(o->a.items[i]);
//            }
//            free(o->a.items);
//            free(o);
//            break;
//        case MaNumberType:
//        case MaStringType:
//            free(o);
//            break;
//        default:
//            break;
//    }    
    
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
- (void) dealloc { MaFree(wrapped); wrapped = nil; data = nil; }
- (NSUInteger)count { return wrapped->h.length; }
- (id)objectAtIndex:(NSUInteger)index { return NSObjectFromMaObject(wrapped->a.items[index], data); }
@end

@implementation MaDictionaryWrapper { MaObject* wrapped; NSData* data; }
- (id) initWithMaObject:(MaObject*)obj andData:(NSData*)d {
    if (self = [super init]) { wrapped = obj; data = d; }
    return self;
}
- (void) dealloc { MaFree(wrapped); wrapped = nil; data = nil; }
- (NSUInteger)count { return wrapped->h.length; }
- (id) objectForKey:(id)key {
    
    for (int i = 0; i < wrapped->h.length; i++) {
        NSString* k = NSObjectFromMaObject((MaObject*)wrapped->h.keys[i], data);
        if ([k isEqualToString:key]) { return NSObjectFromMaObject(wrapped->h.values[i], data); }
    }
    
    return nil;
}

- (NSEnumerator*) keyEnumerator { return [[MaEnumerator alloc] initWithMaObject:wrapped andData:data]; }

@end

@implementation MaSONKit

static const char* bytes;
static NSUInteger length;
static NSUInteger pos;

static void fill(MaObject* object) {
    
    MaObject* value;
    
    char c;
    register NSUInteger start;
    register MaType type = object->null.type;

    MaString* key = nil;
    
    for (; pos < length; pos++) {
        switch (bytes[pos]) {         
            case ']':
            case '}':
                return;                
                
            case '"': 
                start = ++pos;
                for (;(c = bytes[pos]) != '"';pos++) { 
                    if (c == '\\') { pos++; } else if (c > 127) { pos++; if (bytes[pos] > 127) { pos++; if (bytes[pos] > 127) { pos += 2; } } }
                }
                
                if (key == nil && type == MaHashType) {
                    key = MaStringMake(start, pos - start);                                       
                    for (;bytes[pos] != ':';pos++);
                } else {
                    MaSet(object, key, (MaObject*)MaStringMake(start, pos - start)); 
                    key = nil;
                }                                                
                break;  
            
            case '-':
            case '.':
            case '0':
            case '1':
            case '2':
            case '3':
            case '4':
            case '5':
            case '6':
            case '7':
            case '8':
            case '9': 
                start = pos;
                for (;'-' < (c = bytes[pos]) && c <= '9';pos++);                
                MaSet(object, key, (MaObject*)MaNumberMake(start, pos - start));                      
                key = nil;
                break;   
                
            case 'n':
                pos += 3;
                MaSet(object, key, (MaObject*)&Mnull);
                key = nil;
                break;
                
            case 't':
                pos += 3;
                MaSet(object, key, (MaObject*)&Mtrue);
                key = nil;
                break;
                
            case 'f':
                pos += 4;
                MaSet(object, key, (MaObject*)&Mfalse);
                key = nil;
                break;
                
            case '{':            
                pos++;
                value = (MaObject*)MaHashMake();     
                MaSet(object, key, value);
                fill(value); 
                key = nil;
                break;            
            
            case '[': 
                pos++;
                value = (MaObject*)MaArrayMake();
                MaSet(object, key, value);
                fill(value); 
                key = nil;
                break;                            
        }        
    }
}

+ (NSDictionary*) parse:(NSData*)data {
        
    bytes = [data bytes];
    length = [data length];
    for (pos = 0;bytes[pos] != '{';pos++);
    pos++;
    
    MaObject* root = (MaObject*)MaHashMake();
    
    fill(root);
            
    bytes = nil;
    length = 0;
    pos = 0;
    
    return NSObjectFromMaObject(root, data);
    
}

@end



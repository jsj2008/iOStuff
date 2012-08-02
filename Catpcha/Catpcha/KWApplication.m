//
//  KWApplication.m
//  Catpcha
//
//  Created by Mason on 8/2/12.
//  Copyright (c) 2012 Masonsoft. All rights reserved.
//

#import "KWApplication.h"

#include <sys/socket.h>
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>

#import "SSKeychain.h"

#define kKWUDIDService @"org.casuallama.UDID.v1"
#define kKWUDIDAccount @"catpcha"

@implementation KWApplication

+ (NSString*) deviceID {
    
    static NSString* udid;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        udid = [SSKeychain passwordForService:kKWUDIDService account:kKWUDIDAccount];
        if (udid == nil) {
            NSDictionary* info = [[NSBundle mainBundle] infoDictionary];
            NSString* app = [info objectForKey:@"CFBundleDisplayName"];
            NSString* version = [info objectForKey:@"CFBundleShortVersionString"];
            NSString* build = [info objectForKey:@"CFBundleVersion"];
            
            NSString* xudid = [NSString stringWithFormat:@"[%@] %@/(%@) %@", app, version, build, [self mac]];
            [SSKeychain setPassword:xudid forService:kKWUDIDService account:kKWUDIDAccount];
        }
        
    });
    return udid;
    
}

+ (NSString*) mac {
    int                 mgmtInfoBase[6];
    char                *msgBuffer = NULL;
    size_t              length;
    unsigned char       macAddress[6];
    struct if_msghdr    *interfaceMsgStruct;
    struct sockaddr_dl  *socketStruct;
    NSString            *errorFlag = NULL;
    
    // Setup the management Information Base (mib)
    mgmtInfoBase[0] = CTL_NET;        // Request network subsystem
    mgmtInfoBase[1] = AF_ROUTE;       // Routing table info
    mgmtInfoBase[2] = 0;
    mgmtInfoBase[3] = AF_LINK;        // Request link layer information
    mgmtInfoBase[4] = NET_RT_IFLIST;  // Request all configured interfaces
    
    // With all configured interfaces requested, get handle index
    if ((mgmtInfoBase[5] = if_nametoindex("en0")) == 0)
        errorFlag = @"if_nametoindex failure";
    else
    {
        // Get the size of the data available (store in len)
        if (sysctl(mgmtInfoBase, 6, NULL, &length, NULL, 0) < 0)
            errorFlag = @"sysctl mgmtInfoBase failure";
        else
        {
            // Alloc memory based on above call
            if ((msgBuffer = malloc(length)) == NULL)
                errorFlag = @"buffer allocation failure";
            else
            {
                // Get system information, store in buffer
                if (sysctl(mgmtInfoBase, 6, msgBuffer, &length, NULL, 0) < 0)
                    errorFlag = @"sysctl msgBuffer failure";
            }
        }
    }
    
    // Befor going any further...
    if (errorFlag != NULL)
    {
        NSLog(@"Error: %@", errorFlag);
        return errorFlag;
    }
    
    // Map msgbuffer to interface message structure
    interfaceMsgStruct = (struct if_msghdr *) msgBuffer;
    
    // Map to link-level socket structure
    socketStruct = (struct sockaddr_dl *) (interfaceMsgStruct + 1);
    
    // Copy link layer address data in socket structure to an array
    memcpy(&macAddress, socketStruct->sdl_data + socketStruct->sdl_nlen, 6);
    
    // Read from char array into a string object, into traditional Mac address format
    NSString *macAddressString = [NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X",
                                  macAddress[0], macAddress[1], macAddress[2],
                                  macAddress[3], macAddress[4], macAddress[5]];
    
    // Release the buffer memory
    free(msgBuffer);
    
    return macAddressString;
}


@end

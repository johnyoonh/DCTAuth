//
//  DCTAuth.h
//  DCTAuth
//
//  Created by Daniel Tull on 25/08/2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DCTAuthAccount.h"
#import "DCTAuthAccountStore.h"
#import "DCTAuthRequest.h"

@interface DCTAuth
/**  */
+ (BOOL)handleURL:(NSURL *)URL;
@end

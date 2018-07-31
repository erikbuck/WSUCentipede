//
//  WSUCentipede.h
//  WSUCentipede
//
//  Created by Erik Buck on 6/16/16.
//  Copyright © 2016 WSU. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WSUBoard;
@class SKSpriteNode;

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////
@interface WSUCentipede : NSObject

@property (nonatomic, readonly) NSArray *segments;

- (void)advanceInBoard:(WSUBoard *)aBoard;
- (WSUCentipede *)truncateAtNode:(SKSpriteNode *)aNode;

@end

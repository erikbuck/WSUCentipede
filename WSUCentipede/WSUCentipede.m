//
//  WSUCentipede.m
//  WSUCentipede
//
//  Created by Erik Buck on 6/16/16.
//  Copyright © 2016 WSU. All rights reserved.
//

#import "WSUCentipede.h"
#import "WSUBoard.h"
#import <SpriteKit/SpriteKit.h>

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////
@interface WSUCentipede ()

@property (nonatomic) float xDirection; //< direction of lateral motion (-1 or 1)
@property (nonatomic) float yDirection; //< direction of vertical motion (-1 or 1)
@property (nonatomic, readwrite) NSArray *segments; //< Segments composing the centipede

@end

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////
@implementation WSUCentipede

//////////////////////////////////////////////////////////////////////
/// Initializes a centipede with default segments and a default motion
/// direction.
- init;
{
   if(nil != (self = [super init]))
   {
       self.xDirection = 1.0f;
       self.yDirection = -1.0f;
       self.segments = @[[WSUBoard makeHeadSegment],
           [WSUBoard makeBodySegment],
           [WSUBoard makeBodySegment],
           [WSUBoard makeBodySegment],
           [WSUBoard makeBodySegment],
           [WSUBoard makeBodySegment],
           [WSUBoard makeBodySegment],
           [WSUBoard makeBodySegment],
           [WSUBoard makeBodySegment],
           [WSUBoard makeTailSegment]];
   }
   
   return self;
}

//////////////////////////////////////////////////////////////////////
/// Initializes a new centipede with the specified segments from c and
/// the same motion direction as c.
- initWithSegments:(NSArray *)someSegments
    ofCentipede:(WSUCentipede *)c;
{
   if(nil != (self = [super init]))
   {
       self.xDirection = c.xDirection;
       self.yDirection = c.yDirection;
       self.segments = someSegments;
   }
   
   return self;
}

//////////////////////////////////////////////////////////////////////
/// Call this method to move the head. The head stays in teh visible
/// portion of the board, reverses direction when blocked, and in the
/// case that no direction of movement avoids a blockage, the head
/// will actually destroy a blocking mushroom.
///
/// This method calls itself again after each move to produce ongoing
/// motion and animation.
///
/// Do not call this method if the receiver has no segments.
- (void)moveHeadInBoard:(WSUBoard *)aBoard;
{   // try moving horizontal in same direction as prior move
    static const float preferredHeightCeiling = 10.0f; //< Arbitrary
    SKSpriteNode *head = self.segments[0];
    
    head.position = CGPointMake(
        MIN(MAX(0, head.position.x), WSUBoardWidth - 1),
        MIN(MAX(0, head.position.y), WSUBoardHeight - 1));
    
    CGPoint candidatePosition = CGPointMake(
        floorf(head.position.x + self.xDirection),
        floorf(head.position.y));
    if(![aBoard isPositionAvailable:candidatePosition])
    {   // flip horizontal direction
        self.xDirection *= -1.0f;
        head.xScale = fabs(head.xScale) * self.xDirection;
        
        // try moving vertical in same direction as last vertical move
        candidatePosition = CGPointMake(
            floorf(head.position.x),
            floorf(head.position.y + self.yDirection));

        if(![aBoard isPositionAvailable:candidatePosition])
        {   // Last resort:
            self.yDirection = (head.position.y < 2) ? 1.0f : -1.0f;
            
            candidatePosition = CGPointMake(
                floorf(head.position.x + self.xDirection),
                floorf(head.position.y + self.yDirection));
            [aBoard destroyMushroomAt:candidatePosition];
        }
    }
    
    if(candidatePosition.y > preferredHeightCeiling)
    {   // Centipede wants to head back below preferredHeightCeiling
        self.yDirection = -1.0f;
    }
    
    [head runAction:[SKAction moveTo:candidatePosition
       duration:aBoard.updatePeriodSeconds] completion:^{
        [self advanceInBoard:aBoard];
    }];
}

//////////////////////////////////////////////////////////////////////
/// Call this method to move the head and then make every other
/// segment follow the preceiding segment.
- (void)advanceInBoard:(WSUBoard *)aBoard;
{
    if(0 < self.segments.count)
    {
        [self moveHeadInBoard:aBoard];
        
        // Make non-head segments follow the leader
        SKSpriteNode *segment = self.segments[self.segments.count-1];
    
        for(NSInteger i = self.segments.count - 2; i >= 0; --i)
        {
            SKSpriteNode *nextSegment = self.segments[i];
            [segment runAction:[SKAction moveTo:nextSegment.position
                duration:aBoard.updatePeriodSeconds]];
            [segment runAction:[SKAction sequence:@[
                [SKAction waitForDuration:0.5 *
                aBoard.updatePeriodSeconds],
                [SKAction scaleXTo:nextSegment.xScale duration:0]]]];
            segment = nextSegment;
        }
    }
}

//////////////////////////////////////////////////////////////////////
/// Reduce the centipede to the segments if any between the head and
/// aNode not including aNode. It is possible for the receiver to have
/// no remaining segments after this call.
/// If there are no segments remaining between aNode and the tail
/// (not including aNode), this method returns nil.  Otherwise, this
/// method returns a new centipede containing any remaining segments
/// between aNode and the tail not including aNode.
- (WSUCentipede *)truncateAtNode:(SKSpriteNode *)aNode;
{
    WSUCentipede *result = nil;
    NSInteger index = [self.segments indexOfObject:aNode];
    if(NSNotFound != index)
    {
        [aNode removeFromParent];
        
        if((index + 1) < self.segments.count)
        {
            SKSpriteNode *partToBeReplaced = self.segments[index + 1];
            SKSpriteNode *newHead = [WSUBoard makeHeadSegment];
            newHead.position = [partToBeReplaced position];

            [[partToBeReplaced parent] addChild:newHead]; // add head
            [partToBeReplaced removeAllActions];
            
            // remove segment new head replaced
            [partToBeReplaced removeFromParent];
            
            NSMutableArray *remainingSegments = [NSMutableArray
                arrayWithObject:newHead];
            
            if((index + 2) < self.segments.count)
            {
                NSRange remainingRange = NSMakeRange(index + 2,
                    self.segments.count - (index + 2));
                [remainingSegments addObjectsFromArray:[self.segments
                    subarrayWithRange:remainingRange]];
                
            }
            result = [[WSUCentipede alloc] initWithSegments:
                remainingSegments ofCentipede:self];
            result.xDirection = self.xDirection;
            newHead.xScale = fabs(newHead.xScale) * result.xDirection;

         }
        
        if(0 < index)
        {
            NSRange survivingRange = NSMakeRange(0, index);
            self.segments = [self.segments subarrayWithRange:
                survivingRange];
        }
        else
        {
            self.segments = @[];
        }
    }
    
    return result;
}

@end

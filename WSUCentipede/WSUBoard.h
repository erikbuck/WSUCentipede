//
//  WSUBoard.h
//  WSUCentipede
//
//  Created by Erik Buck on 6/16/16.
//  Copyright © 2016 WSU. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>


extern const NSInteger WSUBoardWidth;  //< width in mushrooms/centipede segments
extern const NSInteger WSUBoardHeight; //< height in mushrooms/centipede segments

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////
@interface WSUBoard : SKShapeNode <SKPhysicsContactDelegate>

@property (nonatomic, readonly) float updatePeriodSeconds; //< Controls game speed
@property (nonatomic, readonly) SKNode *shooter; //< Object controlled by the palyer
@property (nonatomic, readonly) NSInteger score; //< The payer's current score
@property (nonatomic, readonly) NSInteger livesRemaining; //< Payer's lives remaining

+ (SKSpriteNode *)makeHeadSegment;
+ (SKSpriteNode *)makeBodySegment;
+ (SKSpriteNode *)makeTailSegment;
+ (SKSpriteNode *)makeShooter;

- (void)start;
- (void)startDemoMode;
-(void)update:(CFTimeInterval)currentTime;

- (BOOL)isPositionAvailable:(CGPoint)candidatePosition;
- (void)destroyMushroomAt:(CGPoint)candidatePosition;
- (void)fireBullet;
- (void)moveShooterToPoint:(CGPoint)aPoint;

@end

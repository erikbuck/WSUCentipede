//
//  WSUBoard.m
//  WSUCentipede
//
//  Created by Erik Buck on 6/16/16.
//  Copyright © 2016 WSU. All rights reserved.
//

#import "WSUBoard.h"
#import "WSUCentipede.h"

const NSInteger WSUBoardWidth = 25;  //< width in mushrooms
const NSInteger WSUBoardHeight = 40; //< height in mushrooms
const float WSUInitialUpdatePeriodSeconds = 0.2f;
static const float updatePeriodReductionPerLevelSeconds = 0.02f;
static const float mushroomXScaleFactor = 1.2f; //< arbitrary
static const float mushroomYScaleFactor = 1.2f; //< arbitrary
static const NSInteger scoreThresholdForNewLife = 3000; //< arbitrary
static const NSInteger defaultNumMushrooms = 75;  //< Arbitrary

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////
@interface WSUBoard ()

@property (nonatomic, readwrite) float updatePeriodSeconds; //< Controls game speed
@property (nonatomic, readwrite) SKNode *shooter; //< Object controlled by the palyer
@property (nonatomic, readwrite) NSInteger score; //< The payer's current score
@property (nonatomic, readwrite) NSArray *centipedes; //< All of the centipedes on the board
@property (nonatomic, readwrite) SKSpriteNode *bullet; //< The bullet
@property (nonatomic, readwrite) SKSpriteNode *mushroomAPrototype; //< Copied to create more mushrooms
@property (nonatomic, readwrite) SKSpriteNode *mushroomBPrototype; //< source of texture (slightly damaged)
@property (nonatomic, readwrite) SKSpriteNode *mushroomCPrototype; //< source of texture (moderate damaged)
@property (nonatomic, readwrite) SKSpriteNode *mushroomDPrototype; //< //< source of texture (very damaged)
@property (nonatomic, readwrite) NSInteger lastMusroomIndex; //< The index of the last mushroom healed
@property (nonatomic, readwrite) SKAction *shootSound; //< Sound played when bullet starts moving
@property (nonatomic, readwrite) SKAction *hitSound; //< Sound played when centipede is hit by bullet
@property (nonatomic, readwrite) SKAction *replenishSound; //< Sound played when mushroom is healed
@property (nonatomic, readwrite) BOOL bulletIsMoving; //< YES if bullet is moving
@property (nonatomic, readwrite) NSInteger livesRemaining; //< Payer's lives remaining
@property (nonatomic, readwrite) BOOL isRunning; //< YES if game not over

@end

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////
@implementation WSUBoard

#pragma mark - Prototype Objects

//////////////////////////////////////////////////////////////////////
/// Returns the parent of all the prototype nodes
+ (SKNode *)prototypes;
{
    static  SKScene *prototypes = nil;
    
    if(nil == prototypes)
    {
        prototypes = [SKScene nodeWithFileNamed:@"Prototypes"];
        NSParameterAssert(prototypes);
    }

    return prototypes;
}

//////////////////////////////////////////////////////////////////////
/// Returns a new copy of the prototype with the specified name.
+ (SKSpriteNode *)segmentWithTypeName:(NSString *)aName;
{
    static const float _segmentXScaleFactor = 1.8f; //< arbitrary
    static const float _segmentYScaleFactor = 1.5f; //< arbitrary
    
    SKNode *resultPrototype = [[[self class] prototypes]
        childNodeWithName:aName];
    NSParameterAssert(resultPrototype);
    SKSpriteNode *result = [resultPrototype copy];
    CGRect frame = result.frame;
    result.position = CGPointMake(-1, WSUBoardHeight - 1);
    result.xScale = _segmentXScaleFactor / frame.size.width;
    result.yScale = _segmentYScaleFactor / frame.size.height;;
    
    return result;
}

//////////////////////////////////////////////////////////////////////
/// Returns a new copy of the head segment prototype
+ (SKSpriteNode *)makeHeadSegment;
{
    SKSpriteNode *result = [self segmentWithTypeName:@"Head"];
    result.zPosition = 2.0; // Make head in front of other segments
    
    return result;
}

//////////////////////////////////////////////////////////////////////
/// Returns a new copy of the body segment prototype
+ (SKSpriteNode *)makeBodySegment;
{
    return [self segmentWithTypeName:@"Segment"];
}

//////////////////////////////////////////////////////////////////////
/// Returns a new copy of the tail segment prototype
+ (SKSpriteNode *)makeTailSegment;
{
    return [self segmentWithTypeName:@"Tail"];
}

//////////////////////////////////////////////////////////////////////
/// Returns a new copy of the shooter prototype
+ (SKSpriteNode *)makeShooter;
{
    SKNode *resultPrototype = [[[self class] prototypes]
        childNodeWithName:@"Shooter"];
    NSParameterAssert(resultPrototype);
    return [resultPrototype copy];
}

#pragma mark - Bullet Collisions

//////////////////////////////////////////////////////////////////////
/// Call this method when a bullet hits aMushroom.
/// This method damages the aMushroom, and if aMushroom is excessively
/// damaged, aMushroom is removed from the board.
///
/// This method increments the score.
- (void)bulletDidHitMushroom:(SKSpriteNode *)aMushroom
{
    [self increaseScore:1];
    
    if(self.mushroomAPrototype.texture == aMushroom.texture)
    {
        aMushroom.texture = self.mushroomBPrototype.texture;
    }
    else if(self.mushroomBPrototype.texture == aMushroom.texture)
    {
        aMushroom.texture = self.mushroomCPrototype.texture;
    }
    else if(self.mushroomCPrototype.texture == aMushroom.texture)
    {
        aMushroom.texture = self.mushroomDPrototype.texture;
    }
    else
    {
        [aMushroom removeFromParent];
    }
}

//////////////////////////////////////////////////////////////////////
/// Call this method when a bullet hits a centipede segment, aSegment.
/// This method identifies which centipede contains aSegemnt and
/// tells that centipede to truncate itself at aSegemnt. Any remaining
/// segments after aSegemnt in teh truncated centipede become a new
/// centipede.
///
/// This method increases the score.
/// Destroyed centipede segements are replaced with mushrooms.
///
/// If this method determins that the last centipede on the board has
/// been destroyed, this method calls
/// -repairReplenishMushroomsAndCentipede.
- (void)bulletDidHitCentipede:(SKSpriteNode *)aSegment
{
    static NSInteger scorePerSegment = 10;
    
    [self runAction:self.hitSound];
    
    SKNode *newMushroom = [self.mushroomAPrototype copy];
    newMushroom.position = CGPointMake(floorf(aSegment.position.x),
        floorf(aSegment.position.y));
    [self addChild:newMushroom];
    
    [self increaseScore:scorePerSegment];
    
    // Recreate the array of centipede to contain only the centipedes
    // that still have some segments.
    NSMutableArray *newArray = [NSMutableArray array];
    for(WSUCentipede *c in self.centipedes)
    {
        WSUCentipede *newCentipede = [c truncateAtNode:aSegment];
        if(nil != newCentipede)
        {
            [newArray addObject:newCentipede];
            [newCentipede  advanceInBoard:self];
        }
        
        if(0 != c.segments.count)
        {
            [newArray addObject:c];
        }
    }
    self.centipedes = newArray;
    
    if(0 == self.centipedes.count)
    {
        [self repairReplenishMushroomsAndCentipede];
    }
}

//////////////////////////////////////////////////////////////////////
/// This method checks for any collision between the bullet and a
/// mushroom or centipede segment. If a collision is detected, this
/// method calls -bulletDidHitMushroom: or -bulletDidHitCentipede: as
/// appropriate. This method returns the mushroom or centipede
/// segment that was hit or nil if no mushroom or centipede was hit.
- (SKSpriteNode *)handleBulletCollisions
{
    SKSpriteNode *otherObject = [self mushroomOrCentipedeSegmentAt:
        self.bullet.position];
    if(nil != otherObject)
    {   // reset the bullet
        self.bullet.position = self.shooter.position;
        
        if([otherObject.name hasPrefix:@"Mushroom"])
        {
            [self bulletDidHitMushroom:otherObject];
            self.bulletIsMoving = NO;
        }
        else
        {
            [self bulletDidHitCentipede:otherObject];
            self.bulletIsMoving = NO;
        }
    }
    
    return otherObject;
}

#pragma mark - Bullet Handling

//////////////////////////////////////////////////////////////////////
/// If the bullet is in motion, move it one mushroom height toward the
/// top if the board and schedule another move 1/60th of a second
/// later. If the bullet is off the board at the top, the
/// bullet set to no longer be in motion, and no further moves are
/// scheduled.
- (void)moveBullet
{
    [self.bullet runAction:[SKAction moveBy:CGVectorMake(0, 1)
        duration:1.0/60.0] completion:^{
            if(self.bulletIsMoving && ![self handleBulletCollisions])
            {
                self.bulletIsMoving =
                    self.bullet.position.y <= WSUBoardHeight;
                [self moveBullet];
            }
        }
    ];
}

//////////////////////////////////////////////////////////////////////
/// If the bullet is not in motion, start moving the bullet from the
/// shooter's position toward the top of the board. Otherwise this
/// method does nothing.
- (void)fireBullet;
{
    if(!self.bulletIsMoving)
    {
        self.bullet.position = CGPointMake(self.shooter.position.x,
            floorf(self.shooter.position.y) + 0.5);
        self.bulletIsMoving = YES;
        [self moveBullet];
        [self runAction:self.shootSound];
    }
}

#pragma mark - Board Queries And Changing

//////////////////////////////////////////////////////////////////////
///
- (void)increaseScore:(NSInteger)amount;
{
    NSInteger newScore = self.score + amount;
    if((newScore / scoreThresholdForNewLife) >
        (self.score / scoreThresholdForNewLife))
    {
         self.livesRemaining += 1;
    }
    
    self.score += amount;
}

//////////////////////////////////////////////////////////////////////
///
- (void)removeAllCentipedes
{
    for(WSUCentipede *c in self.centipedes)
    {
        for(SKSpriteNode *s in c.segments)
        {
            [s removeFromParent];
        }
    }
    self.centipedes = @[];
}

//////////////////////////////////////////////////////////////////////
/// Move player controlled shooter to aPoint but constrain shooter to
/// bottom part of board.
- (void)moveShooterToPoint:(CGPoint)aPoint;
{
    static const float veryShortPeriodSec = 0.01;
    static const float maxShooterHeight = 10.0; //< Arbitrary
    
    // Constrain vertically and horizontally
    aPoint.y = MAX(0, MIN(maxShooterHeight, aPoint.y));
    aPoint.x = MAX(0, MIN(WSUBoardWidth, aPoint.x));
    
    [self.shooter runAction:[SKAction moveTo:aPoint
        duration:veryShortPeriodSec]];
    [self fireBullet];
}


//////////////////////////////////////////////////////////////////////
/// Returns the centipede segments or mushroom at the specified
/// point or nil if there is no mushroom or centipede segment there.
- (SKSpriteNode *)mushroomOrCentipedeSegmentAt:(CGPoint)aPoint;
{
     NSArray *candidates = [self nodesAtPoint:aPoint];
    
     for(SKSpriteNode *candidate in candidates)
     {
        if(![candidate.name isEqualToString:@"Shooter"] &&
           ![candidate.name isEqualToString:@"Bullet"])
        {   ///!!!!! EARLY EXIT !!!!!
            return candidate;
        }
     }
    
     return nil;
}

//////////////////////////////////////////////////////////////////////
/// Returns the mushroom at the specified point or nil if there is no
/// mushroom there.
- (SKSpriteNode *)mushroomAt:(CGPoint)aPoint;
{
     for(SKSpriteNode *candidate in [self nodesAtPoint:aPoint])
     {
        if([candidate.name hasPrefix:@"Mushroom"])
        {   ///!!!!! EARLY EXIT !!!!!
            return candidate;
        }
     }
    
     return nil;
}

//////////////////////////////////////////////////////////////////////
/// Returns the mushroom at the specified point or nil if there is no
/// mushroom there.
- (SKSpriteNode *)centipedeSegementIntersectingNode:(SKNode *)aNode;
{
    static float radiusSquared = 1;
    
    for(WSUCentipede *c in self.centipedes)
    {
        for(SKSpriteNode *s in c.segments)
        {
            float deltaX = s.position.x - aNode.position.x;
            float deltaY = s.position.y - aNode.position.y;
            float distanceSquared = deltaX * deltaX +
                deltaY * deltaY;
            
            if(distanceSquared < radiusSquared)
            {   ///!!!!! EARLY EXIT !!!!!
                return s;
            }
        }
    }
    
    return nil;
}

//////////////////////////////////////////////////////////////////////
/// Returns YES if there is no mshroom or centipede segment at the
/// specified position. Returns NO otherwise.
- (BOOL)isPositionAvailable:(CGPoint)candidatePosition;
{
    const bool isInBoard = (candidatePosition.x >= 0 &&
            candidatePosition.x < WSUBoardWidth &&
            candidatePosition.y >= 0 &&
            candidatePosition.y < WSUBoardHeight);
    
    return isInBoard && nil == [self mushroomOrCentipedeSegmentAt:
        CGPointMake(candidatePosition.x, candidatePosition.y)];
}

//////////////////////////////////////////////////////////////////////
/// Destroy any mushroom at the specified point
- (void)destroyMushroomAt:(CGPoint)candidatePosition;
{
    [[self mushroomAt:candidatePosition] removeFromParent];
}

#pragma mark - Shooter Collisions

//////////////////////////////////////////////////////////////////////
///
- (void)handlePossibleCollisionWithShooter
{
    SKSpriteNode *segment =
        [self centipedeSegementIntersectingNode:self.shooter];

    if(nil != segment)
    {
        [self removeAllCentipedes];
        
        self.livesRemaining -= 1;
        if(0 <= self.livesRemaining)
        {
            [self repairReplenishMushroomsAndCentipede];
            
            // Slow game to give player a break
            self.updatePeriodSeconds +=
                updatePeriodReductionPerLevelSeconds;
        }
        else
        {   // Game is over
            self.isRunning = NO;
            [self.shooter removeFromParent];
            [self.bullet removeFromParent];
        }
    }
}

#pragma mark - Object Spawning

//////////////////////////////////////////////////////////////////////
/// Spawn a centipede
- (void)spawnCentipede
{
    self.centipedes = @[[[WSUCentipede alloc] init]];
    for(WSUCentipede *centipede in self.centipedes)
    {
        for(SKNode *segment in centipede.segments)
        {
            [self addChild:segment];
        }
        [centipede advanceInBoard:self];
    }
}

//////////////////////////////////////////////////////////////////////
/// Add up to amount mushrooms to the board.
- (void)sprinkleMushrooms:(NSInteger)amount
{
    for(NSInteger i = 0; i < amount; ++i)
    {
        SKSpriteNode *mushroom = [self.mushroomAPrototype copy];
        NSParameterAssert(mushroom);
        
        CGRect frame = mushroom.frame;
        mushroom.position = CGPointMake(random() % WSUBoardWidth,
            random() % (WSUBoardHeight - 6) + 5);
        mushroom.xScale = mushroomXScaleFactor / frame.size.width;
        mushroom.yScale = mushroomYScaleFactor / frame.size.height;
        if(nil == [self mushroomOrCentipedeSegmentAt:mushroom.position])
        {
           [self addChild:mushroom];
        }
    }
}

//////////////////////////////////////////////////////////////////////
/// Repair all damaged mushrooms. This function calls itself after
/// short delays to enable animation of rapair mushroom by mushroom.
/// When all mushrooms are whole, extra mushrooms are added and then a
/// centipede is spawned. Call this method after the last segment of a
/// centipede has been destroyed to start the next "level".
- (void)repairReplenishMushroomsAndCentipede
{
    static const int defaultNumReplenishMushrooms = 25; //< Arbitrary
    
    if(self.lastMusroomIndex < self.children.count)
    {
        SKSpriteNode *mushroom =
            (SKSpriteNode *)self.children[self.lastMusroomIndex];
        self.lastMusroomIndex += 1;
        
        if([mushroom.name hasPrefix:@"Mushroom"] &&
            self.mushroomAPrototype.texture != mushroom.texture)
        {
            [self runAction:self.replenishSound];
            mushroom.texture = self.mushroomAPrototype.texture;
            [self performSelector:
                @selector(repairReplenishMushroomsAndCentipede)
                withObject:nil afterDelay:0.1];
            [self increaseScore:1];
        }
        else
        {
            [self performSelector:
                @selector(repairReplenishMushroomsAndCentipede)
                withObject:nil afterDelay:0.0];
        }
    }
    
    if(self.lastMusroomIndex == self.children.count)
    {
        [NSObject cancelPreviousPerformRequestsWithTarget:self
            selector:@selector(repairReplenishMushroomsAndCentipede)
            object:nil];
        self.lastMusroomIndex = 0;
        [self sprinkleMushrooms:defaultNumReplenishMushrooms];
        
        // Speed up game
        self.updatePeriodSeconds = MAX(0, self.updatePeriodSeconds -
            updatePeriodReductionPerLevelSeconds);
        [self spawnCentipede];
    }
}

#pragma mark - Game Lifecycle

//////////////////////////////////////////////////////////////////////
/// Call to load resources like prototypes and sounds before game
/// starts.
- (void)loadResources
{
    [self removeAllChildren];
    
    // Preload sounds
    self.shootSound = [SKAction playSoundFileNamed:@"Pew.mp3"
        waitForCompletion:NO];
    self.hitSound = [SKAction playSoundFileNamed:@"Pop.aiff"
        waitForCompletion:NO];
    self.replenishSound = [SKAction playSoundFileNamed:@"Glass.aiff"
        waitForCompletion:NO];

    // Preload mushroom prototypes
    self.mushroomAPrototype = [[[[self class] prototypes]
        childNodeWithName:@"MushroomA"] copy];
    self.mushroomBPrototype = [[[[self class] prototypes]
        childNodeWithName:@"MushroomB"] copy];
    self.mushroomCPrototype = [[[[self class] prototypes]
        childNodeWithName:@"MushroomC"] copy];
    self.mushroomDPrototype = [[[[self class] prototypes]
        childNodeWithName:@"MushroomD"] copy];
    
    // Setup player's shooter
    SKNode *shooterPrototype = [[[self class] prototypes]
        childNodeWithName:@"Shooter"];
    self.shooter = [shooterPrototype copy];
    
    // Setup bullet
    SKSpriteNode *bulletPrototype =
        (SKSpriteNode *)[[[self class] prototypes] childNodeWithName:
        @"Bullet"];
    self.bullet = [bulletPrototype copy];
    self.bullet.position = self.shooter.position;
}

//////////////////////////////////////////////////////////////////////
/// Call to show came board and animations without player input.
- (void)startDemoMode;
{
    [self loadResources];
    
    // Reset speed to default
    self.updatePeriodSeconds = WSUInitialUpdatePeriodSeconds;

    self.livesRemaining = 0;
    [self sprinkleMushrooms:defaultNumMushrooms];
    [self spawnCentipede];
    self.isRunning = NO;
}


//////////////////////////////////////////////////////////////////////
/// Call to start or restart a game
- (void)start;
{
    [self loadResources];
    
    [self addChild:self.shooter];
    [self addChild:self.bullet];
   
    // Reset speed to default
    self.updatePeriodSeconds = WSUInitialUpdatePeriodSeconds;

    self.livesRemaining = 3;
    [self sprinkleMushrooms:defaultNumMushrooms];
    [self spawnCentipede];
    self.isRunning = YES;
}

//////////////////////////////////////////////////////////////////////
/// Called periodically by scene
-(void)update:(CFTimeInterval)currentTime;
{
    if(self.isRunning)
    {
        [self handlePossibleCollisionWithShooter];
    }
}

@end

//
//  CCMyScene.h
//  Space Cannon
//

//  Copyright (c) 2015 MarkInc. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "AVFoundation/AVFoundation.h"

@interface CCMyScene : SKScene <SKPhysicsContactDelegate>

//nonatomic is faster but does not make guarantees about thread safety
@property (nonatomic) int ammo;
@property (nonatomic) int score;
@property (nonatomic) int pointValue;
@property (nonatomic) bool gamePaused;

@end

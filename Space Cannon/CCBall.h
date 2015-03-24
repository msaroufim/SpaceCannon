//
//  CCBall.h
//  Space Cannon
//
//  Created by Mark Saroufim on 3/24/15.
//  Copyright (c) 2015 MarkInc. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface CCBall : SKSpriteNode

@property (nonatomic) SKEmitterNode *trail;


-(void)updateTrail;

@end

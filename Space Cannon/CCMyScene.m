//
//  CCMyScene.m
//  Space Cannon
//
//  Created by Mark Saroufim on 3/11/15.
//  Copyright (c) 2015 MarkInc. All rights reserved.
//
//_____
//___|    _|__  ____    _____   __  __   ______  ____    _____   _____  __   _  ______  ____  ____    __
//|    \  /  | ||    \  |     | |  |/ /  |   ___||    \  |     | /     \|  | | ||   ___||    ||    \  /  |
//|     \/   | ||     \ |     \ |     \   `-.`-. |     \ |     \ |     ||  |_| ||   ___||    ||     \/   |
//|__/\__/|__|_||__|\__\|__|\__\|__|\__\ |______||__|\__\|__|\__\\_____/|______||___|   |____||__/\__/|__|
//|_____|


#import "CCMyScene.h"
#import "CCMenu.h"
#import "CCBall.h"
#import <AVFoundation/AVFoundation.h>

@implementation CCMyScene
{
    //define main nodes here to make them accessible from all methods
    AVAudioPlayer *_audioPlayer;
    CCMenu *_menu;
    SKNode *_mainLayer;
    SKSpriteNode *_cannon;
    SKSpriteNode *_ammoDisplay;
    SKSpriteNode *_pauseButton;
    SKSpriteNode *_resumeButton;
    SKAction *_bounceSound;
    SKAction *_deepExplosionSound;
    SKAction *_explosionSound;
    SKAction *_laserSound;
    SKAction *_zapSound;
    SKLabelNode *_scoreLabel;
    SKLabelNode *_pointLabel;
    NSUserDefaults *_userDefaults;
    BOOL _didShoot;
    BOOL _gameOver;
}

static const CGFloat HaloLowAngle = 200.0 * M_PI /180;
static const CGFloat HaloHighAngle = 340.0 * M_PI /180;
static const CGFloat HaloSpeed = 100;
static const uint32_t NumberOfShields = 6;
static const CGFloat SHOOTSPEED = 1000;
static const uint32_t AmmoCount = 5;
static const uint32_t  HaloCategory = 0x1    <<0;
static const uint32_t  BallCategory = 0x1    <<1;
static const uint32_t  EdgeCategory = 0x1    <<2;
static const uint32_t  ShieldCategory = 0x1  <<3;
static const uint32_t  LifeBarCategory = 0x1 <<4;

static NSString * const KeyTopScore = @"TopScore";



static inline CGVector radiansToVect(CGFloat radians) {
    
    CGVector vector;
    vector.dx = cosf(radians);
    vector.dy = sinf(radians);
    return vector;
}

static inline CGFloat  randomInRange(CGFloat low, CGFloat high)
{
    CGFloat value = arc4random_uniform(UINT32_MAX) / (CGFloat)UINT32_MAX;
    return value * (high - low) + low;
}



-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        
        self.physicsWorld.gravity  = CGVectorMake(0.0,0.0);
        self.physicsWorld.contactDelegate = self;
        
        /* Setup your scene here */
        
        
        
        //Setup background
        SKSpriteNode *background = [SKSpriteNode spriteNodeWithImageNamed:@"Starfield"];
        background.position = CGPointZero;
        background.anchorPoint = CGPointZero;
        background.blendMode = SKBlendModeReplace;
        [self addChild:background];
        
        
        //Add edges
        SKNode *leftEdge = [[SKNode alloc] init];
        leftEdge.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:CGPointZero toPoint:CGPointMake(0.0,self.size.height)];
        leftEdge.position = CGPointZero;
        leftEdge.physicsBody.categoryBitMask = EdgeCategory;
        [self addChild:leftEdge];
        
        SKNode *rightEdge = [[SKNode alloc] init];
        rightEdge.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:CGPointZero toPoint:CGPointMake(0.0,self.size.height)];
        rightEdge.position = CGPointMake(self.size.width,0.0);
        rightEdge.physicsBody.categoryBitMask = EdgeCategory;
        [self addChild:rightEdge];
        
    
        
        //Add main layer
        _mainLayer = [[SKNode alloc] init ];
        [self addChild:_mainLayer];
        
        //Add cannon
        _cannon = [SKSpriteNode spriteNodeWithImageNamed:@"Cannon"];
        _cannon.position = CGPointMake(self.size.width * 0.5,0.0);
        [self addChild:_cannon];
        
        //Create cannon rotation actions.
        SKAction *rotateCAnnon = [SKAction sequence:@[[SKAction rotateByAngle:M_PI duration:2],
                                                     [SKAction rotateByAngle:-M_PI duration:2]]];
        
        [_cannon runAction:[SKAction repeatActionForever:rotateCAnnon]];
        
        //create spawn halo action
        
        SKAction *spawnHalo = [SKAction sequence:@[[SKAction waitForDuration:2 withRange:1],
                                                   [SKAction performSelector:@selector(spawnHalo) onTarget:self]]];
        
        [self runAction:[SKAction repeatActionForever:spawnHalo] withKey:@"SpawnHalo"];
        
        //Setup ammo
        _ammoDisplay = [SKSpriteNode spriteNodeWithImageNamed:@"Ammo5"];
        _ammoDisplay.anchorPoint = CGPointMake(0.5, 0.0);
        _ammoDisplay.position = _cannon.position;
        [self addChild:_ammoDisplay];
        
        //^{} is lambda syntax
        SKAction *incrementAmmo = [SKAction sequence:@[[SKAction waitForDuration:2],
                                                       [SKAction runBlock:^{
            self.ammo++;
        }]]];
        
        [self runAction:[SKAction repeatActionForever:incrementAmmo]];
        
        
        //Setup pause button
        _pauseButton = [SKSpriteNode spriteNodeWithImageNamed:@"PauseButton"];
        _pauseButton.position = CGPointMake(self.size.width - 30, 20);
        [self addChild:_pauseButton];
        
        //Setup Resume button
        _resumeButton = [SKSpriteNode spriteNodeWithImageNamed:@"ResumeButton"];
        _resumeButton.position = CGPointMake(self.size.width * 0.5, self.size.height * 0.5);
        [self addChild:_resumeButton];
        
        //Score Label
        _scoreLabel = [SKLabelNode labelNodeWithFontNamed:@"DIN Alternate"];
        _scoreLabel.position = CGPointMake(15,10);
        _scoreLabel.horizontalAlignmentMode  = SKLabelHorizontalAlignmentModeLeft;
        _scoreLabel.fontSize = 15;
        [self addChild:_scoreLabel];
        
        
        
        //Setup point multiplier label
        _pointLabel = [SKLabelNode labelNodeWithFontNamed:@"DIN Alternate"];
        _pointLabel.position = CGPointMake(15,30);
        _pointLabel.horizontalAlignmentMode  = SKLabelHorizontalAlignmentModeLeft;
        _pointLabel.fontSize = 15;
        [self addChild:_pointLabel];
        
        
        //Setup sounds
        _bounceSound = [SKAction playSoundFileNamed:@"Bounce.caf" waitForCompletion:NO];
        _deepExplosionSound = [SKAction playSoundFileNamed:@"DeepExplosion.caf" waitForCompletion:NO];
        _explosionSound = [SKAction playSoundFileNamed:@"Explosion.caf" waitForCompletion:NO];
        _laserSound= [SKAction playSoundFileNamed:@"Laser.caf" waitForCompletion:NO];
        _zapSound = [SKAction playSoundFileNamed:@"Zap.caf" waitForCompletion:NO];
        
        
        
        //Setup menu
        
        _menu = [[CCMenu alloc] init];
        _menu.position = CGPointMake(self.size.width * 0.5,self.size.height - 220 );
        [self addChild:_menu];

        
        
        //Set Initial values
        self.ammo = AmmoCount;
        self.score = 0;
        self.pointValue = 1;
        _gameOver = YES;
        _scoreLabel.hidden = YES;
        _pointLabel.hidden = YES;
        _pauseButton.hidden = YES;
        _resumeButton.hidden = YES;
        
        
        //Set User Defaults
        
        //Load Top score
        _userDefaults = [NSUserDefaults standardUserDefaults];
        _menu.topScore = [_userDefaults integerForKey:KeyTopScore];
        
        //Load Music
        NSURL *url = [[NSBundle mainBundle] URLForResource:@"Azure" withExtension:@"caf"];
        NSError *error = nil;
        _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
        
        if (!_audioPlayer) {
            NSLog(@"Error loading audio player: %@",error);
        } else {
            //repeat music forever
            _audioPlayer.numberOfLoops = -1;
            [_audioPlayer play];
        }
        
    }
    return self;
}


-(void)setAmmo:(int)ammo
{
    if(ammo >= 0 && ammo <= 5) {
        _ammo = ammo;
        _ammoDisplay.texture = [SKTexture textureWithImageNamed:[NSString stringWithFormat:@"Ammo%d",ammo]];
    }
}


-(void)setScore:(int)score
{
    _score = score;
    _scoreLabel.text = [NSString stringWithFormat:@"Score: %d",score ];
}

-(void)setPointValue:(int)pointValue
{
    _pointValue = pointValue;
    _pointLabel.text = [NSString stringWithFormat:@"Points: x%d", pointValue];
}

-(void)setGamePaused:(bool)gamePaused
{
    _gamePaused = gamePaused;
    _pauseButton.hidden = gamePaused;
    _resumeButton.hidden = !gamePaused;
    
    //pauses entire scene
    self.paused = gamePaused;
}

-(void)spawnHalo
{
    //Increase spawn speed
    SKAction *spawnHaloAction = [self actionForKey:@"SpawnHalo"];
    if(spawnHaloAction.speed < 1.5) {
        spawnHaloAction.speed += 0.01;
    }
    
    
    SKSpriteNode *halo = [SKSpriteNode spriteNodeWithImageNamed:@"Halo"];
    halo.name = @"halo";
    halo.position = CGPointMake(randomInRange(halo.size.width * 0.5, self.size.width - (halo.size.width * 0.5)),self.size.height + (halo.size.height * 0.5));
    halo.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:16 ];
    CGVector  direction = radiansToVect(randomInRange(HaloLowAngle, HaloHighAngle));
    halo.physicsBody.velocity = CGVectorMake(direction.dx * HaloSpeed, direction.dy *  HaloSpeed);
    halo.physicsBody.restitution = 1.0;
    halo.physicsBody.linearDamping = 0.0;
    halo.physicsBody.friction = 0.0;
    halo.physicsBody.categoryBitMask = HaloCategory;
    halo.physicsBody.collisionBitMask = EdgeCategory ;
    
    //alert when collision with ball happens
    halo.physicsBody.contactTestBitMask = BallCategory | LifeBarCategory | ShieldCategory | EdgeCategory;
    
    
    
    
    //PowerUps
    
    
    int haloCount = 0;
    for (SKNode * node in _mainLayer.children) {
        if ([node.name isEqualToString:@"Halo"]) {
            haloCount++;
            
        }
    }
    
    if (haloCount == 4) {
        //Create bomb
        halo.texture = [SKTexture textureWithImageNamed:@"HaloBomb"];
        halo.userData = [[NSMutableDictionary alloc] init];
        [halo.userData setValue:@YES forKey:@"Bomb"];
        
    }
    
  //Random Point Multiplier
  else  if (!_gameOver && arc4random_uniform(6) == 0) {
        halo.texture = [SKTexture textureWithImageNamed:@"HaloX"];
        halo.userData = [[NSMutableDictionary alloc] init];
        [halo.userData setValue:@YES forKey:@"Multiplier"];
    }
    
    
    [_mainLayer addChild:halo];
}

-(void)didBeginContact:(SKPhysicsContact *)contact
{
    SKPhysicsBody *firstBody;
    SKPhysicsBody *secondBody;
    
    if(contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask) {
        firstBody = contact.bodyA;
        secondBody = contact.bodyB;
    } else {
        firstBody = contact.bodyB;
        secondBody = contact.bodyA;
    }
    
    if(firstBody.categoryBitMask == HaloCategory && secondBody.categoryBitMask == BallCategory) {
        self.score += self.pointValue;
        [self addExplosion:firstBody.node.position withName:@"HaloExplosion"];
        [self runAction:_explosionSound];
        
        
        if ([firstBody.node.userData valueForKey:@"Multiplier"]) {
            self.pointValue++;
        } else if ([[firstBody.node.userData valueForKey:@"Bomb"] boolValue]) {
            firstBody.node.name = nil; //to prevent firstbody from exploding twice
            [_mainLayer enumerateChildNodesWithName:@"halo" usingBlock:^(SKNode *node, BOOL *stop) {
                self.score += self.pointValue;
                [self addExplosion:node.position withName:@"HaloExplosion"];
                [node removeFromParent];
            }];
            
            
        }
        
        [firstBody.node removeFromParent];
        [secondBody.node removeFromParent];
    }
    
    //split out like this because might add different effects later
    if (firstBody.categoryBitMask == HaloCategory &&  secondBody.categoryBitMask == ShieldCategory) {
       [self addExplosion:firstBody.node.position withName:@"HaloExplosion"];
        [firstBody.node removeFromParent];
        [secondBody.node removeFromParent];
        [self runAction:_explosionSound];
    
        
        if ([[firstBody.node.userData valueForKey:@"Bomb"] boolValue]) {
        
        //Remove all shield
        [_mainLayer enumerateChildNodesWithName:@"shield" usingBlock:^(SKNode *node, BOOL *stop) {
            [node removeFromParent];
        }];
        }
    
    }
    
    
    if(firstBody.categoryBitMask == HaloCategory && secondBody.categoryBitMask == LifeBarCategory) {
        [self addExplosion:firstBody.node.position withName:@"HaloExplosion"];
        [self addExplosion:secondBody.node.position withName:@"LifeBarExplosion"];
        [self runAction:_deepExplosionSound];
        [firstBody.node removeFromParent];
        [secondBody.node removeFromParent];
        [self gameOver];
        
    }
    
    if (firstBody.categoryBitMask == HaloCategory && secondBody.categoryBitMask == EdgeCategory) {
        [self runAction:_zapSound];
    }
    
    if (firstBody.categoryBitMask == BallCategory && secondBody.categoryBitMask == EdgeCategory) {
        [self runAction:_bounceSound];
        if ([firstBody.node isKindOfClass:[CCBall class]]) {
            //cast firstbody.node to ccball
            ((CCBall *) firstBody.node).bounces++;
            if (((CCBall *) firstBody.node).bounces > 3) {
                [firstBody.node removeFromParent];
                self.pointValue = 1;
            }
        }
    }


}

-(void)shoot

{
    if (self.ammo > 0) {
        self.ammo--;

        CCBall *ball = [CCBall spriteNodeWithImageNamed:@"Ball"];
        ball.name = @"ball";
        CGVector rotationVector = radiansToVect(_cannon.zRotation);
        ball.position = CGPointMake(_cannon.position.x + (_cannon.size.width * 0.5 * rotationVector.dx),
                                    _cannon.position.y + (_cannon.size.width * 0.5 * rotationVector.dy));
   
        [_mainLayer addChild:ball];
        ball.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:6.0];
        ball.physicsBody.velocity = CGVectorMake(rotationVector.dx * SHOOTSPEED, rotationVector.dy * SHOOTSPEED);
        ball.physicsBody.restitution = 1.0;
        ball.physicsBody.linearDamping = 0.0;
        ball.physicsBody.friction = 0.0;
        ball.physicsBody.categoryBitMask = BallCategory;
    
        //defines categories of things ball will collide to
        //so ball will only react to edges
        ball.physicsBody.collisionBitMask = EdgeCategory;
        ball.physicsBody.contactTestBitMask = EdgeCategory;
        [self runAction:_laserSound];
        
        //create trail
        NSString *ballTrailPath = [[NSBundle mainBundle] pathForResource:@"BallTrail" ofType:@"sks"];
        SKEmitterNode *ballTrail = [NSKeyedUnarchiver unarchiveObjectWithFile:ballTrailPath];
        //particle exists in coordinate system of mainlayer instead of that of ball
        ballTrail.targetNode = _mainLayer;
        [_mainLayer addChild:ballTrail];
        ball.trail = ballTrail;
    
    
        
    }
}


-(void)gameOver
{
    [_mainLayer enumerateChildNodesWithName:@"halo" usingBlock:^(SKNode *node, BOOL *stop) {
        [self addExplosion:node.position withName:@"HaloExplosion"];
        [node removeFromParent];
    }];
    [_mainLayer enumerateChildNodesWithName:@"ball" usingBlock:^(SKNode *node, BOOL *stop) {
        [node removeFromParent];
    }];
    [_mainLayer enumerateChildNodesWithName:@"shield" usingBlock:^(SKNode *node, BOOL *stop) {
        [node removeFromParent];
    }];
    
    _menu.score = self.score;
    
    if(self.score > _menu.topScore) {
        _menu.topScore = self.score;
        [_userDefaults setInteger:self.score forKey:KeyTopScore];
        [_userDefaults synchronize];
        
    }
    
    _gameOver = YES;
    _scoreLabel.hidden = YES;
    _scoreLabel.hidden = YES;
    _pauseButton.hidden = YES;
    [self runAction:[SKAction waitForDuration:1.0] completion:^{
        [_menu show];
    }];
    
}

-(void)newGame
{
   
  
    [_mainLayer removeAllChildren];
    
    //Setup shields
    for (int i = 0; i < NumberOfShields; i++) {
        SKSpriteNode *shield = [SKSpriteNode spriteNodeWithImageNamed:@"Block"];
        shield.name = @"shield";
        shield.position = CGPointMake(35 + (50*i), 90);
        shield.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(42, 9)];
        shield.physicsBody.categoryBitMask = ShieldCategory;
        shield.physicsBody.collisionBitMask = 0;
        [_mainLayer addChild:shield];
        
    }
    
    //Setup Life Bar
    SKSpriteNode *lifeBar = [SKSpriteNode spriteNodeWithImageNamed:@"BlueBar"];
    lifeBar.position = CGPointMake(self.size.width * 0.5, 70 );
    lifeBar.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:CGPointMake(-lifeBar.size.width * 0.5,0) toPoint:CGPointMake(lifeBar.size.width * 0.5, 0)];
    lifeBar.physicsBody.categoryBitMask = LifeBarCategory;
    [self addChild:lifeBar];
    
    
    
    //Set newGame Initial values
    [self actionForKey:@"SpawnHalo"].speed = 1.0;
    self.ammo = AmmoCount;
    self.pointValue = 1;
    self.score = 0;
    _scoreLabel.hidden = NO;
    _pointLabel.hidden = NO;
    _pauseButton.hidden = NO;
    [_menu hide];
    _gameOver = NO;
  
    
    
}

-(void)addExplosion:(CGPoint)position withName:(NSString *)name
{
    //get path to file
    NSString *explosionPath = [[NSBundle mainBundle] pathForResource:name ofType:@"sks" ];
    SKEmitterNode *explosion = [NSKeyedUnarchiver unarchiveObjectWithFile:explosionPath];
    
    
//    //also possible to set emitter manually
//    SKEmitterNode *explosion = [SKEmitterNode node];
//    explosion.particleTexture = [SKTexture textureWithImageNamed:@"spark"];
//    explosion.particleLifetime = 1;
//    explosion.particleBirthRate = 2000;
//    explosion.numParticlesToEmit = 100;
//    explosion.emissionAngleRange =  360;
//    explosion.particleScale = 0.2;
//    explosion.particleScaleSpeed = -0.2;
//    explosion.particleSpeed = 200;
    
    explosion.position = position;
    [_mainLayer addChild:explosion];
    
    
    SKAction *removeExplosion = [SKAction sequence:@[[SKAction waitForDuration:1.5],
                                                     [SKAction removeFromParent]]];
    
    [explosion runAction:removeExplosion];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */
    
    for (UITouch *touch in touches) {
        if(!_gameOver && !self.gamePaused) {
            if (![_pauseButton containsPoint:[touch locationInNode:_pauseButton.parent]]) {
                _didShoot = YES;
                [self shoot];
            }
   
        }
    }
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        if(_gameOver && _menu.touchable) {
            SKNode *n = [_menu nodeAtPoint:[touch locationInNode:_menu]];
            if([n.name isEqualToString:@"Play"]) {
                [self newGame];
            }
            
        }
        else if (!_gameOver) {
            if(self.gamePaused) {
                if ([_resumeButton containsPoint:[touch locationInNode:_resumeButton.parent]]) {
                    self.gamePaused = NO;
                }
            } else {
                if ([_pauseButton containsPoint:[touch locationInNode:_resumeButton.parent]]) {
                    self.gamePaused = YES;
                }
                
            }
        }
    }
}

-(void)didSimulatePhysics
{
    if(_didShoot) {
        _didShoot = NO;
    }
    
    
    
    
   //Remove nodes missing from page
    
    [_mainLayer enumerateChildNodesWithName:@"ball" usingBlock:^(SKNode *node, BOOL *stop) {
        
        if ([node respondsToSelector:@selector(updateTrail)]) {
            [node performSelectorOnMainThread:@selector(updateTrail) withObject:nil waitUntilDone:NO];
        }
        
        
        
        if (!CGRectContainsPoint(self.frame,node.position)) {
            [node removeFromParent];
            self.pointValue = 1;

        }
        
    }];
    
    //if halo is below the bottom of the screen
    [_mainLayer enumerateChildNodesWithName:@"halo" usingBlock:^(SKNode *node, BOOL *stop) {
        if(node.position.y + node.frame.size.height < 0) {
            [node removeFromParent];
        }
    }];
   
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
}

@end

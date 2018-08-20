//
//  GameScene.swift
//  ZombieConga
//
//  Created by Bret Williams on 8/18/18.
//  Copyright © 2018 Bret Williams. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
    
    var zombie = SKSpriteNode()
    var zombieMovePointsPerSec:CGFloat = 480.0
    var velocity:CGPoint = CGPoint.zero
    var lastUpdateTime: TimeInterval = 0
    var dt: TimeInterval = 0
    
    override func didMove(to view: SKView) {
        
        backgroundColor = UIColor.black
        
        let background = SKSpriteNode(imageNamed: "background1")
        background.zPosition = -1
        background.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(background)
        
        zombie = SKSpriteNode(imageNamed: "zombie1")
        zombie.position = CGPoint(x: 400, y: 400)
        addChild(zombie)
        
    }
    
    func move(sprite: SKSpriteNode, velocity: CGPoint) {
        
        let amountToMove = CGPoint(x: velocity.x * CGFloat(dt), y:velocity.y * CGFloat(dt))
        sprite.position = CGPoint(x: sprite.position.x + amountToMove.x, y: sprite.position.y + amountToMove.y)
        
    }
    
    func moveZombieToward(location: CGPoint) {
        
        //vector between the tap location and the zombie position
        let offset = CGPoint(x: location.x - zombie.position.x, y: location.y - zombie.position.y)
        //using the Pythagorean theorem, find the length of the line betweeen zombie and the tap location
        let length = sqrt(Double(offset.x * offset.x + offset.y * offset.y))
        //reduce to a unit vector
        let direction = CGPoint(x: offset.x / CGFloat(length), y: offset.y / CGFloat(length))
        //calcualte velocity of the direction vector.  this is how fast the zombie will travel along the route.
        velocity = CGPoint(x: direction.x * zombieMovePointsPerSec, y:direction.y * zombieMovePointsPerSec)
        
    }
    
    func sceneTouched(touchLocation: CGPoint) {
        
        moveZombieToward(location: touchLocation)
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        guard let touch = touches.first else {
            return
        }
        
        let touchLocation = touch.location(in: self)
        sceneTouched(touchLocation: touchLocation)
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        guard let touch = touches.first else {
            return
        }
        
        let touchLocation = touch.location(in: self)
        sceneTouched(touchLocation: touchLocation)
        
    }
    
    override func update(_ currentTime: TimeInterval) {
        
        if lastUpdateTime > 0 {
            dt = currentTime - lastUpdateTime
        } else {
            dt = 0
        }
        lastUpdateTime = currentTime
        
        move(sprite: zombie, velocity: velocity)
    }
    
}

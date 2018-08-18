//
//  GameScene.swift
//  ZombieConga
//
//  Created by Bret Williams on 8/18/18.
//  Copyright © 2018 Bret Williams. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
    
    override func didMove(to view: SKView) {
        
        backgroundColor = UIColor.black
        
        let background = SKSpriteNode(imageNamed: "background1")
        background.zPosition = -1
        background.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(background)
        
        let zombieOne = SKSpriteNode(imageNamed: "zombie1")
        zombieOne.position = CGPoint(x: 400, y: 400)
        addChild(zombieOne)
        
    }
    
}

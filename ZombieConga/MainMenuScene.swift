//
//  MainMenuScene.swift
//  ZombieConga
//
//  Created by Bret Williams on 9/23/18.
//  Copyright © 2018 Bret Williams. All rights reserved.
//

import Foundation
import SpriteKit

class MainMenuScene : SKScene {
    
    override func didMove(to view: SKView) {
        
        backgroundColor = UIColor.black
        
        let background = SKSpriteNode(imageNamed: "MainMenu")
        background.zPosition = -1
        background.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(background)
        
    }
    
    func sceneTapped() {
      
        let gameScene = GameScene(size: size)
        gameScene.scaleMode = scaleMode
        let transition = SKTransition.doorway(withDuration: 1.5)
        view?.presentScene(gameScene, transition: transition)
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        sceneTapped()
        
    }
    
    
    
}

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
    var catMovePointsPerSec:CGFloat = 480.0
    var lives = 5
    var gameOver = false
    var velocity:CGPoint = CGPoint.zero
    var lastUpdateTime: TimeInterval = 0
    var dt: TimeInterval = 0
    let playableRect: CGRect
    var lastTouchLocation: CGPoint = CGPoint.zero
    let zombieRotateRadiansPerSec: CGFloat = 4.0 * π
    let zombieAnimation: SKAction
    let catCollisionSound: SKAction = SKAction.playSoundFileNamed("hitCat.wav", waitForCompletion: false)
    let enemyCollisionSound: SKAction = SKAction.playSoundFileNamed("hitCatLady.wav", waitForCompletion: false)
    var isZombieInvincible:Bool = false
    
    func boundsCheckZombie() {
        
        let bottomLeft = CGPoint(x: 0, y: playableRect.minY)
        let topRight = CGPoint(x: size.width, y: playableRect.maxY)
        
        if zombie.position.x <= bottomLeft.x {
            zombie.position.x = bottomLeft.x
            velocity.x = -velocity.x
        }
        
        if zombie.position.x >= topRight.x {
            zombie.position.x = topRight.x
            velocity.x = -velocity.x
        }
        
        if zombie.position.y <= bottomLeft.y {
            zombie.position.y = bottomLeft.y
            velocity.y = -velocity.y
        }
        
        if zombie.position.y >= topRight.y {
            zombie.position.y = topRight.y
            velocity.y = -velocity.y
        }
        
    }
    
    func checkCollisions() {
        
        var hitCats: [SKSpriteNode] = []  //initialize empty array of SKSpriteNode
        enumerateChildNodes(withName: "cat") {
            (node, _) in
            let cat = node as! SKSpriteNode
            if (cat.frame.intersects(self.zombie.frame)) {
                hitCats.append(cat)
            }
        }
        for cat in hitCats {
            zombieHit(cat: cat)
        }
        
        if (!isZombieInvincible) {
            var hitEnemies: [SKSpriteNode] = []
            enumerateChildNodes(withName: "enemy") {
                (node, _) in
                let enemy = node as! SKSpriteNode
                if (node.frame.insetBy(dx: 20, dy: 20).intersects(self.zombie.frame)) {
                    hitEnemies.append(enemy)
                }
            }
            for enemy in hitEnemies {
                zombieHit(enemy: enemy)
            }
        }
    }
    
    func debugDrawPlayableArea() {
        
        let shape = SKShapeNode(rect: playableRect)
        shape.strokeColor = SKColor.red
        shape.lineWidth = 4.0
        addChild(shape)
        
    }
    
    override func didEvaluateActions() {
        checkCollisions()
    }
    
    override func didMove(to view: SKView) {
        
        backgroundColor = UIColor.black
        
        let background = SKSpriteNode(imageNamed: "background1")
        background.zPosition = -1
        background.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(background)
        
        zombie = SKSpriteNode(imageNamed: "zombie1")
        zombie.position = CGPoint(x: 400, y: 400)
        zombie.zPosition = 100
        addChild(zombie)
        //zombie.run(SKAction.repeatForever(zombieAnimation))
        //startZombieAnimation()
        
        run(SKAction.repeatForever(
            SKAction.sequence([SKAction.run() {
                [weak self] in
                    self?.spawnEnemy()
                },
                SKAction.wait(forDuration: 2.0)])))
        
        run(SKAction.repeatForever(
            SKAction.sequence([SKAction.run() {
                [weak self] in
                self?.spawnCat()
                },
                SKAction.wait(forDuration: 1.0)])))
        
        playBackgroundMusic(filename: "backgroundMusic.mp3")
        
    }
    
    override init(size: CGSize) {
        let maxAspectRatio:CGFloat = 16.9 / 9.0
        let playableHeight = size.width / maxAspectRatio
        let playableMargin = (size.height - playableHeight) / 2.0
        playableRect = CGRect(x: 0, y: playableMargin,
                              width: size.width,
                              height: playableHeight)
        
        var textures: [SKTexture] = []
        for i in 1...4 {
            textures.append(SKTexture(imageNamed: "zombie\(i)"))
        }
        textures.append(textures[2])
        textures.append(textures[1])
        zombieAnimation = SKAction.animate(with: textures, timePerFrame: 0.1)
        
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init coder has not been implemented")
    }
    
    func loseCats() {
        
        var loseCount = 0
        
        enumerateChildNodes(withName: "train") { node, stop in
            var randomSpot = node.position
            randomSpot.x += CGFloat.random(min: -100, max: 100)
            randomSpot.y += CGFloat.random(min: -100, max: 100)
            
            node.name = ""
            node.run(
                SKAction.sequence([
                    SKAction.group([
                        SKAction.rotate(byAngle: π*4, duration: 1.0),
                        SKAction.move(to: randomSpot, duration: 1.0),
                        SKAction.scale(to: 0, duration: 1.0)
                        ]),
                    SKAction.removeFromParent()
                ]))
            
            loseCount += 1
            print("Lost a cat! \(loseCount)")
            if (loseCount >= 2) {
                stop[0] = true
            }
        }
    }
    
    func move(sprite: SKSpriteNode, velocity: CGPoint) {
        
        //long form
        //let amountToMove = CGPoint(x: velocity.x * CGFloat(dt),
        //                           y: velocity.y * CGFloat(dt))
        
        //sprite.position = CGPoint(x: sprite.position.x + amountToMove.x,
        //                          y: sprite.position.y + amountToMove.y)
        
        //refactored using overloaded operators
        let amountToMove = velocity * CGFloat(dt)
        
        sprite.position += amountToMove
        
    }
    
    func moveTrain() {
        
        var targetPosition = zombie.position
        var trainCount = 0
        
        enumerateChildNodes(withName: "train") { node, stop in
            trainCount += 1
            if !node.hasActions() {
                let actionDuration = 0.3
                let offset = targetPosition - node.position
                let direction = offset.normalized()
                let amountToMovePerSec = direction * self.catMovePointsPerSec
                let amountToMove = amountToMovePerSec * CGFloat(actionDuration)
                let moveAction = SKAction.moveBy(x: amountToMove.x, y: amountToMove.y, duration: actionDuration)
                node.run(moveAction)
            }
            targetPosition = node.position
        }
            
        if (trainCount >= 15 && !gameOver) {
            gameOver = true
            print("Winning!")
            
            backgroundMusicPlayer.stop()
            let gameOverScene = GameOverScene(size: size, won: true)
            gameOverScene.scaleMode = scaleMode
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            view?.presentScene(gameOverScene, transition: reveal)
        }
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
    
    func rotate(sprite: SKSpriteNode, direction: CGPoint, rotateRadiansPerSec: CGFloat) {
        
        let shortest = shortestAngleBetween(angle1: sprite.zRotation, angle2: velocity.angle)
        let amountToRotate = min(rotateRadiansPerSec * CGFloat(dt), abs(shortest))
        sprite.zRotation += shortest.sign() * amountToRotate

    }
    
    func sceneTouched(touchLocation: CGPoint) {
        
        lastTouchLocation = touchLocation
        moveZombieToward(location: touchLocation)
        startZombieAnimation()
        
    }
    
    func spawnCat() {
        
        let cat = SKSpriteNode(imageNamed: "cat")
        cat.name = "cat"
        cat.position = CGPoint(x: CGFloat.random(min: playableRect.minX,
                                                 max: playableRect.maxX),
                               y: CGFloat.random(min: playableRect.minY,
                                                 max: playableRect.maxY))
        cat.setScale(0)
        addChild(cat)
        
        let appear = SKAction.scale(to: 1.0, duration: 0.5)
        
        cat.zRotation = -π / 16.0
        let leftWiggle = SKAction.rotate(byAngle: π/8.0, duration: 0.5)
        let rightWiggle = leftWiggle.reversed()
        let fullWiggle = SKAction.sequence([leftWiggle, rightWiggle])
       
        let scaleUp = SKAction.scale(by: 1.2, duration: 0.25)
        let scaleDown = scaleUp.reversed()
        let fullScale = SKAction.sequence([scaleUp, scaleDown, scaleUp, scaleDown])
        let group = SKAction.group([fullScale, fullWiggle])
        let groupWait = SKAction.repeat(group, count: 10)
        
        let disappear = SKAction.scale(to: 0, duration: 0.5)
        let removeFromParent = SKAction.removeFromParent()
        let actions = [appear, groupWait, disappear, removeFromParent]
        
        cat.run(SKAction.sequence(actions))
        
    }
  
    func spawnEnemy() {
        
        let enemy = SKSpriteNode(imageNamed: "enemy")
        enemy.name = "enemy"
        enemy.position = CGPoint(x: size.width + enemy.size.width / 2,
                                 y: CGFloat.random(min: playableRect.minY + enemy.size.height / 2,
                                                   max: playableRect.maxY - enemy.size.height / 2))
        addChild(enemy)
        
        //these actions are not reversible
        //let actionMidMove = SKAction.move(to: CGPoint(x: size.width / 2, y: playableRect.minY + enemy.size.height / 2), duration: 2.0)
        //let actionMove = SKAction.move(to: CGPoint(x: -enemy.size.width / 2, y: enemy.position.y), duration: 2.0)
        
        //these actions are reversible
        //let actionMidMove = SKAction.moveBy(x: -size.width / 2 - enemy.size.width / 2,
        //                                    y: -playableRect.height / 2 + enemy.size.height / 2,
        //                                    duration: 2.0)
        //let actionMove = SKAction.moveBy(x: -size.width / 2 - enemy.size.width / 2,
        //                                 y: playableRect.height / 2 - enemy.size.height / 2,
        //                                 duration: 2.0)
        
        //let logMessage = SKAction.run() {
        //    print("Boing!")
        //}
        
        //let actionWait = SKAction.wait(forDuration: 1.0)
        //let halfSequence = SKAction.sequence([actionMidMove, actionWait, logMessage, actionMove])
        //let sequence = SKAction.sequence([halfSequence, halfSequence.reversed()])
        
        //let repeatAction = SKAction.repeatForever(sequence)
        
        let actionMove = SKAction.moveTo(x: -enemy.size.width / 2, duration: 4.0)
        let actionRemove = SKAction.removeFromParent()
        
        enemy.run(SKAction.sequence([actionMove, actionRemove]))
        
    }
    
    func startZombieAnimation() {
        
        if zombie.action(forKey: "animation") == nil {
            zombie.run(SKAction.repeatForever(zombieAnimation), withKey: "animation")
        }
        
    }
    
    func stopZombieAnimation() {
        zombie.removeAction(forKey: "animation")
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
        
        if (abs(lastTouchLocation.length() - zombie.position.length()) <= CGFloat(Double(zombieMovePointsPerSec) * dt)) {
            
            zombie.position = lastTouchLocation
            velocity = CGPoint.zero
            stopZombieAnimation()
            
        } else {
            move(sprite: zombie, velocity: velocity)
            
          //  print("zombie position: ( \(zombie.position.x), \(zombie.position.y) )")
          //  print("size position: ( \(size.height), \(size.width) )")
            
            rotate(sprite: zombie, direction: velocity, rotateRadiansPerSec: zombieRotateRadiansPerSec)
            
        }
        
        boundsCheckZombie()
        moveTrain()
        
        if (lives <= 0 && !gameOver) {
            gameOver = true
            print("Losing sucks!")
            
            backgroundMusicPlayer.stop()
            let gameOverScene = GameOverScene(size: size, won: false)
            gameOverScene.scaleMode = scaleMode
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            view?.presentScene(gameOverScene, transition: reveal)
        }
        
    }
    
    func zombieHit(cat: SKSpriteNode) {
        
        cat.name = "train"
        cat.removeAllActions()
        cat.setScale(1)
        cat.zRotation = 0
        
        let greenAction : SKAction = SKAction.colorize(with: SKColor.green, colorBlendFactor: 1.0, duration: 0.2)
        
        let sequence = SKAction.sequence([greenAction])
        cat.run(sequence)
        
        run(catCollisionSound)
        
    }
    
    func zombieHit(enemy: SKSpriteNode) {
        
        isZombieInvincible = true
        let blinkTimes = 10.0
        let duration = 3.0
        
        let blinkAction = SKAction.customAction(withDuration: duration) { node, elapsedTime in
            let slice = duration / blinkTimes
            let remainder = Double(elapsedTime).truncatingRemainder(
                dividingBy: slice)
            node.isHidden = remainder > slice / 2
        }
        
        let setHidden = SKAction.run() { [weak self] in
            self?.zombie.isHidden = false
            self?.isZombieInvincible = false
        }
        
        zombie.run(SKAction.sequence([blinkAction, setHidden]))
        run(enemyCollisionSound)
        
        loseCats()
        lives -= 1
        
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
}























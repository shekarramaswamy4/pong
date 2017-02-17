//
//  GameScene.swift
//  Bamboo Breakout
/**
 * Copyright (c) 2016 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */ 

import SpriteKit
import GameplayKit


let BallCategoryName = "ball"
let GameMessageName = "gameMessage"

let BallCategory   : UInt32 = 0x1 << 0
let WallCategory   : UInt32 = 0x1 << 1
let BlockCategory  : UInt32 = 0x1 << 2
let PaddleCategory : UInt32 = 0x1 << 3
let BorderCategory : UInt32 = 0x1 << 4

//initialize actual game over sound here
let gameOverSound = SKAction.playSoundFileNamed("gameover", waitForCompletion: false)


class GameScene: SKScene, SKPhysicsContactDelegate {
    
    lazy var gameState: GKStateMachine = GKStateMachine(states: [
        WaitingForTap(scene: self),
        Playing(scene: self),
        GameOver(scene: self)])
    
    var score:Int = 0
    var highestScore:Int = 0
    
    var gameWon : Bool = false {
        didSet {
            //where game over sound is played
            run(gameOverSound)
            
            let gameOver = childNode(withName: GameMessageName) as! SKSpriteNode
            var textureName:String = ""
            
            //change medal sets later: 15, 25, 40
            if (score < 15) {
                textureName = "GameOver"
            }
            else if (score < 25) {
                textureName = "GameOverBronze"
            }
            else if (score < 40) {
                textureName = "GameOverSilver"
            }
            else {
                textureName = "GameOverGold"
            }
            let texture = SKTexture(imageNamed: textureName)
            let actionSequence = SKAction.sequence([SKAction.setTexture(texture),
                                                    SKAction.scale(to: 1.75, duration: 0.25)])
            
            
            gameOver.run(actionSequence)

        }
    }
    
    var isFingerOnPaddleL = false
    var isFingerOnPaddleR = false
    var touchTracker:[UITouch:String] = [:]
    
  override func didMove(to view: SKView) {
    super.didMove(to: view)
    
    let borderBody = SKPhysicsBody(edgeLoopFrom: self.frame)
    
    borderBody.friction = 0
    self.physicsBody = borderBody
    
    physicsWorld.gravity = CGVector(dx: 0.0, dy: 0.0)
    physicsWorld.contactDelegate = self
    
    let ball = childNode(withName: BallCategoryName) as! SKSpriteNode
    
    let scoreboard = childNode(withName: "scoreboard") as! SKLabelNode
    scoreboard.text = "0"
    
    let highscore = childNode(withName: "highscore") as! SKLabelNode
    var savedScore:Int = 0
    UserDefaults.standard.register(defaults: ["HighestScore": 0])
    savedScore = UserDefaults.standard.value(forKey: "HighestScore") as! Int

    highscore.text = String(savedScore)
    
    
    
    let paddleL = childNode(withName: "paddleL") as! SKSpriteNode
    let paddleR = childNode(withName: "paddleR") as! SKSpriteNode
    
    let leftRect = CGRect(x: frame.origin.x, y: frame.origin.y, width: 1, height: frame.size.height)
    let left = SKNode()
    left.physicsBody = SKPhysicsBody(edgeLoopFrom: leftRect)
    addChild(left)
    
    let rightRect = CGRect(x: frame.maxX, y: frame.origin.y, width: 1, height: frame.size.height)
    let right = SKNode()
    right.physicsBody = SKPhysicsBody(edgeLoopFrom: rightRect)
    addChild(right)
    
    left.physicsBody!.categoryBitMask = WallCategory
    right.physicsBody!.categoryBitMask = WallCategory
    ball.physicsBody!.categoryBitMask = BallCategory
    paddleL.physicsBody!.categoryBitMask = PaddleCategory
    paddleR.physicsBody!.categoryBitMask = PaddleCategory
    borderBody.categoryBitMask = BorderCategory
    
    ball.physicsBody!.contactTestBitMask = WallCategory | PaddleCategory
    
    let gameMessage = SKSpriteNode(imageNamed: "TapToPlay")
    gameMessage.name = GameMessageName
    gameMessage.position = CGPoint(x: frame.midX, y: frame.midY)
    gameMessage.zPosition = 4
    gameMessage.setScale(0.0)
    addChild(gameMessage)
    
    //put background music here
    let randomNum:UInt32 = arc4random_uniform(10) + 1
    let audioName = "Beat" + String(randomNum) + ".mp3"
    let backgroundMusic = SKAudioNode(fileNamed: audioName)
    backgroundMusic.autoplayLooped = true
    self.addChild(backgroundMusic)
    
    let skView = self.view! as SKView
    skView.showsFPS = false
    skView.showsNodeCount = false
    
    gameState.enter(WaitingForTap.self)
  }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        switch gameState.currentState {
        case is WaitingForTap:
            gameState.enter(Playing.self)
            
        case is Playing:
            for touch in touches {
                let touchLocation = touch.location(in: self)
                let node = atPoint(touchLocation)
                if let name = node.name {
                    if name == "leftClicker" || name == "paddleL" {
                        print("Began touch on paddleL")
                        touchTracker[touch] = name
                    }
                    else if name == "rightClicker" || name == "paddleR" {
                        print("Began touch on paddleR")
                        touchTracker[touch] = name
                    }
                }
            }
            
        case is GameOver:
            let newScene = GameScene(fileNamed:"GameScene")
            newScene!.scaleMode = .aspectFit
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            self.view?.presentScene(newScene!, transition: reveal)
        
        default: break
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let touchLocation = touch.location(in: self)
            let previousLocation = touch.previousLocation(in: self)
            var name:String = ""
            if touchTracker[touch] == "leftClicker" || touchTracker[touch] == "paddleL" {
                name = "paddleL"
            }
            else if touchTracker[touch] == "rightClicker" || touchTracker[touch] == "paddleR"{
                name = "paddleR"
            }
            if (name != "") {
            
            if let paddle = childNode(withName: name) as? SKSpriteNode {
                
                var paddleY = paddle.position.y + (touchLocation.y - previousLocation.y)
                
                paddleY = max(paddle.size.height/2, paddleY)
                paddleY = min(size.height - paddle.size.height/2, paddleY)
                
                paddle.position = CGPoint(x: paddle.position.x, y: paddleY)
                
                paddle.position = CGPoint(x:paddle.position.x, y:touchLocation.y)
                }
                
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if touchTracker[touch] != nil {
                touchTracker.removeValue(forKey: touch)
            }
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        
        if gameState.currentState is Playing {
            
            var firstBody: SKPhysicsBody
            var secondBody: SKPhysicsBody
            
            if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
                firstBody = contact.bodyA
                secondBody = contact.bodyB
            } else {
                firstBody = contact.bodyB
                secondBody = contact.bodyA
            }
            
            if firstBody.categoryBitMask == BallCategory && secondBody.categoryBitMask == WallCategory {
                let scoreboard = childNode(withName: "scoreboard") as! SKLabelNode
                let current = Int(scoreboard.text!)
                score = current!
                
                let savedScore = UserDefaults.standard.value(forKey: "HighestScore") as! Int
                if (current! > savedScore) {
                    UserDefaults.standard.set(current!, forKey: "HighestScore")
                }

                gameState.enter(GameOver.self)
                gameWon = false
                
            }
            
            if firstBody.categoryBitMask == BallCategory && secondBody.categoryBitMask == PaddleCategory {
                let scoreboard = childNode(withName: "scoreboard") as! SKLabelNode
                var current = Int(scoreboard.text!)
                current = current! + 1
                scoreboard.text = String(describing: current!)
                
                //could change later
                if (current == 2 || current == 10 || current == 20)
                {
                    let curBall = childNode(withName: BallCategoryName) as! SKSpriteNode
                    let ball = curBall.copy() as! SKSpriteNode
                    ball.physicsBody?.restitution = 1
                    ball.physicsBody?.linearDamping = 0
                    ball.physicsBody?.linearDamping = 0
                    ball.physicsBody?.velocity = CGVector(dx: (ball.physicsBody?.velocity.dx.multiplied(by: -1.0))!, dy: (ball.physicsBody?.velocity.dy)!)
                    ball.position = CGPoint(x: frame.midX, y: frame.midY)
                    self.addChild(ball)
                }
            }
        }
    }
    
    func randomFloat(from: CGFloat, to: CGFloat) -> CGFloat {
        let rand: CGFloat = CGFloat(Float(arc4random()) / 0xFFFFFFFF)
        return (rand) * (to - from) + from
    }
    
    override func update(_ currentTime: TimeInterval) {
        gameState.update(deltaTime: currentTime)
    }
  
}

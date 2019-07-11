//
//  DrawFile.swift
//  Touch Tracker
//
//  Created by Ahmed Aboelela on 7/11/19.
//  Copyright © 2019 Ahmed Aboelela. All rights reserved.
//

import UIKit

class DrawView: UIView, UIGestureRecognizerDelegate{
    var moveGesture: UIPanGestureRecognizer!
    var currentLine = [NSValue:Line]()
    var finishedLines = [Line]()
    var selectedIndex: Int?{
        didSet{
            if selectedIndex == nil{
                let menu = UIMenuController.shared
                menu.setMenuVisible(false, animated: true)
            }
        }
    }
    
    @IBInspectable var finishedLineColor: UIColor = UIColor.black{
        didSet{
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var currentLineColor: UIColor = UIColor.red{
        didSet{
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var lineThickness: CGFloat = 10{
        didSet{
            setNeedsDisplay()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        let doubleTapRecognizer = UITapGestureRecognizer(target: self,action: #selector(DrawView.doubleTap(_:)))
        doubleTapRecognizer.numberOfTapsRequired = 2
        doubleTapRecognizer.delaysTouchesBegan = true
        addGestureRecognizer(doubleTapRecognizer)
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(DrawView.tap(_:)))
        tapRecognizer.numberOfTapsRequired = 1
        tapRecognizer.delaysTouchesBegan = true
        tapRecognizer.require(toFail: doubleTapRecognizer)
        addGestureRecognizer(tapRecognizer)
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(DrawView.longPress(_:)))
        addGestureRecognizer(longPressRecognizer)
        
        moveGesture = UIPanGestureRecognizer(target: self, action: #selector(DrawView.moveLine(_:)))
        moveGesture.delegate = self
        moveGesture.cancelsTouchesInView = false
        addGestureRecognizer(moveGesture)
    }
    
    @objc func doubleTap(_ gestureRecognizer: UIGestureRecognizer){
        currentLine.removeAll()
        finishedLines.removeAll()
        selectedIndex = nil
        setNeedsDisplay()
    }
    
    @objc func deleteLine(_ sender: UIMenuController){
        if let index = selectedIndex{
            finishedLines.remove(at: index)
            selectedIndex = nil
            setNeedsDisplay()
        }
    }
    
    @objc func longPress(_ sender: UIGestureRecognizer){
        setNeedsDisplay()
        if(sender.state == .began){
            let point = sender.location(in: self)
            selectedIndex = indexOfLine(at: point)
            
            if selectedIndex != nil {
                currentLine.removeAll()
            }
            
        }else if(sender.state == .ended){
            selectedIndex = nil
        }
        setNeedsDisplay()
    }
    
    @objc func moveLine(_ sender: UIPanGestureRecognizer){
        if let index = selectedIndex {
            // When the pan recognizer changes its position...
            if moveGesture.state == .changed {
                // How far has the pan moved?
                let translation = moveGesture.translation(in: self)
                // Add the translation to the current beginning and end points of the line
                // Make sure there are no copy and paste typos!
                finishedLines[index].begin.x += translation.x
                finishedLines[index].begin.y += translation.y
                finishedLines[index].end.x += translation.x
                finishedLines[index].end.y += translation.y
                moveGesture.setTranslation(CGPoint.zero, in: self)
                // Redraw the screen
                setNeedsDisplay()
            }
        } else {
            // If no line is selected, do not do anything
            return
        }
    }
    
    override var canBecomeFirstResponder: Bool{
        return true
    }
    
    @objc func tap(_ gestureRecognizer: UIGestureRecognizer){
        let point = gestureRecognizer.location(in: self)
        selectedIndex = indexOfLine(at: point)
        
        let menu = UIMenuController.shared
        if selectedIndex != nil{
            becomeFirstResponder()
            let deleteItem = UIMenuItem(title: "Delete", action: #selector(DrawView.deleteLine(_:)))
            menu.menuItems = [deleteItem]
            let targetRect = CGRect(x: point.x, y: point.y, width: 2, height: 2)
            menu.setTargetRect(targetRect, in: self)
            menu.setMenuVisible(true, animated: true)
        }else{
            menu.setMenuVisible(false, animated: true)
        }
        
        
        setNeedsDisplay()
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func stroke(_ line: Line){
        let path = UIBezierPath()
        path.lineWidth = lineThickness
        path.lineCapStyle = .round
        path.move(to: line.begin)
        path.addLine(to: line.end)
        path.stroke()
    }
    
    override func draw(_ rect: CGRect){
        finishedLineColor.setStroke()
        for line in finishedLines{
            stroke(line)
        }
        
        currentLineColor.setStroke()
        for (_, line) in currentLine {
            stroke(line)
        }
        
        if let index = selectedIndex{
            UIColor.purple.setStroke()
            let selectedLine = finishedLines[index]
            stroke(selectedLine)
        }
    }
    
    func indexOfLine(at point: CGPoint) -> Int? {
        // Find a line close to point
        for (index, line) in finishedLines.enumerated() {
            let begin = line.begin
            let end = line.end
            // Check a few points on the line
            for t in stride(from: CGFloat(0), to: 1.0, by: 0.05) {
                let x = begin.x + ((end.x - begin.x) * t)
                let y = begin.y + ((end.y - begin.y) * t)
                // If the tapped point is within 20 points, let's return this line
                if hypot(x - point.x, y - point.y) < 20.0 {
                    return index
                }
            }
        }
        // If nothing is close enough to the tapped point, then we did not select a line
        return nil
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches{
            let location = touch.location(in: self)
            let key = NSValue(nonretainedObject: touch)
            currentLine[key] = Line(begin: location, end: location)
            setNeedsDisplay()
        }
    }
    
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        for touch in touches{
            let location = touch.location(in: self)
            let key = NSValue(nonretainedObject: touch)
            currentLine[key]?.end = location
        }
        setNeedsDisplay()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        for touch in touches{
            let location = touch.location(in: self)
            let key = NSValue(nonretainedObject: touch)
            currentLine[key]?.end = location
            finishedLines.append(currentLine[key]!)
            currentLine.removeValue(forKey: key)
        }
        setNeedsDisplay()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        currentLine.removeAll()
        setNeedsDisplay()
    }
}

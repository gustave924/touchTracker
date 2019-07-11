//
//  DrawFile.swift
//  Touch Tracker
//
//  Created by Ahmed Aboelela on 7/11/19.
//  Copyright © 2019 Ahmed Aboelela. All rights reserved.
//

import UIKit

class DrawView: UIView{
    var currentLine = [NSValue:Line]()
    var finishedLines = [Line]()
    
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

//
//  TYRangePointList.swift
//  TYRingSlider
//
//  Created by TeemoYang on 2024/4/10.
//

import UIKit

class TYRangePointList: NSObject {
    private(set) var head: TYRangePoint? {
        didSet {
            print("777777: \(head)")
        }
    }
    private var count: Int = 0
    
    // 判断链表是否为空
    var isEmpty: Bool {
        return head == nil
    }
    
    // 返回链表中的节点数
    var nodeCount: Int {
        return count
    }
    
    // 添加新元素到链表
    func append(value: CGFloat, isStart: Bool, isEnd: Bool, isCross: Bool, lineTag: Int) {
        let newPoint = TYRangePoint()
        newPoint.value = value
        newPoint.isStart = isStart
        newPoint.isEnd = isEnd
        newPoint.isCross = isCross
        newPoint.lineTag = lineTag
        newPoint.index = count
        
        if let headPoint = head {
            // 如果链表不为空，找到尾节点，并设置新节点为尾节点的下一个节点，同时将新节点的前一个节点设为尾节点
            var currentPoint = headPoint
            while let nextPoint = currentPoint.next, nextPoint !== headPoint {
                currentPoint = nextPoint
            }
            currentPoint.next = newPoint
            newPoint.previous = currentPoint
            newPoint.next = headPoint // 完成环形
            headPoint.previous = newPoint
        } else {
            // 如果链表为空，新节点自己形成一个环
            head = newPoint
            newPoint.next = newPoint
            newPoint.previous = newPoint
        }
        
        count += 1 // 更新节点计数器
    }
    
    // 从指定节点开始遍历链表
    func traverse(from node: TYRangePoint? = nil, _ body: (TYRangePoint) -> Bool) {
        guard let startNode = node ?? head else { return }
        var currentNode = startNode
        repeat {
            let shouldContinue = body(currentNode)
            guard let nextNode = currentNode.next, shouldContinue else { break }
            currentNode = nextNode
        } while currentNode !== startNode
    }
    
    // 示例：删除链表中所有的节点（重置链表）
    func removeAll() {
        head = nil
        count = 0 // 重置节点计数器
    }
    
    func removeNode(withValue value: CGFloat) {
        guard let startNode = head else { return }
        var currentNode: TYRangePoint? = startNode
        var previousNode: TYRangePoint? = nil
        
        repeat {
            if currentNode?.value == value {
                if currentNode === head {
                    if currentNode?.next === head {
                        head = nil // 如果链表只有一个节点，将头节点置为nil
                    } else {
                        head = currentNode?.next
                    }
                }
                
                previousNode?.next = currentNode?.next
                currentNode?.next?.previous = previousNode
                
                if currentNode?.next === startNode { // 如果是环形链表的最后一个节点
                    head?.previous = previousNode
                }
                
                if currentNode === currentNode?.next { // 如果链表只剩下一个节点，移除后将head置为nil
                    head = nil
                }
                
                count -= 1 // 更新节点计数器
                break
            }
            
            previousNode = currentNode
            currentNode = currentNode?.next
        } while currentNode !== startNode
    }
    
    func remove(node: TYRangePoint) {
        // 如果链表为空或者节点是nil，直接返回
        guard let _ = head, let _ = node.next, let _ = node.previous else { return }

        // 处理链表只有一个节点的情况
        if node === node.next {
            head = nil
        } else {
            node.previous?.next = node.next
            node.next?.previous = node.previous

            // 如果移除的是头节点，更新头节点为下一个节点
            if node === head {
                head = node.next
            }
        }

        // 清除移除节点的前后关系，以便Swift的ARC可以正确回收
        node.next = nil
        node.previous = nil

        // 更新节点计数器
        count -= 1
    }


    
    func findFirstNode() -> TYRangePoint? {
        guard let startNode = head else { return nil }
        var currentNode: TYRangePoint? = startNode
        repeat {
            if currentNode?.isStart == true {
                return currentNode
            }
            currentNode = currentNode?.next
        } while currentNode !== startNode && currentNode != nil
        return nil
    }
    
    func findEndNode() -> TYRangePoint? {
        guard let startNode = head else { return nil }
        var currentNode: TYRangePoint? = startNode
        repeat {
            if currentNode?.isEnd == true {
                return currentNode
            }
            currentNode = currentNode?.next
        } while currentNode !== startNode && currentNode != nil
        return nil
    }
}

import Foundation
import UIKit
import Postbox
import AsyncDisplayKit
import Display
import SwiftSignalKit

private let titleFont = UIFont.systemFont(ofSize: 13.0)

class ChatUnreadItem: ListViewItem {
    let index: MessageIndex
    let theme: ChatPresentationThemeData
    let strings: PresentationStrings
    let header: ChatMessageDateHeader
    
    init(index: MessageIndex, theme: ChatPresentationThemeData, strings: PresentationStrings) {
        self.index = index
        self.theme = theme
        self.strings = strings
        self.header = ChatMessageDateHeader(timestamp: index.timestamp, theme: theme, strings: strings)
    }
    
    func nodeConfiguredForParams(async: @escaping (@escaping () -> Void) -> Void, params: ListViewItemLayoutParams, previousItem: ListViewItem?, nextItem: ListViewItem?, completion: @escaping (ListViewItemNode, @escaping () -> (Signal<Void, NoError>?, () -> Void)) -> Void) {
        async {
            let node = ChatUnreadItemNode()
            node.layoutForParams(params, item: self, previousItem: previousItem, nextItem: nextItem)
            completion(node, {
                return (nil, {})
            })
        }
    }
    
    public func updateNode(async: @escaping (@escaping () -> Void) -> Void, node: ListViewItemNode, params: ListViewItemLayoutParams, previousItem: ListViewItem?, nextItem: ListViewItem?, animation: ListViewItemUpdateAnimation, completion: @escaping (ListViewItemNodeLayout, @escaping () -> Void) -> Void) {
        if let node = node as? ChatUnreadItemNode {
            Queue.mainQueue().async {
                let nodeLayout = node.asyncLayout()
                
                async {
                    let dateAtBottom = !chatItemsHaveCommonDateHeader(self, nextItem)
                    
                    let (layout, apply) = nodeLayout(self, params, dateAtBottom)
                    Queue.mainQueue().async {
                        completion(layout, {
                            apply()
                        })
                    }
                }
            }
        } else {
            assertionFailure()
        }
    }
}

class ChatUnreadItemNode: ListViewItemNode {
    var item: ChatUnreadItem?
    let backgroundNode: ASImageNode
    let labelNode: TextNode
    
    private var theme: ChatPresentationThemeData?
    
    private let layoutConstants = ChatMessageItemLayoutConstants()
    
    init() {
        self.backgroundNode = ASImageNode()
        self.backgroundNode.isLayerBacked = true
        self.backgroundNode.displayWithoutProcessing = true
        
        self.labelNode = TextNode()
        self.labelNode.isLayerBacked = true
        
        super.init(layerBacked: true, dynamicBounce: true, rotated: true)
        
        self.addSubnode(self.backgroundNode)
        
        self.addSubnode(self.labelNode)
        
        self.transform = CATransform3DMakeRotation(CGFloat.pi, 0.0, 0.0, 1.0)
        
        self.scrollPositioningInsets = UIEdgeInsets(top: 5.0, left: 0.0, bottom: 6.0, right: 0.0)
        self.canBeUsedAsScrollToItemAnchor = false
    }
    
    override func animateInsertion(_ currentTimestamp: Double, duration: Double, short: Bool) {
        super.animateInsertion(currentTimestamp, duration: duration, short: short)
        
        self.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.2)
    }
    
    override func animateAdded(_ currentTimestamp: Double, duration: Double) {
        self.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.2)
    }
    
    override func layoutForParams(_ params: ListViewItemLayoutParams, item: ListViewItem, previousItem: ListViewItem?, nextItem: ListViewItem?) {
            if let item = item as? ChatUnreadItem {
            let dateAtBottom = !chatItemsHaveCommonDateHeader(item, nextItem)
            let (layout, apply) = self.asyncLayout()(item, params, dateAtBottom)
            apply()
            self.contentSize = layout.contentSize
            self.insets = layout.insets
        }
    }
    
    func asyncLayout() -> (_ item: ChatUnreadItem, _ params: ListViewItemLayoutParams, _ dateAtBottom: Bool) -> (ListViewItemNodeLayout, () -> Void) {
        let labelLayout = TextNode.asyncLayout(self.labelNode)
        let layoutConstants = self.layoutConstants
        let currentTheme = self.theme
        
        return { item, params, dateAtBottom in
            var updatedBackgroundImage: UIImage?
            if currentTheme != item.theme {
                updatedBackgroundImage = PresentationResourcesChat.chatUnreadBarBackgroundImage(item.theme.theme)
            }
            
            let (size, apply) = labelLayout(TextNodeLayoutArguments(attributedString: NSAttributedString(string: item.strings.Conversation_UnreadMessages, font: titleFont, textColor: item.theme.theme.chat.serviceMessage.unreadBarTextColor), backgroundColor: nil, maximumNumberOfLines: 1, truncationType: .end, constrainedSize: CGSize(width: params.width - params.leftInset - params.rightInset, height: CGFloat.greatestFiniteMagnitude), alignment: .natural, cutout: nil, insets: UIEdgeInsets()))
            
            let backgroundSize = CGSize(width: params.width, height: 25.0)
            
            return (ListViewItemNodeLayout(contentSize: CGSize(width: params.width, height: 25.0), insets: UIEdgeInsets(top: 6.0 + (dateAtBottom ? layoutConstants.timestampHeaderHeight : 0.0), left: 0.0, bottom: 5.0, right: 0.0)), { [weak self] in
                if let strongSelf = self {
                    strongSelf.item = item
                    strongSelf.theme = item.theme
                    
                    if let updatedBackgroundImage = updatedBackgroundImage {
                        strongSelf.backgroundNode.image = updatedBackgroundImage
                    }
                    
                    let _ = apply()
                    
                    strongSelf.backgroundNode.frame = CGRect(origin: CGPoint(x: 0.0, y: 0.0), size: backgroundSize)
                    strongSelf.labelNode.frame = CGRect(origin: CGPoint(x: floorToScreenPixels((backgroundSize.width - size.size.width) / 2.0), y: floorToScreenPixels((backgroundSize.height - size.size.height) / 2.0)), size: size.size)
                }
            })
        }
    }
    
    override public func header() -> ListViewItemHeader? {
        if let item = self.item {
            return item.header
        } else {
            return nil
        }
    }
    
    override public func animateRemoved(_ currentTimestamp: Double, duration: Double) {
        super.animateRemoved(currentTimestamp, duration: duration)
        
        self.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.2, removeOnCompletion: false)
    }
}

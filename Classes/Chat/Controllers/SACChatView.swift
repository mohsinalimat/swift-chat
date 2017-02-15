//
//  SACChatView.swift
//  SAChat
//
//  Created by SAGESSE on 26/12/2016.
//  Copyright © 2016-2017 SAGESSE. All rights reserved.
//

import UIKit

public protocol SACChatViewDataSource: class {
    
    func numberOfItems(in chatView: SACChatView)
    
    func chatView(_ chatView: SACChatView, itemAtIndexPath: IndexPath)
    
}

public protocol SACChatViewDelegate: class {
    
    func chatView(_ chatView: SACChatView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool
    func chatView(_ chatView: SACChatView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool
    func chatView(_ chatView: SACChatView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?)
}


@objc open class SACChatView: UIView {
    
    public init(frame: CGRect, chatViewLayout: SACChatViewLayout) {
        // init data
        _chatViewData = SACChatViewData()
        // init to layout & container view
        _chatViewLayout = chatViewLayout
        _chatContainerView = SACChatContainerView(frame: frame, collectionViewLayout: chatViewLayout)
        // init super
        super.init(frame: frame)
        // init other data
        _commonInit()
    }
    public required init?(coder aDecoder: NSCoder) {
        // decode layout
        guard let chatViewLayout = SACChatViewLayout(coder: aDecoder) else {
            return nil
        }
        // decode container view
        guard let chatContainerView = SACChatContainerView(coder: aDecoder) else {
            return nil
        }
        // init data
        _chatViewData = SACChatViewData()
        // init to layout & container view
        _chatViewLayout = chatViewLayout
        _chatContainerView = chatContainerView
        // init super
        super.init(coder: aDecoder)
        // init other data
        _commonInit()
    }
    
    open weak var delegate: SACChatViewDelegate?
    open weak var dataSource: SACChatViewDataSource?
    
    func insert(_ newMessage: SACMessageType, at index: Int) {
        _batchBegin()
        _batchItems.append(.insert(newMessage, at: index))
        _batchCommit()
    }
    func insert(contentsOf newMessages: Array<SACMessageType>, at index: Int) {
        _batchBegin()
        _batchItems.append(contentsOf: newMessages.map({ .insert($0, at: index) }))
        _batchCommit()
    }
    
    func update(_ newMessage: SACMessageType, at index: Int) {
        _batchBegin()
        _batchItems.append(.update(newMessage, at: index))
        _batchCommit()
    }
    
    func remove(at index: Int) {
        _batchBegin()
        _batchItems.append(.remove(at: index))
        _batchCommit()
    }
    func remove(contentOf indexs: Array<Int>) {
        _batchBegin()
        _batchItems.append(contentsOf: indexs.map({ .remove(at: $0) }))
        _batchCommit()
    }
    
    func move(at index1: Int, to index2: Int) {
        _batchBegin()
        _batchItems.append(.move(at: index1, to: index2))
        _batchCommit()
    }
    
    func append(_ newMessage: SACMessageType) {
        insert(newMessage, at: _chatViewData.count)
    }
    func append(contentsOf newMessages: Array<SACMessageType>) {
        insert(contentsOf: newMessages, at: _chatViewData.count)
    }
    
    fileprivate func _batchBegin() {
        objc_sync_enter(_batchItems)
        _batchRequiredCount = max(_batchRequiredCount + 1, 1)
        objc_sync_exit(_batchItems)
    }
    fileprivate func _batchCommit() {
        objc_sync_enter(_batchItems)
        _batchRequiredCount = max(_batchRequiredCount - 1, 0)
        guard _batchRequiredCount == 0 else {
            objc_sync_exit(_batchItems)
            return
        }
        let items = _batchItems
        _batchItems.removeAll()
        objc_sync_exit(_batchItems)
        
        let update = SACChatViewUpdate(model: _chatViewData)
        update.apply(with: items, to: _chatContainerView)
    }
    
    fileprivate lazy var _batchItems: Array<SACChatViewUpdateItem> = []
    fileprivate lazy var _batchRequiredCount: Int = 0
    
    private func _commonInit() {
        
        backgroundColor = .white
        
        _chatContainerView.allowsSelection = false
        _chatContainerView.allowsMultipleSelection = false
        _chatContainerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        _chatContainerView.keyboardDismissMode = .interactive
        _chatContainerView.backgroundColor = .clear
        _chatContainerView.dataSource = self
        _chatContainerView.delegate = self
        
        addSubview(_chatContainerView)
    }
    
    fileprivate var _chatViewData: SACChatViewData
    
    fileprivate var _chatViewLayout: SACChatViewLayout
    fileprivate var _chatContainerView: SACChatContainerView
    
    fileprivate lazy var _chatContainerRegistedTypes: Set<String> = []
}

internal class SACChatContainerView: UICollectionView {
    
    
}



extension SACChatView: UICollectionViewDataSource, SACChatViewLayoutDelegate {
    
    open dynamic var contentSize: CGSize {
        set { return _chatContainerView.contentSize = newValue }
        get { return _chatContainerView.contentSize }
    }
    open dynamic var contentOffset: CGPoint {
        set { return _chatContainerView.contentOffset = newValue }
        get { return _chatContainerView.contentOffset }
    }
    open dynamic var contentInset: UIEdgeInsets {
        set { return _chatContainerView.contentInset = newValue }
        get { return _chatContainerView.contentInset }
    }
    open dynamic var scrollIndicatorInsets: UIEdgeInsets {
        set { return _chatContainerView.scrollIndicatorInsets = newValue }
        get { return _chatContainerView.scrollIndicatorInsets }
    }
    
    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return _chatViewData.count
    }
    
    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let message = _chatViewData[indexPath.item]
        
        let options = (message.options.showsCard.hashValue << 0) | (message.options.showsAvatar.hashValue << 1)
        let alignment = message.options.alignment.rawValue
        let identifier = NSStringFromClass(type(of: message.content)) + ".\(alignment)"
        
        if !_chatContainerRegistedTypes.contains(identifier) {
            _chatContainerRegistedTypes.insert(identifier)
            _chatContainerView.register(SACChatViewCell.self, forCellWithReuseIdentifier: identifier)
        }
        
        return _chatContainerView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath)
    }
    
    open func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        //cell.backgroundColor = .random
    }
    
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, itemAt indexPath: IndexPath) -> SACMessageType {
        return _chatViewData[indexPath.item]
    }
    
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let collectionViewLayout = collectionViewLayout as? SACChatViewLayout else {
            return .zero
        }
        guard let layoutAttributesInfo = collectionViewLayout.layoutAttributesInfoForItem(at: indexPath) else {
            return .zero
        }
        let size = layoutAttributesInfo.layoutedBoxRect(with: .all).size
        return .init(width: collectionView.frame.width, height: size.height)
    }
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAvatarOf style: SACMessageStyle) -> CGSize {
        // 78 * 78
        return .init(width: 39, height: 39)
    }
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemCardOf style: SACMessageStyle) -> CGSize {
        return .init(width: 0, height: 18)
    }
    
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForItemOf style: SACMessageStyle) -> UIEdgeInsets {
        switch style {
        case .bubble:
            // bubble content edg, 2x
            // +----12--+-+---+
            // |        | |   |
            // 16       4 40  16
            // |        | |   |
            // +----12--+-+---+
            return .init(top: 6, left: 8, bottom: 6, right: 2 + 20 + 8)
            
        case .notice:
            // default edg
            // +----10----+
            // 20         20
            // +----10----+
            return .init(top: 10, left: 20, bottom: 10, right: 20)
            
        default:
            // default edg
            // +----10----+
            // 10         10
            // +----10----+
            return .init(top: 10, left: 10, bottom: 10, right: 10)
        }
    }
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForItemCardOf style: SACMessageStyle) -> UIEdgeInsets {
        return .init(top: 0, left: 8, bottom: 0, right: 8)
    }
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForItemAvatarOf style: SACMessageStyle) -> UIEdgeInsets {
        return .init(top: 2, left: 2, bottom: 2, right: 2)
    }
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForItemBubbleOf style: SACMessageStyle) -> UIEdgeInsets {
        return .init(top: -2, left: 0, bottom: -2, right: 0)
    }
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForItemContentOf style: SACMessageStyle) -> UIEdgeInsets {
        switch style {
        case .bubble:
            // bubble image edg, scale: 2x, radius: 15
            // /--------16-------\
            // |  +-----04-----+ |
            // 20 04          04 20
            // |  +-----04-----+ |
            // \--------16-------/
            return .init(top: 8 + 2, left: 10 + 2, bottom: 8 + 2, right: 10 + 2)
            
        case .notice:
            // notice edg
            // /------4-------\
            // 10             10
            // \------4-------/
            return .init(top: 4, left: 10, bottom: 4, right: 10)
            
        }
    }
    
    open func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    open func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        if action == #selector(copy(_:)) {
            return true
        }
        if action == #selector(paste(_:)) {
            return true
        }
        if action == #selector(delete(_:)) {
            return true
        }
        return false
    }
    open func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
        logger.debug("\(indexPath) \(action)")
        
        if action == #selector(delete(_:)) {
            remove(at: indexPath.item)
        }
        if action == #selector(paste(_:)) {
            move(at: indexPath.item, to: _chatViewData.count - 1)
            //move(at: indexPath.item, to: indexPath.item + 1)
        }
    }
}

//class SACChatView: UICollectionView {
//    
//    override init(frame: CGRect, collectionViewLayout: UICollectionViewLayout) {
//        super.init(frame: frame, collectionViewLayout: collectionViewLayout)
//        _commonInit()
//    }
//    required init?(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)
//        _commonInit()
//    }
//
//    
//    //UIKit`-[UICollectionView _shouldShowMenuForCell:]:
//    //UIKit`-[UICollectionViewCell _gestureRecognizerShouldBegin:]:
////    private dynamic func _gestureRecognizerShouldBegin(_ sender: UILongPressGestureRecognizer) {
////    }
//    
//    private func _commonInit() {
//       
//        backgroundColor = .white
//        
//        allowsSelection = false
//        allowsMultipleSelection = false
//    }
//
////    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
////        guard gestureRecognizer == _menuGesture else {
////            return super.gestureRecognizerShouldBegin(gestureRecognizer)
////        }
////        
////        return false
////    }
////    
//    
//    private lazy var _chatViewData: SACChatViewData = SACChatViewData(chatView: self)
//}

//extension SACChatView: UIGestureRecognizerDelegate {
//}


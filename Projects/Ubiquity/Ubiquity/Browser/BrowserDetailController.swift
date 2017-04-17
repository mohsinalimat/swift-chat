//
//  BrowserDetailController.swift
//  Ubiquity
//
//  Created by sagesse on 16/03/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

//@objc protocol BrowseDetailViewDelegate {
//    
//    @objc optional func browseDetailView(_ browseDetailView: Any, _ containerView: IBScrollView, shouldBeginRotationing view: UIView?) -> Bool
//    @objc optional func browseDetailView(_ browseDetailView: Any, _ containerView: IBScrollView, didEndRotationing view: UIView?, atOrientation orientation: UIImageOrientation) // scale between minimum and maximum. called after any 'bounce' animations
//}

internal class BrowserDetailController: UICollectionViewController {
    
    internal init(container: Container, at indexPath: IndexPath) {
        let collectionViewLayout = BrowserDetailLayout()
        
        collectionViewLayout.scrollDirection = .horizontal
        collectionViewLayout.minimumLineSpacing = -extraContentInset.left * 2
        collectionViewLayout.minimumInteritemSpacing = -extraContentInset.right * 2
        collectionViewLayout.headerReferenceSize = CGSize(width: -extraContentInset.left, height: 0)
        collectionViewLayout.footerReferenceSize = CGSize(width: -extraContentInset.right, height: 0)

        self.container = container
        super.init(collectionViewLayout: collectionViewLayout)
        // setup some default
        _currentIndexPath = indexPath
    }
    internal required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    internal override func loadView() {
        super.loadView()
        // setup controller
        title = "Detail"
        automaticallyAdjustsScrollViewInsets = false
        
        // setup view
        view.clipsToBounds = true
        view.backgroundColor = .white
        
        // setup gesture recognizer
        interactiveDismissGestureRecognizer.delegate = self
        interactiveDismissGestureRecognizer.maximumNumberOfTouches = 1
        interactiveDismissGestureRecognizer.delaysTouchesEnded = true
        interactiveDismissGestureRecognizer.addTarget(self, action: #selector(dismiss(_:)))
        view.addGestureRecognizer(interactiveDismissGestureRecognizer)
        
        // setup colleciton view
        collectionView?.frame = UIEdgeInsetsInsetRect(view.bounds, extraContentInset)
        collectionView?.scrollsToTop = false
        collectionView?.isPagingEnabled = true
        collectionView?.alwaysBounceVertical = false
        collectionView?.alwaysBounceHorizontal = true
        collectionView?.showsVerticalScrollIndicator = false
        collectionView?.showsHorizontalScrollIndicator = false
        collectionView?.allowsMultipleSelection = false
        collectionView?.allowsSelection = false
        collectionView?.backgroundColor = .white
        collectionView?.register(BrowserDetailCell.dynamic(with: UIImageView.self), forCellWithReuseIdentifier: "ASSET-DETAIL-IMAGE")
        
        // setup indicator 
        indicatorItem.delegate = self
        indicatorItem.dataSource = self
        
        // setup toolbar items
        let toolbarItems = [
            indicatorItem,
            UIBarButtonItem(barButtonSystemItem: .action, target: nil, action: nil),
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(barButtonSystemItem: .trash, target: nil, action: nil)
        ]
        setToolbarItems(toolbarItems, animated: true)
    }
    
    internal override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let indexPath = _currentIndexPath else {
            return
        }
        UIView.performWithoutAnimation {
            indicatorItem.scrollToItem(at: indexPath, animated: false)
            collectionView?.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
        }
    }
    
    internal override func viewWillAppear(_ animated: Bool) {
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        super.viewWillAppear(animated)
    }
    internal override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
//    internal override func viewWillLayoutSubviews() {
//        super.viewWillLayoutSubviews()
//        _updateVisableCellContentInsetIfNeeded()
//    }
    
    // MARK: internal var
    
    internal var container: Container
    internal var animator: Animator? {
        willSet {
            ub_transitioningDelegate = newValue
        }
    }
    
    internal let indicatorItem = IndicatorItem()
    internal let interactiveDismissGestureRecognizer = UIPanGestureRecognizer()
    
    internal let extraContentInset = UIEdgeInsetsMake(0, -20, 0, -20)
    
    internal var vaildContentOffset = CGPoint.zero
    
    internal var ignoreContentOffsetChange: Bool {
        objc_sync_enter(self)
        let result = _ignoreContentOffsetChange
        objc_sync_enter(self)
        return result
    }
    
    internal var currentIndexPath: IndexPath? {
        return _currentIndexPath
    }
    
    // MARK: private ivar
    
    // 转场
    fileprivate var _transitionIsInteractiving: Bool = false
    fileprivate var _transitionAtLocation: CGPoint = .zero
    fileprivate var _transitionContext: TransitioningContext?
    
    // 插入删除的时候必须清除
    fileprivate var _interactivingFromIndex: Int?
    fileprivate var _interactivingFromIndexPath: IndexPath?
    fileprivate var _interactivingToIndex: Int?
    fileprivate var _interactivingToIndexPath: IndexPath?
    
    fileprivate var _currentItem: UICollectionViewLayoutAttributes?
    fileprivate var _currentIndexPath: IndexPath? {
        willSet {
//            guard let newValue = newValue else {
//                return 
//            }
//            animator?.indexPath = newValue
        }
    }
    
    fileprivate var _ignoreContentOffsetChange = false
}

///
/// Provide collection view display support
///
extension BrowserDetailController: UICollectionViewDelegateFlowLayout {
    
    internal override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return container.numberOfSections
    }
    internal override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return container.numberOfItems(inSection: section)
    }
    
    internal override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: "ASSET-DETAIL-IMAGE", for: indexPath)
    }
    internal override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell =  cell as? BrowserDetailCell else {
            return
        }
        return cell.apply(for: container.item(at: indexPath))
    }
    
    internal func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return view.frame.size
    }
    
    // MARK: scroll view events
    
    internal override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // only process in collection view
        guard collectionView === scrollView else {
            return
        }
        // check whether to allow the change of content offset
        guard !ignoreContentOffsetChange else {
            return
        }
        // update current item & index pathd
        _updateCurrentItem(scrollView.contentOffset)
        _updateCurrentIndexForIndicator(scrollView.contentOffset)
    }
    internal override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // only process in collection view
        guard collectionView === scrollView else {
            return
        }
        // notify indicator interactive start
        indicatorItem.beginInteractiveMovement()
    }
    internal override  func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        // only process in collection view
        guard collectionView === scrollView else {
            return
        }
        // if you do not need to decelerate, notify indicator interactive finish
        guard !decelerate else {
            return
        }
        indicatorItem.endInteractiveMovement()
    }
    internal override  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // only process in collection view
        guard collectionView === scrollView else {
            return
        }
        // notify indicator interactive finish
        indicatorItem.endInteractiveMovement()
    }
    
    // MARK: private method
    
    fileprivate func _updateCurrentItem(_ offset: CGPoint) {
        // must has a collection view
        guard let collectionView = collectionView else {
            return
        }
        // check for any changes
        let x = offset.x + collectionView.bounds.width / 2
        if let item = _currentItem, item.frame.minX <= x && x < item.frame.maxX {
            return // hit cache
        }
        guard let indexPath = collectionView.indexPathForItem(at: CGPoint(x: x, y: 0)) else {
            return // not found, use old
        }
        logger.debug?.write("\(x) => \(indexPath)")
        
        let newValue = collectionView.layoutAttributesForItem(at: indexPath)
        // update to current context
        _currentItem = newValue
        _currentIndexPath = newValue?.indexPath
    }
    fileprivate func _updateCurrentIndexForIndicator(_ offset: CGPoint) {
        // must has a collection view
        guard let collectionView = collectionView else {
            return
        }
        let value = offset.x / collectionView.bounds.width
        let to = Int(ceil(value))
        let from = Int(floor(value))
        let percent = modf(value + 1).1
        // if from index is changed
        if _interactivingFromIndex != from {
            // get index path from collection view
            let indexPath = collectionView.indexPathForItem(at: CGPoint(x: (CGFloat(from) + 0.5) * collectionView.bounds.width , y: 0))
            
            _interactivingFromIndex = from
            _interactivingFromIndexPath = indexPath
        }
        // if to index is changed
        if _interactivingToIndex != to {
            // get index path from collection view
            let indexPath = collectionView.indexPathForItem(at: CGPoint(x: (CGFloat(to) + 0.5) * collectionView.bounds.width , y: 0))
            
            _interactivingToIndex = to
            _interactivingToIndexPath = indexPath
        }
        // use percentage update index
        indicatorItem.updateIndexPath(from: _interactivingFromIndexPath, to: _interactivingToIndexPath, percent: percent)
    }
//    fileprivate func _updateVisableCellContentInsetIfNeeded() {
//        let top = topLayoutGuide.length
//        let bottom = (navigationController?.toolbar?.sizeThatFits(.zero).height ?? 0) + indicatorView.frame.height
//        
//        guard _currentContentInset.top != top || _currentContentInset.bottom != bottom else {
//            return // no change
//        }
//        _currentContentInset.top = top
//        _currentContentInset.bottom = bottom
//        
//        collectionView.visibleCells.forEach {
//            ($0 as? BrowseDetailViewCell)?.contentInset =  _currentContentInset
//        }
//    }
    
    fileprivate func _performWithoutContentOffsetChange<T>(_ actionsWithoutAnimation: () -> T) -> T {
        objc_sync_enter(self)
        _ignoreContentOffsetChange = true
        let result = actionsWithoutAnimation()
        _ignoreContentOffsetChange = false
        objc_sync_exit(self)
        return result
    }
    
    
//    func numberOfSections(in collectionView: UICollectionView) -> Int {
//        return dataSource?.numberOfSections(in: self) ?? 0
//    }
//    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return dataSource?.browser(self, numberOfItemsInSection: section) ?? 0
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        return collectionView.dequeueReusableCell(withReuseIdentifier: "Asset", for: indexPath)
//    }
//    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
//        guard let cell = cell as? BrowseDetailViewCell else {
//            return
//        }
//        // 更新属性
//        cell.apply(dataSource?.browser(self, assetForItemAt: indexPath))
//        
//        cell.delegate = self
//        cell.contentInset = _currentContentInset
//    }
//    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
//        guard let cell = cell as? BrowseDetailViewCell else {
//            return
//        }
//        // 清除属性
//        cell.apply(nil)
//    }
//    
//
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        //dismissHandler(indexPath)
//    }
    
//
//    
//    
//    fileprivate var _currentContentInset: UIEdgeInsets = .zero
//}
//
//extension BrowseDetailViewController: BrowseDetailViewDelegate, UINavigationBarDelegate {
//    
//    func navigationBar(_ navigationBar: UINavigationBar, shouldPop item: UINavigationItem) -> Bool {
//        // 正在旋转的时候不允许返回
//        guard collectionView.isScrollEnabled else {
//            return false
//        }
//        
//        return true
//    }
//    
//    func browseDetailView(_ browseDetailView: Any, _ containerView: IBScrollView, shouldBeginRotationing view: UIView?) -> Bool {
//        collectionView.isScrollEnabled = false
//        return true
//    }
//    func browseDetailView(_ browseDetailView: Any, _ containerView: IBScrollView, didEndRotationing view: UIView?, atOrientation orientation: UIImageOrientation) {
//        collectionView.isScrollEnabled = true
//    }
}

///
/// Provide dismiss gesture recognizer support
///
extension BrowserDetailController: UIGestureRecognizerDelegate {
    
    internal func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if  interactiveDismissGestureRecognizer == gestureRecognizer  {
            let velocity = interactiveDismissGestureRecognizer.velocity(in: collectionView)
            // detect the direction of gestures => up or down
            guard fabs(velocity.x / velocity.y) < 1.5 else {
                return false
            }
            guard let cell = collectionView?.visibleCells.last as? BrowserDetailCell else {
                return false
            }
            // check this gesture event can not trigger bounces
            let point = interactiveDismissGestureRecognizer.location(in: cell.detailView?.superview)
            guard (point.y - view.frame.height) <= 0 else {
                return false
            }
            return true
        }
        return true
    }
    
    internal func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // only process dismiss gesture recognizer
        if interactiveDismissGestureRecognizer == gestureRecognizer  {
            // if it has started to interact, it is the exclusive mode
            guard !_transitionIsInteractiving else {
                return false
            }
            guard let panGestureRecognizer = otherGestureRecognizer as? UIPanGestureRecognizer else {
                return true
            }
            // only allow canvas view gestures can operate
            guard let view = panGestureRecognizer.view, view.superview is CanvasView else {
                return false
            }
            return true
        }
        return false
    }
    
    fileprivate dynamic func dismiss(_ sender: UIPanGestureRecognizer) {
       
        if !_transitionIsInteractiving { // start
            // check the direction of gestures => vertical & up
            let velocity = sender.velocity(in: view)
            guard velocity.y > 0 && fabs(velocity.x / velocity.y) < 1.5 else {
                return
            }
            // get cell & detail view & container view
            guard let cell = collectionView?.visibleCells.last as? BrowserDetailCell, let detailView = cell.detailView else {
                return
            }
            // check whether this has triggered bounces
            let mh = sender.location(in: view).y
            let point = sender.location(in: cell.detailView?.superview)
            guard point.y - mh < 0 || detailView.frame.height <= view.frame.height else {
                return
            }
            // enable interactiving
            _transitionAtLocation = sender.location(in: nil)
            _transitionIsInteractiving = true
            
//            // save canvas view context
//            let frame = detailView.frame
//            let size = containerView.frame.size
//            vaildContentOffset.x = min(max(offset.x, frame.minX), max(frame.width, size.width) - size.width)
//            vaildContentOffset.y = min(max(offset.y, frame.minY), max(frame.height, size.height) - size.height)
            // dismiss
            DispatchQueue.main.async {
                // setup vaild content offset
//                if let containerView = cell.containerView {
//                    containerView.layoutIfNeeded()
//                    - (void)(id)arg1;
//                    - (void)handlePinch:(id)arg1;
                    //var offset = containerVie.contentOffset
                    //containerView.contentOffset
                //containerView.setContentOffset(self.vaildContentOffset, animated: false)
//                }
                // if is navigation controller poped
                if let navigationController = self.navigationController {
                    navigationController.popViewController(animated: true)
                    return
                }
                // if is presented
                self.dismiss(animated: true, completion: nil)
            }
            logger.debug?.write("start")
            
        } else if sender.state == .changed {
            // update
            let origin = _transitionAtLocation
            let current = sender.location(in: nil)
            
            let offset = CGPoint(x: current.x - origin.x, y: current.y - origin.y)
            let percent = offset.y / (UIScreen.main.bounds.height * 3 / 5)
            
            _transitionContext?.ub_update(percent: min(max(percent, 0), 1), at: offset)
            
        } else {
            // complate or cancel
            logger.debug?.write("stop")
            // forced to reset the content of offset
            // prevent jitter caused by the rolling animation
            collectionView?.visibleCells.forEach {
                guard let cell = ($0 as? BrowserDetailCell) else {
                    return
                }
                guard let offset = cell.draggingContentOffset, cell.containerView?.isDecelerating ?? false else {
                    return
                }
              //  cell.logger.debug?.write(offset)
                cell.containerView?.setContentOffset(offset, animated: false)
            }
            // commit animation
            let complete = sender.state == .ended && sender.velocity(in: nil).y >= 0
            _transitionContext?.ub_complete(complete)
            // disable interactiving
            _transitionContext = nil
            _transitionIsInteractiving = false
        }
        
        
//        // if state is change, update
//        guard sender.state != .changed else {
//            return
//        }
        
//        // interactiving is turned on?
//        guard !isInteractiving else {
//            // ignore changed events
//            guard sender.state != .changed else {
//                return
//            }
//            return
//        }
    }
}


///
/// Provide interactivable transitioning support
///
extension BrowserDetailController: TransitioningDataSource {
    
    internal func ub_transitionView(using animator: Animator, for operation: Animator.Operation) -> TransitioningView? {
        logger.trace?.write()
        
        guard let indexPath = animator.indexPath else {
            return nil
        }
        // get at current index path the cell
        return collectionView?.cellForItem(at: indexPath) as? BrowserDetailCell
    }
    
    internal func ub_transitionShouldStart(using animator: Animator, for operation: Animator.Operation) -> Bool {
        logger.trace?.write()
        
        animator.indexPath = currentIndexPath
        return true
    }
    internal func ub_transitionShouldStartInteractive(using animator: Animator, for operation: Animator.Operation) -> Bool {
        logger.trace?.write()
        
        let state = interactiveDismissGestureRecognizer.state
        guard state == .changed || state == .began else {
            return false
        }
        return true
    }
    
    internal func ub_transitionDidPrepare(using animator: Animator, context: TransitioningContext) {
        logger.trace?.write()
        
        // must be attached to the collection view
        guard let collectionView = collectionView, let indexPath = animator.indexPath else {
            return
        }
        // check the index path is displaying
        if !collectionView.indexPathsForVisibleItems.contains(indexPath) {
            // no, scroll to the cell at index path
            collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
            // must call the layoutIfNeeded method, otherwise cell may not create
            UIView.performWithoutAnimation {
                indicatorItem.layoutIfNeeded()
                collectionView.setNeedsLayout()
                collectionView.layoutIfNeeded()
            }
        }
    }
    
    internal func ub_transitionDidStart(using animator: Animator, context: TransitioningContext) {
        _transitionContext = context
    }
    internal func ub_transitionDidEnd(using animator: Animator, transitionCompleted: Bool) {
        _transitionContext = nil
    }
}

///
/// Provide indicator view display support
///
extension BrowserDetailController: IndicatorViewDataSource, IndicatorViewDelegate {
    
    // MARK: IndicatorViewDataSource
    
    internal func numberOfSections(in indicator: IndicatorView) -> Int {
        return container.numberOfSections
    }
    internal func indicator(_ indicator: IndicatorView, numberOfItemsInSection section: Int) -> Int {
        return container.numberOfItems(inSection: section)
    }
    
    internal func indicator(_ indicator: IndicatorView, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return container.item(at: indexPath).size
    }
    
    // MARK: IndicatorViewDelegate
    
    internal func indicator(_ indicator: IndicatorView, willDisplay cell: IndicatorViewCell, forItemAt indexPath: IndexPath) {
        
        cell.contentView.backgroundColor = container.item(at: indexPath).backgroundColor
        
        if let imageView = cell.contentView as? UIImageView {
            imageView.contentMode = .scaleAspectFill
            imageView.image = container.item(at: indexPath).image
        }
    }
    
    internal func indicatorWillBeginDragging(_ indicator: IndicatorView) {
        logger.trace?.write()
        
        collectionView?.isScrollEnabled = false
        interactiveDismissGestureRecognizer.isEnabled = false
    }
    internal func indicatorDidEndDragging(_ indicator: IndicatorView) {
        logger.trace?.write()
        
        collectionView?.isScrollEnabled = true
        interactiveDismissGestureRecognizer.isEnabled = true
    }

    internal func indicator(_ indicator: IndicatorView, didSelectItemAt indexPath: IndexPath) {
        logger.debug?.write(indexPath)
        
//        guard !isInteractiving else {
//            return // 正在交互
//        }
        // index path is changed
        guard indexPath != _currentIndexPath else {
            return
        }
        // prevent possible animations
        _currentItem = collectionView?.layoutAttributesForItem(at: indexPath)
        _currentIndexPath = indexPath
        _performWithoutContentOffsetChange {
            // prevent possible animations
            UIView.performWithoutAnimation {
                collectionView?.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
            }
        }
    }
}

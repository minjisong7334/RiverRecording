//
//  Floaty.swift
//
//  Created by LeeSunhyoup on 2015. 10. 4..
//  Copyright © 2015년 kciter. All rights reserved.
//

import UIKit

public enum FloatyOpenAnimationType {
    case pop
    case fade
    case slideLeft
    case slideUp
    case slideDown
    case none
}

/**
    Floaty Object. It has `FloatyItem` objects.
    Floaty support storyboard designable.
*/
@IBDesignable
open class Floaty: UIView {
    // MARK: - Properties

    /**
        `FloatyItem` objects.
    */
    open var items: [FloatyItem] = []

    /**
        This object's button size.
    */
    open var size: CGFloat = 56 {
        didSet {
            self.setNeedsDisplay()
            self.recalculateItemsOrigin()
        }
    }

    /**
        Padding from bottom right of UIScreen or superview.
    */
    open var paddingX: CGFloat = 14 {
        didSet {
            self.setNeedsDisplay()
        }
    }
    open var paddingY: CGFloat = 14 {
        didSet {
            self.setNeedsDisplay()
        }
    }

	/**
		Automatically closes child items when tapped
	*/
	@IBInspectable open var autoCloseOnTap: Bool = true

	/**
		Degrees to rotate image
	*/
	@IBInspectable open var rotationDegrees: CGFloat = -45

    /**
     Animation speed of buttons
     */
    @IBInspectable open var animationSpeed: Double = 0.1
    /**
        Button color.
    */
    @IBInspectable open var buttonColor: UIColor = UIColor(red: 73/255.0, green: 151/255.0, blue: 241/255.0, alpha: 1)

    /**
        Button image.
    */
    @IBInspectable open var buttonImage: UIImage? = nil {
        didSet {
            self.setNeedsDisplay()
        }
    }

    /**
        Plus icon color inside button.
    */
    @IBInspectable open var plusColor: UIColor = UIColor(white: 0.2, alpha: 1)

    /**
        Background overlaying color.
    */
    @IBInspectable open var overlayColor: UIColor = UIColor.black.withAlphaComponent(0.3)

    /**
        The space between the item and item.
    */
    @IBInspectable open var itemSpace: CGFloat = 14

    /**
        Child item's default size.
    */
    @IBInspectable open var itemSize: CGFloat = 42 {
        didSet {
            self.items.forEach { item in
                item.size = self.itemSize
            }
            self.recalculateItemsOrigin()
            self.setNeedsDisplay()
        }
    }

    /**
        Child item's default button color.
    */
    @IBInspectable open var itemButtonColor: UIColor = UIColor.white

    /**
     Child item's default title label color.
     */
    @IBInspectable open var itemTitleColor: UIColor = UIColor.white

	/**
		Child item's image color
	*/
	@IBInspectable open var itemImageColor: UIColor? = nil

    /**
        Enable/disable shadow.
     */
    @IBInspectable open var hasShadow: Bool = true

    /**
        Child item's default shadow color.
    */
    @IBInspectable open var itemShadowColor: UIColor = UIColor.black

    /**

    */
    open var closed: Bool = true

    open var openAnimationType: FloatyOpenAnimationType = .pop

    open var friendlyTap: Bool = true
    
    open var sticky: Bool = false
    
    open static var global: FloatyManager {
        get {
            return FloatyManager.defaultInstance()
        }
    }
    
    /**
     Delegate that can be used to learn more about the behavior of the FAB widget.
    */
    @IBOutlet open weak var fabDelegate: FloatyDelegate?

    /**
        Button shape layer.
    */
    fileprivate var circleLayer: CAShapeLayer = CAShapeLayer()

    /**
        Plus icon shape layer.
    */
    fileprivate var plusLayer: CAShapeLayer = CAShapeLayer()

    /**
        Button image view.
    */
    fileprivate var buttonImageView: UIImageView = UIImageView()

    /**
        If you keeping touch inside button, button overlaid with tint layer.
    */
    fileprivate var tintLayer: CAShapeLayer = CAShapeLayer()

    fileprivate var hamburgerLayer: CAShapeLayer = CAShapeLayer()
    
    let shortStroke: CGPath = {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 2, y: 2))
        path.addLine(to: CGPoint(x: 28, y: 2))
        
        return path
    }()
    
    let outline: CGPath = {
        let path = CGMutablePath()
        path.move(to: CGPoint(x:10, y:27))
        path.addCurve(to: CGPoint(x:40, y:27), control1: CGPoint(x:12.00, y:27.00), control2:CGPoint(x:28.02, y:27.00))
        path.addCurve(to: CGPoint(x:27, y:2), control1: CGPoint(x:55.92, y:27.00), control2:CGPoint(x:50.47, y:2.00))
        path.addCurve(to: CGPoint(x:2, y:27), control1: CGPoint(x:13.16, y:2.00), control2:CGPoint(x:2.00, y:13.16))
        path.addCurve(to: CGPoint(x:27, y:52), control1: CGPoint(x:2.00, y:40.84), control2:CGPoint(x:13.16, y:52.00))
        path.addCurve(to: CGPoint(x:52, y:27), control1: CGPoint(x:40.84, y:52.00), control2:CGPoint(x:52.00, y:40.84))
        path.addCurve(to: CGPoint(x:27, y:2), control1: CGPoint(x:52.00, y:13.16), control2:CGPoint(x:42.39, y:2.00))
        path.addCurve(to: CGPoint(x:2, y:27), control1: CGPoint(x:13.16, y:2.00), control2:CGPoint(x:2.00, y:13.16))
        
        return path
    }()

    /**
        If you show items, background overlaid with overlayColor.
    */
//    private var overlayLayer: CAShapeLayer = CAShapeLayer()

    fileprivate var overlayView : UIControl = UIControl()

    /**
        Keep track of whether overlay open animation completes, to avoid animation conflicts.
     */
    fileprivate var overlayViewDidCompleteOpenAnimation: Bool = true

    /**
        If you created this object from storyboard or `initWithFrame`, this property set true.
    */
    fileprivate var isCustomFrame: Bool = false

    // MARK: - Initialize

    
    let menuStrokeStart: CGFloat = 0.325
    let menuStrokeEnd: CGFloat = 0.9
    let hamburgerStrokeStart: CGFloat = 0.028
    let hamburgerStrokeEnd: CGFloat = 0.111
    
    var top: CAShapeLayer! = CAShapeLayer()
    var bottom: CAShapeLayer! = CAShapeLayer()
    var middle: CAShapeLayer! = CAShapeLayer()
    
    
    /**
        Initialize with default property.
    */
    public init() {
        super.init(frame: CGRect(x: 0, y: 0, width: size, height: size))
        backgroundColor = UIColor.clear
        setObserver()
    }

    /**
        Initialize with custom size.
    */
    public init(size: CGFloat) {
        self.size = size
        super.init(frame: CGRect(x: 0, y: 0, width: size, height: size))
        backgroundColor = UIColor.clear
        setObserver()
    }

    /**
        Initialize with custom frame.
    */
    public override init(frame: CGRect) {
        super.init(frame: frame)
        size = min(frame.size.width, frame.size.height)
        backgroundColor = UIColor.clear
        isCustomFrame = true
        setObserver()
    }

    /**
        Initialize from storyboard.
    */
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        size = min(frame.size.width, frame.size.height)
        backgroundColor = UIColor.clear
        clipsToBounds = false
        isCustomFrame = true
        setObserver()
    }

    // MARK: - Method

    /**
        Set size and frame.
    */
    open override func draw(_ rect: CGRect) {
        super.draw(rect)

        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale
        if isCustomFrame == false {
            setRightBottomFrame()
        } else {
            size = min(frame.size.width, frame.size.height)
        }

        setCircleLayer()
        if buttonImage == nil {
            setHamburgerLayer()
        } else {
            setButtonImage()
        }
        setShadow()
    }

    var showsMenu: Bool = false {
        didSet {
            let strokeStart = CABasicAnimation(keyPath: "strokeStart")
            let strokeEnd = CABasicAnimation(keyPath: "strokeEnd")
            
            if self.showsMenu {
                strokeStart.toValue = menuStrokeStart
                strokeStart.duration = 0.5
                strokeStart.timingFunction = CAMediaTimingFunction(controlPoints: 0.25, -0.4, 0.5, 1)
                
                strokeEnd.toValue = menuStrokeEnd
                strokeEnd.duration = 0.6
                strokeEnd.timingFunction = CAMediaTimingFunction(controlPoints: 0.25, -0.4, 0.5, 1)
            } else {
                strokeStart.toValue = hamburgerStrokeStart
                strokeStart.duration = 0.5
                strokeStart    .timingFunction = CAMediaTimingFunction(controlPoints: 0.25, 0, 0.5, 1.2)
                strokeStart.beginTime = CACurrentMediaTime() + 0.1
                strokeStart.fillMode = kCAFillModeBackwards
                
                strokeEnd.toValue = hamburgerStrokeEnd
                strokeEnd.duration = 0.6
                strokeEnd.timingFunction = CAMediaTimingFunction(controlPoints: 0.25, 0.3, 0.5, 0.9)
            }
            
            self.middle.ocb_applyAnimation(strokeStart)
            self.middle.ocb_applyAnimation(strokeEnd)
            
            let topTransform = CABasicAnimation(keyPath: "transform")
            topTransform.timingFunction = CAMediaTimingFunction(controlPoints: 0.5, -0.8, 0.5, 1.85)
            topTransform.duration = 0.4
            topTransform.fillMode = kCAFillModeBackwards
            
            let bottomTransform = topTransform.copy() as! CABasicAnimation
            
            if self.showsMenu {
                let translation = CATransform3DMakeTranslation(-4, 0, 0)
                
                topTransform.toValue = NSValue(caTransform3D: CATransform3DRotate(translation, -0.7853975, 0, 0, 1))
                topTransform.beginTime = CACurrentMediaTime() + 0.25
                
                bottomTransform.toValue = NSValue(caTransform3D: CATransform3DRotate(translation, 0.7853975, 0, 0, 1))
                bottomTransform.beginTime = CACurrentMediaTime() + 0.25
            } else {
                topTransform.toValue = NSValue(caTransform3D: CATransform3DIdentity)
                topTransform.beginTime = CACurrentMediaTime() + 0.05
                
                bottomTransform.toValue = NSValue(caTransform3D: CATransform3DIdentity)
                bottomTransform.beginTime = CACurrentMediaTime() + 0.05
            }
            
            self.top.ocb_applyAnimation(topTransform)
            self.bottom.ocb_applyAnimation(bottomTransform)
        }
    }

    
    /**
        Items open.
    */
    open func open() {
        fabDelegate?.floatyWillOpen?(self)
        let animationGroup = DispatchGroup()
        
        if(items.count > 0){

            setOverlayView()
            self.superview?.insertSubview(overlayView, aboveSubview: self)
            self.superview?.bringSubview(toFront: self)
            overlayView.addTarget(self, action: #selector(close), for: UIControlEvents.touchUpInside)

            overlayViewDidCompleteOpenAnimation = false
            animationGroup.enter()
            self.showsMenu = !self.showsMenu

            switch openAnimationType {
            case .pop:
                popAnimationWithOpen(group: animationGroup)
            case .fade:
                fadeAnimationWithOpen(group: animationGroup)
            case .slideLeft:
                slideLeftAnimationWithOpen(group: animationGroup)
            case .slideUp:
                slideUpAnimationWithOpen(group: animationGroup)
            case .slideDown:
                slideDownAnimationWithOpen(group: animationGroup)
            case .none:
                noneAnimationWithOpen()
            }
        }

        animationGroup.notify(queue: .main) {
            self.fabDelegate?.floatyDidOpen?(self)
        }
        fabDelegate?.floatyOpened?(self)
        closed = false
    }

    /**
        Items close.
    */
    @objc open func close() {
        fabDelegate?.floatyWillClose?(self)
        let animationGroup = DispatchGroup()
        
        if(items.count > 0){
            self.overlayView.removeTarget(self, action: #selector(close), for: UIControlEvents.touchUpInside)
            animationGroup.enter()
           
            self.showsMenu = !self.showsMenu

            switch openAnimationType {
            case .pop:
                popAnimationWithClose(group: animationGroup)
            case .fade:
                fadeAnimationWithClose(group: animationGroup)
            case .slideLeft:
                slideLeftAnimationWithClose(group: animationGroup)
            case .slideUp:
                slideUpAnimationWithClose(group: animationGroup)
            case .slideDown:
                slideDownAnimationWithClose(group: animationGroup)
            case .none:
                noneAnimationWithClose()
            }
        }

        animationGroup.notify(queue: .main) {
            self.fabDelegate?.floatyDidClose?(self)
        }
        fabDelegate?.floatyClosed?(self)
        closed = true
    }

    /**
        Items open or close.
    */
    open func toggle() {
        if items.count > 0 {
            if closed == true {
                open()
            } else {
                close()
            }
        } else {
            fabDelegate?.emptyFloatySelected?(self)
        }
    }

    /**
        Add custom item
    */
    open func addItem(item: FloatyItem) {
        let big = size > item.size ? size : item.size
        let small = size <= item.size ? size : item.size
        item.frame.origin = CGPoint(x: big/2-small/2, y: big/2-small/2)
        item.alpha = 0
		item.actionButton = self
        items.append(item)
        addSubview(item)
    }
    
    
    /**
     Add item with title, titlePositon.
     titlePosition's default value is left.
     */
    @discardableResult
    open func addItem(title: String, titlePosition: FloatyItemLabelPositionType?) -> FloatyItem {
        let item = FloatyItem()
        itemDefaultSet(item)
        if(titlePosition == nil) {
            item.titleLabelPosition = .left // default
        } else {
            item.titleLabelPosition = titlePosition!
        }
        item.title = title
        addItem(item: item)
        return item
    }

    /**
        Add item with title.
    */
    @discardableResult
    open func addItem(title: String) -> FloatyItem {
        let item = FloatyItem()
        itemDefaultSet(item)
        item.title = title
        addItem(item: item)
        return item
    }
    
    /**
     Add item with title, titlePosition and icon.
     titlePosition's default value is left.
     */
    @discardableResult
    open func addItem(_ title: String, icon: UIImage?, titlePosition: FloatyItemLabelPositionType?) -> FloatyItem {
        let item = FloatyItem()
        itemDefaultSet(item)
        if(titlePosition == nil) {
            item.titleLabelPosition = .left // default
        } else {
            item.titleLabelPosition = titlePosition!
        }
        item.title = title
        item.icon = icon
        addItem(item: item)
        return item
    }

    /**
        Add item with title and icon.
    */
    @discardableResult
    open func addItem(_ title: String, icon: UIImage?) -> FloatyItem {
        let item = FloatyItem()
        itemDefaultSet(item)
        item.title = title
        item.icon = icon
        addItem(item: item)
        return item
    }

    /**
     Add item with title and handler.
     */
    @discardableResult
    open func addItem(title: String, handler: @escaping ((FloatyItem) -> Void)) -> FloatyItem {
        let item = FloatyItem()
        itemDefaultSet(item)
        item.title = title
        item.handler = handler
        addItem(item: item)
        return item
    }
    
    /**
     Add item with titlePosition and handler.
     titlePosition's default value is left.
     */
    @discardableResult
    open func addItem(title: String, titlePosition: FloatyItemLabelPositionType?, handler: @escaping ((FloatyItem) -> Void)) -> FloatyItem {
        let item = FloatyItem()
        itemDefaultSet(item)
        if(titlePosition == nil) {
            item.titleLabelPosition = .left // default
        } else {
            item.titleLabelPosition = titlePosition!
        }
        item.title = title
        item.handler = handler
        addItem(item: item)
        return item
    }

    /**
        Add item with title, icon or handler.
    */
    @discardableResult
    open func addItem(_ title: String, icon: UIImage?, handler: @escaping ((FloatyItem) -> Void)) -> FloatyItem {
        let item = FloatyItem()
        itemDefaultSet(item)
        item.title = title
        item.icon = icon
        item.handler = handler
        addItem(item: item)
        return item
    }
    
    /**
     Add item with title, icon, titlePosition or handler.
     titlePosition's default value is left
     */
    @discardableResult
    open func addItem(_ title: String, icon: UIImage?, titlePosition: FloatyItemLabelPositionType?, handler: @escaping ((FloatyItem) -> Void)) -> FloatyItem {
        let item = FloatyItem()
        itemDefaultSet(item)
        if(titlePosition == nil) {
            item.titleLabelPosition = .left // default
        } else {
            item.titleLabelPosition = titlePosition!
        }
        item.title = title
        item.icon = icon        
        item.handler = handler
        addItem(item: item)
        return item
    }

    /**
        Add item with icon.
    */
    @discardableResult
    open func addItem(icon: UIImage?) -> FloatyItem {
        let item = FloatyItem()
        itemDefaultSet(item)
        item.icon = icon
        addItem(item: item)
        return item
    }

    /**
        Add item with icon and handler.
    */
    @discardableResult
    open func addItem(icon: UIImage?, handler: @escaping ((FloatyItem) -> Void)) -> FloatyItem {
        let item = FloatyItem()
        itemDefaultSet(item)
        item.icon = icon
        item.handler = handler
        addItem(item: item)
        return item
    }

    /**
        Remove item.
    */
    open func removeItem(item: FloatyItem) {
        guard let index = items.index(of: item) else { return }
        items[index].removeFromSuperview()
        items.remove(at: index)
    }

    /**
        Remove item with index.
    */
    open func removeItem(index: Int) {
        items[index].removeFromSuperview()
        items.remove(at: index)
    }

    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if closed == false {
            for item in items {
                if item.isHidden == true { continue }
                var itemPoint = item.convert(point, from: self)

                let tapArea = determineTapArea(item: item)
                if tapArea.contains(itemPoint) == true {
                    itemPoint = item.bounds.origin
                    return item.hitTest(itemPoint, with: event)
                }
            }
        }

        return super.hitTest(point, with: event)
    }

    fileprivate func determineTapArea(item : FloatyItem) -> CGRect {
        let tappableMargin : CGFloat = 30.0
        var x : CGFloat?
        if(item.titleLabelPosition == .left) {
            x = item.titleLabel.frame.origin.x + item.bounds.origin.x
        } else {
            x = item.bounds.origin.x
        }
        let y = item.bounds.origin.y
        
        var width: CGFloat
        if isCustomFrame {
            width = item.titleLabel.bounds.size.width + item.bounds.size.width + tappableMargin + paddingX
        } else {
            width = item.titleLabel.bounds.size.width + item.bounds.size.width + tappableMargin
        }
        let height = item.bounds.size.height

        return CGRect(x: x!, y: y, width: width, height: height)
    }

    fileprivate func setCircleLayer() {
        circleLayer.removeFromSuperlayer()
        circleLayer.frame = CGRect(x: 0, y: 0, width: size, height: size)
        circleLayer.backgroundColor = buttonColor.cgColor
        circleLayer.cornerRadius = size/2
        layer.addSublayer(circleLayer)
    }

    fileprivate func setPlusLayer() {
        plusLayer.removeFromSuperlayer()
        plusLayer.frame = CGRect(x: 0, y: 0, width: size, height: size)
        plusLayer.lineCap = kCALineCapRound
        plusLayer.strokeColor = plusColor.cgColor
        plusLayer.lineWidth = 2.0
        plusLayer.path = plusBezierPath().cgPath
        layer.addSublayer(plusLayer)
    }

    fileprivate func setButtonImage() {
        buttonImageView.removeFromSuperview()
        buttonImageView = UIImageView(image: buttonImage)
		buttonImageView.tintColor = plusColor
        buttonImageView.frame = CGRect(
            x: circleLayer.frame.origin.x + (size / 2 - buttonImageView.frame.size.width / 2),
            y: circleLayer.frame.origin.y + (size / 2 - buttonImageView.frame.size.height / 2),
            width: buttonImageView.frame.size.width,
            height: buttonImageView.frame.size.height
        )

        addSubview(buttonImageView)
    }

    fileprivate func setTintLayer() {
        tintLayer.frame = CGRect(x: circleLayer.frame.origin.x, y: circleLayer.frame.origin.y, width: size, height: size)
        tintLayer.backgroundColor = UIColor.white.withAlphaComponent(0.2).cgColor
        tintLayer.cornerRadius = size/2
        layer.addSublayer(tintLayer)
    }
    
    fileprivate func setHamburgerLayer() {
        self.top.path = shortStroke
        self.middle.path = outline
        self.bottom.path = shortStroke
        
        for layer in [ self.top, self.middle, self.bottom ] {
            layer?.fillColor = nil
            layer?.strokeColor = UIColor.white.cgColor
            layer?.lineWidth = 3
            layer?.miterLimit = 4
            layer?.lineCap = kCALineCapRound
            layer?.masksToBounds = true
            
            let strokingPath = CGPath(__byStroking: (layer?.path!)!, transform: nil, lineWidth: 4, lineCap: .round, lineJoin: .miter, miterLimit: 4)
            
            layer?.bounds = (strokingPath?.boundingBoxOfPath)!
            
            layer?.actions = [
                "strokeStart": NSNull(),
                "strokeEnd": NSNull(),
                "transform": NSNull()
            ]
            
            self.layer.addSublayer(layer!)
        }
        
        self.top.anchorPoint = CGPoint(x: 28.0 / 30.0, y: 0.5)
        self.top.position = CGPoint(x: 40, y: 18)
        
        self.middle.position = CGPoint(x: 27, y: 27)
        self.middle.strokeStart = hamburgerStrokeStart
        self.middle.strokeEnd = hamburgerStrokeEnd
        
        self.bottom.anchorPoint = CGPoint(x: 28.0 / 30.0, y: 0.5)
        self.bottom.position = CGPoint(x: 40, y: 36)
    }

    fileprivate func setOverlayView() {
		setOverlayFrame()
        overlayView.backgroundColor = overlayColor
        overlayView.alpha = 0
        overlayView.isUserInteractionEnabled = true

    }
	fileprivate func setOverlayFrame() {
        if let superview = superview {
		    overlayView.frame = CGRect(
			  x: 0,y: 0,
			  width: superview.bounds.width,
			  height: superview.bounds.height
		    )
        }
	}

    fileprivate func setShadow() {
        if !hasShadow {
            return
        }
        
        layer.shadowOffset = CGSize(width: 1, height: 1)
        layer.shadowRadius = 2
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.4
    }

    fileprivate func plusBezierPath() -> UIBezierPath {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: size/2, y: size/3))
        path.addLine(to: CGPoint(x: size/2, y: size-size/3))
        path.move(to: CGPoint(x: size/3, y: size/2))
        path.addLine(to: CGPoint(x: size-size/3, y: size/2))
        return path
    }

    fileprivate func itemDefaultSet(_ item: FloatyItem) {
        item.buttonColor = itemButtonColor

		/// Use separate color (if specified) for item button image, or default to the plusColor
		item.iconImageView.tintColor = itemImageColor ?? plusColor
        item.titleColor = itemTitleColor
        item.circleShadowColor = itemShadowColor
        item.titleShadowColor = itemShadowColor
        item.size = itemSize
    }

    fileprivate func setRightBottomFrame(_ keyboardSize: CGFloat = 0) {
        if superview == nil {
            frame = CGRect(
                x: (UIScreen.main.bounds.size.width - size) - paddingX,
                y: (UIScreen.main.bounds.size.height - size - keyboardSize) - paddingY,
                width: size,
                height: size
            )
        } else {
            frame = CGRect(
                x: (superview!.bounds.size.width-size) - paddingX,
                y: (superview!.bounds.size.height-size-keyboardSize) - paddingY,
                width: size,
                height: size
            )
        }

        if friendlyTap == true {
            frame.size.width += paddingX
            frame.size.height += paddingY
        }
    }

    fileprivate func recalculateItemsOrigin() {
        for item in items {
            let big = size > item.size ? size : item.size
            let small = size <= item.size ? size : item.size
            item.frame.origin = CGPoint(x: big/2-small/2, y: big/2-small/2)
        }
    }

    fileprivate func setObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(deviceOrientationDidChange(_:)), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name:NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name:NSNotification.Name.UIKeyboardWillHide, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        NotificationCenter.default.removeObserver(self, name:NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name:NSNotification.Name.UIKeyboardWillHide, object: nil)
    }

    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        if isTouched(touches) {
            setTintLayer()
        }
    }

    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        tintLayer.removeFromSuperlayer()
        if isTouched(touches) {
            toggle()
        }
    }

    fileprivate func isTouched(_ touches: Set<UITouch>) -> Bool {
        return touches.count == 1 && touches.first?.tapCount == 1 && touches.first?.location(in: self) != nil
    }

    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if (object as? UIView) == superview && keyPath == "frame" {
            if isCustomFrame == false {
                setRightBottomFrame()
                setOverlayFrame()
            } else {
                size = min(frame.size.width, frame.size.height)
            }
        } else if (object as? UIScrollView) == superview && keyPath == "contentOffset" {
            let scrollView = object as! UIScrollView
            frame.origin.x = ((self.superview!.bounds.size.width - size) - paddingX) + scrollView.contentOffset.x
            frame.origin.y = ((self.superview!.bounds.size.height - size) - paddingY) + scrollView.contentOffset.y
        }
    }

    open override func willMove(toSuperview newSuperview: UIView?) {
        superview?.removeObserver(self, forKeyPath: "frame")
        if sticky == true {
            if let superviews = self.getAllSuperviews() {
                for superview in superviews {
                    if superview is UIScrollView {
                        superview.removeObserver(self, forKeyPath: "contentOffset", context:nil)
                    }
                }
            }
        }
        super.willMove(toSuperview: newSuperview)
    }

    open override func didMoveToSuperview() {
        super.didMoveToSuperview()
        superview?.addObserver(self, forKeyPath: "frame", options: [], context: nil)
        if sticky == true {
            if let superviews = self.getAllSuperviews() {
                for superview in superviews {
                    if superview is UIScrollView {
                        superview.addObserver(self, forKeyPath: "contentOffset", options: .new, context:nil)
                    }
                }
            }
        }
    }

    @objc internal func deviceOrientationDidChange(_ notification: Notification) {
        guard let keyboardSize: CGFloat = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.size.height else {
            return
        }

		/// Update overlay frame for new orientation dimensions
		setOverlayFrame()

        if isCustomFrame == false {
            setRightBottomFrame(keyboardSize)
        } else {
            size = min(frame.size.width, frame.size.height)
        }
    }

    @objc internal func keyboardWillShow(_ notification: Notification) {
        guard let keyboardSize: CGFloat = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.size.height else {
            return
        }
        
        if sticky == true {
            return
        }

        if isCustomFrame == false {
            setRightBottomFrame(keyboardSize)
        } else {
            size = min(frame.size.width, frame.size.height)
        }

        UIView.animate(withDuration: 0.2, delay: 0, options: UIViewAnimationOptions(), animations: {
            self.frame = CGRect(
                x: UIScreen.main.bounds.width-self.size - self.paddingX,
                y: UIScreen.main.bounds.height-self.size - keyboardSize - self.paddingY,
                width: self.size,
                height: self.size
            )
            }, completion: nil)
    }

    @objc internal func keyboardWillHide(_ notification: Notification) {
        
        if sticky == true {
            return
        }
        
        UIView.animate(withDuration: 0.2, delay: 0, options: UIViewAnimationOptions(), animations: {
            if self.isCustomFrame == false {
                self.setRightBottomFrame()
            } else {
                self.size = min(self.frame.size.width, self.frame.size.height)
            }

            }, completion: nil)
    }
}

/**
    Opening animation functions
 */
extension Floaty {
    /**
        Pop animation
     */
    fileprivate func popAnimationWithOpen(group: DispatchGroup) {
        var itemHeight: CGFloat = 0
        var delay = 0.0
        for item in items {
            if item.isHidden == true { continue }
            itemHeight += item.size + itemSpace
            item.layer.transform = CATransform3DIdentity
            let big = size > item.size ? size : item.size
            let small = size <= item.size ? size : item.size
            item.frame.origin.x = big/2-small/2
            item.frame.origin.y = -itemHeight
            item.layer.transform = CATransform3DMakeScale(0.4, 0.4, 1)
            group.enter()
            UIView.animate(withDuration: 0.3, delay: delay,
                                       usingSpringWithDamping: 0.55,
                                       initialSpringVelocity: 0.3,
                                       options: UIViewAnimationOptions(), animations: { () -> Void in
                                        item.layer.transform = CATransform3DIdentity
                                        item.alpha = 1
            }, completion: { _ in
                group.leave()
            })

            delay += animationSpeed
        }
    }

    fileprivate func popAnimationWithClose(group: DispatchGroup) {
        var delay = 0.0
        for item in items.reversed() {
            if item.isHidden == true { continue }
            group.enter()
            UIView.animate(withDuration: 0.15, delay: delay, options: [], animations: { () -> Void in
                item.layer.transform = CATransform3DMakeScale(0.4, 0.4, 1)
                item.alpha = 0
            }, completion: { _ in
                group.leave()
            })
            delay += animationSpeed
        }
    }

    /**
        Fade animation
     */
    fileprivate func fadeAnimationWithOpen(group: DispatchGroup) {
        var itemHeight: CGFloat = 0
        var delay = 0.0
        for item in items {
            if item.isHidden == true { continue }
            itemHeight += item.size + itemSpace
            item.frame.origin.y = -itemHeight
            group.enter()
            UIView.animate(withDuration: 0.4,
                                       delay: delay,
                                       options: [],
                                       animations: { () -> Void in
                                        item.alpha = 1
            }, completion: { _ in
                group.leave()
            })

            delay += animationSpeed * 2
        }
    }

    fileprivate func fadeAnimationWithClose(group: DispatchGroup) {
        var delay = 0.0
        for item in items.reversed() {
            if item.isHidden == true { continue }
            group.enter()
            UIView.animate(withDuration: 0.4,
                                       delay: delay,
                                       options: [],
                                       animations: { () -> Void in
                                        item.alpha = 0
            }, completion: { _ in
                group.leave()
            })
            delay += animationSpeed * 2
        }
    }

    /**
        Slide left animation
     */
    fileprivate func slideLeftAnimationWithOpen(group: DispatchGroup) {
        var itemHeight: CGFloat = 0
        var delay = 0.0
        for item in items {
            if item.isHidden == true { continue }
            itemHeight += item.size + itemSpace
            item.frame.origin.x = UIScreen.main.bounds.size.width - frame.origin.x
            item.frame.origin.y = -itemHeight
            group.enter()
            UIView.animate(withDuration: 0.3, delay: delay,
                                       usingSpringWithDamping: 0.55,
                                       initialSpringVelocity: 0.3,
                                       options: UIViewAnimationOptions(), animations: { () -> Void in
                                        item.frame.origin.x = self.size/2 - self.itemSize/2
                                        item.alpha = 1
            }, completion: { _ in
                group.leave()
            })

            delay += animationSpeed
        }
    }

    fileprivate func slideLeftAnimationWithClose(group: DispatchGroup) {
        var delay = 0.0
        for item in items.reversed() {
            if item.isHidden == true { continue }
            group.enter()
            UIView.animate(withDuration: 0.3, delay: delay, options: [], animations: { () -> Void in
                item.frame.origin.x = UIScreen.main.bounds.size.width - self.frame.origin.x
                item.alpha = 0
            }, completion: { _ in
                group.leave()
            })
            delay += animationSpeed
        }
    }

    /**
        Slide up animation
     */
    fileprivate func slideUpAnimationWithOpen(group: DispatchGroup) {
        var itemHeight: CGFloat = 0
        for item in items {
            if item.isHidden == true { continue }
            itemHeight += item.size + itemSpace
            group.enter()
            UIView.animate(withDuration: 0.2, delay: 0, options: [], animations: { () -> Void in
                                        item.frame.origin.y = -itemHeight
                                        item.alpha = 1
            }, completion: { _ in
                group.leave()
            })
        }
    }

    fileprivate func slideUpAnimationWithClose(group: DispatchGroup) {
        for item in items.reversed() {
            if item.isHidden == true { continue }
            group.enter()
            UIView.animate(withDuration: 0.2, delay: 0, options: [], animations: { () -> Void in
                item.frame.origin.y = 0
                item.alpha = 0
            }, completion: { _ in
                group.leave()
            })
        }
    }

    /**
        Slide down animation
     */
    fileprivate func slideDownAnimationWithOpen(group: DispatchGroup) {
        var itemHeight: CGFloat = 0
        for item in items {
            if item.isHidden == true { continue }
            itemHeight += item.size + itemSpace
            group.enter()
            UIView.animate(withDuration: 0.2, delay: 0, options: [], animations: { () -> Void in
                                        item.frame.origin.y = itemHeight
                                        item.alpha = 1
            }, completion: { _ in
                group.leave()
            })
        }
    }

    fileprivate func slideDownAnimationWithClose(group: DispatchGroup) {
        for item in items.reversed() {
            if item.isHidden == true { continue }
            group.enter()
            UIView.animate(withDuration: 0.2, delay: 0, options: [], animations: { () -> Void in
                item.frame.origin.y = 0
                item.alpha = 0
            }, completion: { _ in
                group.leave()
            })
        }
    }

    /**
        None animation
     */
    fileprivate func noneAnimationWithOpen() {
        var itemHeight: CGFloat = 0
        for item in items {
            if item.isHidden == true { continue }
            itemHeight += item.size + itemSpace
            item.frame.origin.y = -itemHeight
            item.alpha = 1
        }
    }

    fileprivate func noneAnimationWithClose() {
        for item in items.reversed() {
            if item.isHidden == true { continue }
            item.frame.origin.y = 0
            item.alpha = 0
        }
    }
}

/**
    Util functions
 */
extension Floaty {
    fileprivate func degreesToRadians(_ degrees: CGFloat) -> CGFloat {
        return degrees / 180.0 * CGFloat.pi
    }
}

extension UIView {
    fileprivate func getAllSuperviews() -> [UIView]? {
        if (self.superview == nil) {
            return nil
        }
        
        var superviews: [UIView] = []
        
        superviews.append(self.superview!)
        if let allSuperviews = self.superview!.getAllSuperviews() {
            superviews.append(contentsOf: allSuperviews)
        }
        
        return superviews
    }
}

extension CALayer {
    func ocb_applyAnimation(_ animation: CABasicAnimation) {
        let copy = animation.copy() as! CABasicAnimation
        
        if copy.fromValue == nil {
            copy.fromValue = self.presentation()!.value(forKeyPath: copy.keyPath!)
        }
        
        self.add(copy, forKey: copy.keyPath)
        self.setValue(copy.toValue, forKeyPath:copy.keyPath!)
    }
}


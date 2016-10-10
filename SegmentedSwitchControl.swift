import UIKit


public protocol SegmentedSwitchControlDelegate {
  func switchDidMoved(atIndex index: Int)
  func switchWillMoved(atIndex index: Int)
}

public extension SegmentedSwitchControlDelegate {
  func switchDidMoved(atIndex index: Int) {}
  func switchWillMoved(atIndex index: Int) {}
}


public class SegmentedSwitchControl: UIControl {
  
  
  // MARK: - Public vars
  
  public var delegate: SegmentedSwitchControlDelegate?
  
  public var titles: [String] {
    set {
      (titleLabels + selectedTitleLabels).forEach { $0.removeFromSuperview() }
      titleLabels = newValue.map { title in
        let label = UILabel()
        label.text = title
        label.textColor = titleColor
        label.font = titleFont
        label.textAlignment = .center
        label.lineBreakMode = .byClipping
        titleLabelsContentView.addSubview(label)
        return label
      }
      selectedTitleLabels = newValue.map { title in
        let label = UILabel()
        label.text = title
        label.textColor = selectedTitleColor
        label.font = titleFont
        label.textAlignment = .center
        label.lineBreakMode = .byClipping
        selectedTitleLabelsContentView.addSubview(label)
        return label
      }
    }
    get { return titleLabels.map { $0.text! } }
  }
  
  private(set) public var selectedIndex: Int = 0
  
  public var selectedBackgroundInset: CGFloat = 2.0 {
    didSet { setNeedsLayout() }
  }
  
  public var selectedBackgroundColor: UIColor! {
    set { selectedBackgroundView.backgroundColor = newValue }
    get { return selectedBackgroundView.backgroundColor }
  }
  
  public var titleColor: UIColor! {
    didSet { titleLabels.forEach { $0.textColor = titleColor } }
  }
  
  public var selectedTitleColor: UIColor! {
    didSet { selectedTitleLabels.forEach { $0.textColor = selectedTitleColor } }
  }
  
  public var selectedTitleFont: UIFont! {
    didSet { selectedTitleLabels.forEach { $0.font = selectedTitleFont } }
  }
  
  public var titleFont: UIFont! {
    didSet { titleLabels.forEach { $0.font = titleFont } }
  }
  
  public var titleFontFamily: String = "HelveticaNeue"
  
  public var titleFontSize: CGFloat = 18.0
  
  public var animationDuration: TimeInterval = 0.3
  public var animationSpringDamping: CGFloat = 0.75
  public var animationInitialSpringVelocity: CGFloat = 0.0
  
  public var cornerRadius: CGFloat {
    get {
      if cornerRadiusValue == nil {
        return bounds.height / 2
      }
      return cornerRadiusValue!
    }
    
    set {
      cornerRadiusValue = newValue
    }
  }
  
  // MARK: -
  // MARK: Private vars
  
  private var cornerRadiusValue: CGFloat? {
    didSet {
      setupCornerRadius()
    }
  }
  
  fileprivate var titleLabelsContentView = UIView()
  fileprivate var titleLabels = [UILabel]()
  
  fileprivate var selectedTitleLabelsContentView = UIView()
  fileprivate var selectedTitleLabels = [UILabel]()
  
  var selectedBackgroundView = UIView()
  
  fileprivate var titleMaskView: UIView = UIView()
  
  fileprivate var tapGesture: UITapGestureRecognizer!
  fileprivate var panGesture: UIPanGestureRecognizer!
  
  fileprivate var initialSelectedBackgroundViewFrame: CGRect?
  
  // MARK: -
  // MARK: Constructors
  
  public init(titles: [String]) {
    super.init(frame: CGRect.zero)
    
    self.titles = titles
    
    finishInit()
  }
  
  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    
    finishInit()
  }
  
  override public init(frame: CGRect) {
    super.init(frame: frame)
    
    finishInit()
    backgroundColor = .black // don't set background color in finishInit(), otherwise IB settings which are applied in init?(coder:) are overwritten
  }
  
  private func finishInit() {
    // Setup views
    addSubview(titleLabelsContentView)
    
    setupCornerRadius()
    
    addSubview(selectedBackgroundView)
    
    addSubview(selectedTitleLabelsContentView)
    titleMaskView.backgroundColor = .black
    selectedTitleLabelsContentView.layer.mask = titleMaskView.layer
    
    
    
    // Setup defaul colors
    if backgroundColor == nil {
      backgroundColor = .black
    }
    
    selectedBackgroundColor = .white
    titleColor = .white
    selectedTitleColor = .black
    
    // Gestures
    tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapped))
    addGestureRecognizer(tapGesture)
    
    panGesture = UIPanGestureRecognizer(target: self, action: #selector(pan))
    panGesture.delegate = self
    addGestureRecognizer(panGesture)
    
    addObserver(self, forKeyPath: #keyPath(selectedBackgroundView.frame), options: .new, context: nil)
  }
  
  private func setupCornerRadius() {
    selectedBackgroundView.layer.cornerRadius = cornerRadius
    titleMaskView.layer.cornerRadius = cornerRadius
    layer.cornerRadius = cornerRadius
  }
  
  override public func awakeFromNib() {
    super.awakeFromNib()
    
    self.titleFont = UIFont(name: self.titleFontFamily, size: self.titleFontSize)
    self.selectedTitleFont = self.titleFont
  }
  
  // MARK: -
  // MARK: Destructor
  
  deinit {
    removeObserver(self, forKeyPath: #keyPath(selectedBackgroundView.frame))
  }
  
  // MARK: -
  // MARK: Observer
  
  public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
    if keyPath == #keyPath(selectedBackgroundView.frame) {
      titleMaskView.frame = selectedBackgroundView.frame
    }
  }
  
  // MARK: -
  
  //  override public class func layerClass() -> AnyClass {
  //    return DGRunkeeperSwitchRoundedLayer.self
  //  }
  
  func tapped(gesture: UITapGestureRecognizer!) {
    let location = gesture.location(in: self)
    let index = Int(location.x / (bounds.width / CGFloat(titleLabels.count)))
    setSelectedIndex(index, animated: false)
  }
  
  func pan(gesture: UIPanGestureRecognizer!) {
    if gesture.state == .began {
      initialSelectedBackgroundViewFrame = selectedBackgroundView.frame
    } else if gesture.state == .changed {
      var frame = initialSelectedBackgroundViewFrame!
      frame.origin.x += gesture.translation(in: self).x
      frame.origin.x = max(min(frame.origin.x, bounds.width - selectedBackgroundInset - frame.width), selectedBackgroundInset)
      selectedBackgroundView.frame = frame
    } else if gesture.state == .ended || gesture.state == .failed || gesture.state == .cancelled {
      let index = max(0, min(titleLabels.count - 1, Int(selectedBackgroundView.center.x / (bounds.width / CGFloat(titleLabels.count)))))
      setSelectedIndex(index, animated: true)
    }
  }
  
  public func setSelectedIndex(_ selectedIndex: Int, animated: Bool) {
    delegate?.switchWillMoved(atIndex: selectedIndex)
    
    guard 0..<titleLabels.count ~= selectedIndex else { return }
    
    // Reset switch on half pan gestures
    var catchHalfSwitch: Bool = false
    if self.selectedIndex == selectedIndex {
      catchHalfSwitch = true
    }
    
    self.selectedIndex = selectedIndex
    if animated {
      if !catchHalfSwitch {
        sendActions(for: .valueChanged)
      }
      UIView.animate(withDuration: animationDuration, delay: 0.0, usingSpringWithDamping: animationSpringDamping, initialSpringVelocity: animationInitialSpringVelocity, options: [UIViewAnimationOptions.beginFromCurrentState, UIViewAnimationOptions.curveEaseOut], animations: { () -> Void in
        self.delegate?.switchDidMoved(atIndex: selectedIndex)
        self.layoutSubviews()
        }, completion: nil)
    } else {
      layoutSubviews()
      sendActions(for: .valueChanged)
    }
  }
  
  // MARK: -
  // MARK: Layout
  
  private var isShadowSetted = false
  
  override public func layoutSubviews() {
    super.layoutSubviews()
    
    let selectedBackgroundWidth = bounds.width / CGFloat(titleLabels.count) - selectedBackgroundInset * 2.0
    selectedBackgroundView.frame = CGRect(x: selectedBackgroundInset + CGFloat(selectedIndex) * (selectedBackgroundWidth + selectedBackgroundInset * 2.0), y: selectedBackgroundInset, width: selectedBackgroundWidth, height: bounds.height - selectedBackgroundInset * 2.0)
    
    if !isShadowSetted {
      let _ = selectedBackgroundView.addShadow(shadowOpacity: 0.2, shadowOffset: CGSize.zero,
                                     shadowRadius: 3)
      isShadowSetted = true
    }
    
    (titleLabelsContentView.frame, selectedTitleLabelsContentView.frame) = (bounds, bounds)
    
    let titleLabelMaxWidth = selectedBackgroundWidth
    let titleLabelMaxHeight = bounds.height - selectedBackgroundInset * 2.0
    
    zip(titleLabels, selectedTitleLabels).forEach { label, selectedLabel in
      let index = titleLabels.index(of: label)!
      
      var size = selectedLabel.sizeThatFits(CGSize(width: titleLabelMaxWidth+5, height: titleLabelMaxHeight))
      size.width = min(size.width, titleLabelMaxWidth)
      
      let x = floor((bounds.width / CGFloat(titleLabels.count)) * CGFloat(index) + (bounds.width / CGFloat(titleLabels.count) - size.width) / 2.0)
      let y = floor((bounds.height - size.height) / 2.0)
      let origin = CGPoint(x: x, y: y)
      
      let frame = CGRect(origin: origin, size: size)
      label.frame = frame
      selectedLabel.frame = frame
    }
  }
  
}

// MARK: -
// MARK: UIGestureRecognizer Delegate

extension SegmentedSwitchControl: UIGestureRecognizerDelegate {
  
  override public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    if gestureRecognizer == panGesture {
      return selectedBackgroundView.frame.contains(gestureRecognizer.location(in: self))
    }
    return super.gestureRecognizerShouldBegin(gestureRecognizer)
  }
  
}

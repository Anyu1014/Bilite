import Flutter
import UIKit
import SwiftUI

final class NativeBottomBarFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) { self.messenger = messenger }

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "bilite/native_bottom_bar", binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { call, result in
      guard call.method == "isSupported" else { result(FlutterMethodNotImplemented); return }
      if #available(iOS 26.0, *) { result(true) } else { result(false) }
    }
    registrar.register(NativeBottomBarFactory(messenger: registrar.messenger()), withId: "bilite/native_bottom_bar")
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol { FlutterStandardMessageCodec.sharedInstance() }

  func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
    if #available(iOS 26.0, *) {
      return NativeBottomBarView(frame: frame, id: viewId, messenger: messenger, arguments: args)
    }
    // The capability handshake keeps older systems on the existing Flutter bar.
    return UnsupportedBottomBarView()
  }
}

private final class UnsupportedBottomBarView: NSObject, FlutterPlatformView {
  private let content = UIView()
  func view() -> UIView { content }
}

@available(iOS 26.0, *)
private final class NativeBottomBarView: NSObject, FlutterPlatformView, UITabBarControllerDelegate {
  private let host: NativeBottomBarHost
  private let channel: FlutterMethodChannel
  private var identifiers: [String] = []
  private var showsLabels: Bool?
  private var iconOnlyArtwork: [String: UIImage] = [:]

  init(frame: CGRect, id: Int64, messenger: FlutterBinaryMessenger, arguments: Any?) {
    host = NativeBottomBarHost(frame: frame)
    channel = FlutterMethodChannel(name: "bilite/native_bottom_bar/\(id)", binaryMessenger: messenger)
    super.init()
    host.controller.delegate = self
    update(arguments)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else { result(nil); return }
      guard call.method == "update" else { result(FlutterMethodNotImplemented); return }
      guard self.update(call.arguments) else {
        result(FlutterError(code: "invalid_bottom_bar", message: "Invalid bottom bar configuration", details: nil))
        return
      }
      result(nil)
    }
  }

  deinit { channel.setMethodCallHandler(nil) }
  func view() -> UIView { host }

  @discardableResult
  private func update(_ arguments: Any?) -> Bool {
    guard let config = arguments as? [String: Any],
          let items = config["items"] as? [[String: Any]], (2...3).contains(items.count),
          let selected = config["selectedIndex"] as? Int, items.indices.contains(selected),
          let labels = config["showLabel"] as? Bool,
          let collapse = config["collapse"] as? Double, collapse.isFinite,
          let width = config["expandedWidth"] as? Double, width.isFinite, width > 0,
          let dark = config["dark"] as? Bool, let tint = config["tint"] as? NSNumber,
          let unselectedTint = config["unselectedTint"] as? NSNumber else { return false }
    let compactOffset = (config["compactOffset"] as? Double) ?? 0
    guard compactOffset.isFinite else { return false }
    let ids = items.compactMap { $0["id"] as? String }
    guard ids.count == items.count, Set(ids).count == ids.count,
          ids.allSatisfy({ ["home", "dynamics", "mine"].contains($0) }),
          items.allSatisfy({ $0["label"] is String }) else { return false }

    let controller = host.controller
    if identifiers != ids {
      identifiers = ids
      showsLabels = nil
      controller.setViewControllers(ids.map { id in
        let page = UIViewController()
        page.view.backgroundColor = .clear
        let symbol = id == "home" ? "house" : id == "dynamics" ? "play.square.stack" : "person.crop.circle"
        page.tabBarItem = UITabBarItem(title: nil, image: UIImage(systemName: symbol),
                                     selectedImage: UIImage(systemName: symbol + ".fill"))
        return page
      }, animated: false)
      // Page order is user-configurable in Flutter, never by UIKit's More editor.
      controller.customizableViewControllers = []
    }
    let updateItems = { [self] in
      for (index, page) in (controller.viewControllers ?? []).enumerated() {
        let title = items[index]["label"] as? String
        let item = page.tabBarItem!
        let visibleTitle = labels ? title : "\u{00A0}"
        if item.title != visibleTitle { item.title = visibleTitle }
        item.accessibilityLabel = title
        if showsLabels != labels {
          let id = ids[index]
          let symbol = id == "home" ? "house" : id == "dynamics" ? "play.square.stack" : "person.crop.circle"
          if labels {
            item.image = UIImage(systemName: symbol)
            item.selectedImage = UIImage(systemName: symbol + ".fill")
          } else {
            if iconOnlyArtwork[id] == nil {
              let glyph = Image(systemName: symbol + ".fill")
                .font(.system(size: 29, weight: .semibold)).foregroundStyle(.black)
              let renderer = ImageRenderer(content: glyph)
              renderer.scale = 3
              let image = renderer.uiImage?.withRenderingMode(.alwaysTemplate)
              iconOnlyArtwork[id] = image?.withAlignmentRectInsets(UIEdgeInsets(top: -7, left: 0, bottom: 7, right: 0))
            }
            item.image = iconOnlyArtwork[id]
            item.selectedImage = iconOnlyArtwork[id]
          }
        }
        let insets = labels ? UIEdgeInsets.zero : UIEdgeInsets(top: 6, left: 0, bottom: -6, right: 0)
        if item.imageInsets != insets { item.imageInsets = insets }
        let badge = items[index]["badge"] as? String
        if item.badgeValue != badge { item.badgeValue = badge }
      }
    }
    if #available(iOS 27.0, *), showsLabels != labels {
      // Commit both system glass layers together when changing icon-only titles.
      UIView.performWithoutAnimation { controller.performBatchUpdates(updateItems) }
    } else {
      updateItems()
    }
    showsLabels = labels
    if controller.selectedIndex != selected { controller.selectedIndex = selected }
    host.overrideUserInterfaceStyle = dark ? .dark : .light
    controller.overrideUserInterfaceStyle = host.overrideUserInterfaceStyle
    func color(_ argb: NSNumber) -> UIColor {
      let value = argb.uint32Value
      return UIColor(red: CGFloat((value >> 16) & 255) / 255, green: CGFloat((value >> 8) & 255) / 255,
                     blue: CGFloat(value & 255) / 255, alpha: CGFloat(value >> 24) / 255)
    }
    controller.tabBar.tintColor = color(tint)
    controller.tabBar.unselectedItemTintColor = color(unselectedTint)
    host.expandedWidth = width
    host.collapse = min(1, max(0, collapse))
    host.compactOffset = compactOffset
    host.setNeedsLayout()
    return true
  }

  func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
    guard let index = tabBarController.viewControllers?.firstIndex(of: viewController) else { return false }
    // Forward re-taps too: Flutter owns page switching and refresh behavior.
    channel.invokeMethod("select", arguments: index)
    return false
  }
}

@available(iOS 26.0, *)
private final class NativeBottomBarController: UITabBarController {
  weak var host: NativeBottomBarHost?

  init() { super.init(nibName: nil, bundle: nil) }
  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    host?.alignNativeBar()
  }
}

@available(iOS 26.0, *)
private final class NativeBottomBarHost: UIView {
  let controller = NativeBottomBarController()
  private let avatarGlass: UIVisualEffectView
  var expandedWidth: CGFloat = 264
  var collapse: CGFloat = 0
  var compactOffset: CGFloat = 0

  override init(frame: CGRect) {
    let effect = UIGlassEffect(style: .regular)
    avatarGlass = UIVisualEffectView(effect: effect)
    super.init(frame: frame)
    backgroundColor = .clear
    clipsToBounds = false
    controller.host = self
    controller.mode = .tabBar
    controller.tabBarMinimizeBehavior = .never
    controller.traitOverrides.horizontalSizeClass = .compact
    controller.loadViewIfNeeded()
    controller.view.backgroundColor = .clear
    controller.view.clipsToBounds = false
    controller.tabBar.clipsToBounds = false
    controller.tabBar.accessibilityIdentifier = "bilite-native-bottom-bar"
    addSubview(controller.view)
    avatarGlass.isUserInteractionEnabled = false
    avatarGlass.clipsToBounds = true
    addSubview(avatarGlass)
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  override func didMoveToWindow() {
    super.didMoveToWindow()
    if window == nil {
      controller.willMove(toParent: nil)
      controller.view.removeFromSuperview()
      controller.removeFromParent()
    } else if controller.parent == nil {
      var responder: UIResponder? = next
      while let current = responder, !(current is UIViewController) { responder = current.next }
      if let parent = responder as? UIViewController {
        parent.addChild(controller)
        insertSubview(controller.view, belowSubview: avatarGlass)
        controller.didMove(toParent: parent)
      }
    }
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    // Lay out a normal controller first, then place its bar inside the Flutter frame.
    // The platform view keeps its bounds while the visible bar and avatar animate.
    UIView.performWithoutAnimation {
      let viewportWidth = max(bounds.width, expandedWidth)
      let viewportHeight = max(window?.bounds.height ?? expandedWidth * 2, bounds.height)
      let bar = controller.tabBar
      bar.transform = .identity
      let viewportSize = CGSize(width: viewportWidth, height: viewportHeight)
      if controller.view.bounds.size != viewportSize {
        controller.view.bounds = CGRect(origin: .zero, size: viewportSize)
        controller.view.center = CGPoint(x: viewportWidth / 2, y: viewportHeight / 2)
      }
      controller.view.layoutIfNeeded()
      alignNativeBar()
      let fade = min(1, max(0, collapse / 0.6))
      bar.alpha = 1 - fade * fade * (3 - 2 * fade)
      bar.transform = CGAffineTransform(translationX: compactOffset, y: 0)
        .scaledBy(x: 1 - 0.45 * collapse, y: 1)
      bar.isUserInteractionEnabled = collapse <= 0.35
      bar.accessibilityElementsHidden = collapse > 0.35
      avatarGlass.transform = .identity
      avatarGlass.frame = CGRect(x: bounds.midX + compactOffset - 31, y: bounds.midY - 31,
                                 width: 62, height: 62)
      avatarGlass.layer.cornerRadius = 31
      let avatarFade = min(1, max(0, (collapse - 0.25) / 0.75))
      avatarGlass.alpha = avatarFade * avatarFade * (3 - 2 * avatarFade)
      avatarGlass.transform = CGAffineTransform(scaleX: 0.88 + 0.12 * collapse, y: 0.88 + 0.12 * collapse)
    }
  }

  func alignNativeBar() {
    let bar = controller.tabBar
    func controlBounds(_ view: UIView) -> CGRect {
      if view is UIControl {
        return view.bounds.isEmpty ? .null : view.convert(view.bounds, to: bar)
      }
      return view.subviews.reduce(CGRect.null) { $0.union(controlBounds($1)) }
    }
    let content = controlBounds(bar)
    guard !content.isNull, !content.isEmpty else { return }
    // The system tab-bar frame includes space below the visible glass capsule.
    let center = bar.convert(CGPoint(x: content.midX, y: content.midY), to: controller.view)
    let transform = CGAffineTransform(
      translationX: (bounds.width - controller.view.bounds.width) / 2,
      y: bounds.midY - center.y)
    UIView.performWithoutAnimation {
      if controller.view.transform != transform { controller.view.transform = transform }
    }
  }

  override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
    guard collapse <= 0.35 else { return nil }
    let bar = controller.tabBar
    guard let hit = bar.hitTest(convert(point, to: bar), with: event) else { return nil }
    var candidate: UIView? = hit
    while let view = candidate, view !== bar {
      if view is UIControl { return hit }
      candidate = view.superview
    }
    return nil
  }
}

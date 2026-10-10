import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController.init()
    self.contentViewController = flutterViewController
    
    // Desktop layout: same default and minimum size as the Windows build, centered
    self.setContentSize(NSSize(width: 1200, height: 820))
    self.contentMinSize = NSSize(width: 420, height: 600)
    self.center()

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}

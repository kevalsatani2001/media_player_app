import Flutter
import UIKit
import AVKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let pipChannel = "media_player/pip"
  private let eqChannel = "media_player/equalizer"
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(name: pipChannel, binaryMessenger: controller.binaryMessenger)
      channel.setMethodCallHandler { call, result in
        switch call.method {
        case "isPipSupported":
          if #available(iOS 15.0, *) {
            result(AVPictureInPictureController.isPictureInPictureSupported())
          } else {
            result(false)
          }
        case "enterPip":
          // Real PiP entry needs AVPlayerLayer ownership in native view.
          result(false)
        default:
          result(FlutterMethodNotImplemented)
        }
      }

      let eq = FlutterMethodChannel(name: eqChannel, binaryMessenger: controller.binaryMessenger)
      eq.setMethodCallHandler { call, result in
        // iOS video backend currently has no direct DSP hooks here.
        switch call.method {
        case "setEnabled", "setReverb", "setBassBoost", "setVirtualizer":
          result(false)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

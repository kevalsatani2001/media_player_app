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

      let editorChannel = FlutterMethodChannel(name: "media_player/editor", binaryMessenger: controller.binaryMessenger)
      editorChannel.setMethodCallHandler { (call, result) in
          if call.method == "renameVideo" {
              // iOS àª®àª¾àª‚ àª—à«‡àª²à«‡àª°à«€àª¨à«€ àª«àª¾àªˆàª²àª¨à«àª‚ àª¨àª¾àª® àª¨à«‡àªŸàª¿àªµ àª°à«€àª¤à«‡ àª¬àª¦àª²àªµà«àª‚ àª…àª˜àª°à«àª‚ àª›à«‡.
              // àª…àª¤à«àª¯àª¾àª°à«‡ àª†àªªàª£à«‡ Flutter àª¬àª¾àªœà«àª¥à«€ àªœ PhotoManager àªµàª¾àªªàª°à«€àª¶à«àª‚.
              // àªàªŸàª²à«‡ àª…àª¹à«€àª‚àª¥à«€ àª«àª•à«àª¤ 'false' àª…àª¥àªµàª¾ 'NotImplemented' àª®à«‹àª•àª²à«€àª àª›à«€àª.
              result(FlutterMethodNotImplemented)
          } else {
              result(FlutterMethodNotImplemented)
          }
      }
    }
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
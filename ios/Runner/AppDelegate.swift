import Flutter
import UIKit
import UserNotifications
import TrueSDK

@main
@objc class AppDelegate: FlutterAppDelegate, TCTrueSDKDelegate {
  private var pendingResult: FlutterResult?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Set notification delegate for iOS 10+
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }
    
    // Explicitly register for remote notifications
    application.registerForRemoteNotifications()

    // Initialize Truecaller SDK before super.application to catch launch-time deep links
    if TCTrueSDK.sharedManager().isSupported() {
      TCTrueSDK.sharedManager().setup(
        withAppKey: "IRicNd6dc840a8d594a70b983e92c2f34af92",
        appLink: "https://sic9acec38c5624bf3947bc61aa8288b31.truecallerdevs.com"
      )
      TCTrueSDK.sharedManager().delegate = self
    }

    let isFinished = super.application(application, didFinishLaunchingWithOptions: launchOptions)

    // Set up Flutter Method Channel safely using registrar
    if let registrar = self.registrar(forPlugin: "Truecaller") {
      let truecallerChannel = FlutterMethodChannel(
        name: "com.elnazeredu.elnazer/truecaller",
        binaryMessenger: registrar.messenger()
      )

      truecallerChannel.setMethodCallHandler { [weak self] (call, result) in
      guard let self = self else { return }
      if call.method == "isUsable" {
        result(TCTrueSDK.sharedManager().isSupported())
      } else if call.method == "verifyUser" {
        if TCTrueSDK.sharedManager().isSupported() {
          self.pendingResult = result
          TCTrueSDK.sharedManager().requestTrueProfile()
        } else {
          result(["status": "error", "message": "Truecaller is not supported on this device"])
        }
      } else if call.method == "getAndClearCachedPhone" {
        let phone = UserDefaults.standard.string(forKey: "tc_verified_phone")
        if phone != nil {
          UserDefaults.standard.removeObject(forKey: "tc_verified_phone")
        }
        result(phone)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    }
    
    return isFinished
  }

  // MARK: - TCTrueSDKDelegate

  @objc func didReceive(_ profile: TCTrueProfile) {
    let phoneNumber = profile.phoneNumber ?? ""
    if !phoneNumber.isEmpty {
      UserDefaults.standard.set(phoneNumber, forKey: "tc_verified_phone")
    }
    
    if let result = pendingResult {
      result([
        "status": "success",
        "phoneNumber": phoneNumber
      ])
      pendingResult = nil
    }
  }

  @objc func didFailToReceiveTrueProfileWithError(_ error: TCError) {
    if let result = pendingResult {
      result([
        "status": "failure",
        "error": "Truecaller verification failed: \(error.description)"
      ])
      pendingResult = nil
    }
  }

  // MARK: - Deep Link / Universal Link redirection

  override func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {
    let handler: ([Any]?) -> Void = { restorableObjects in
      restorationHandler(restorableObjects as? [UIUserActivityRestoring])
    }
    if TCTrueSDK.sharedManager().application(application, continue: userActivity, restorationHandler: handler) {
      return true
    }
    return super.application(application, continue: userActivity, restorationHandler: restorationHandler)
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
      if TCTrueSDK.sharedManager().continue(withUrlScheme: url) {
      return true
    }
    return super.application(app, open: url, options: options)
  }
}

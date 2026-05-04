import CoreMotion
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let motionEvidenceHandler = RunMotionEvidenceStreamHandler()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      FlutterEventChannel(
        name: "runlini/motion_evidence",
        binaryMessenger: controller.binaryMessenger
      ).setStreamHandler(motionEvidenceHandler)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

final class RunMotionEvidenceStreamHandler: NSObject, FlutterStreamHandler {
  private let pedometer = CMPedometer()
  private var lastStepCount = 0

  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    guard CMPedometer.isStepCountingAvailable() else {
      events(event(availability: "unavailable"))
      return nil
    }
    lastStepCount = 0
    events(event(availability: "available"))
    pedometer.startUpdates(from: Date()) { [weak self] data, error in
      guard let self else { return }
      if error != nil {
        DispatchQueue.main.async {
          events(self.event(availability: "permissionDenied"))
        }
        return
      }
      guard let data else { return }
      let current = data.numberOfSteps.intValue
      let delta = max(0, current - self.lastStepCount)
      self.lastStepCount = current
      guard delta > 0 else { return }
      DispatchQueue.main.async {
        events(self.event(availability: "available", stepDelta: delta))
      }
    }
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    pedometer.stopUpdates()
    lastStepCount = 0
    return nil
  }

  private func event(
    availability: String,
    stepDelta: Int = 0
  ) -> [String: Any] {
    [
      "availability": availability,
      "stepDelta": stepDelta,
      "timestampEpochMs": Int(Date().timeIntervalSince1970 * 1000),
    ]
  }
}

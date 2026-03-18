import DeviceActivity
import Foundation

final class ActivityMonitorExtension: DeviceActivityMonitor {
    override func intervalDidStart(for activity: DeviceActivityName) {
        _ = activity
    }
}

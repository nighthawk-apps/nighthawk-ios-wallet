import Foundation
import Models
import UIKit
import UserNotifications

/// Local chat alerts: no self-echo, no DAG replay, lockscreen shows a generic body.
/// Tap stores the thread; Home consumes it and opens that DM or channel.
public enum ChatNotificationRouter {
    private static let pendingKey = "nighthawk.pendingChatThread"
    private static let delegate = Delegate()

    public static func install() {
        UNUserNotificationCenter.current().delegate = delegate
    }

    public static func takePending() -> String? {
        let value = UserDefaults.standard.string(forKey: pendingKey)
        UserDefaults.standard.removeObject(forKey: pendingKey)
        return value?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
    }

    static func maybeNotify(
        nick: String,
        body: String,
        thread: String,
        isOutgoing: Bool,
        timestamp: Date,
        ownNick: String
    ) {
        guard ChatNotificationPolicy.shouldAlert(
            isOutgoing: isOutgoing,
            ownNick: ownNick,
            nick: nick,
            timestamp: timestamp
        ) else { return }
        guard UIApplication.shared.applicationState != .active else { return }
        let content = UNMutableNotificationContent()
        content.title = "Nighthawk"
        content.body = ChatNotificationPolicy.lockscreenText
        content.userInfo = ["nighthawk_chat_thread": thread]
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: "chat-\(thread)-\(Int(timestamp.timeIntervalSince1970))",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    private final class Delegate: NSObject, UNUserNotificationCenterDelegate {
        func userNotificationCenter(
            _ center: UNUserNotificationCenter,
            willPresent notification: UNNotification
        ) async -> UNNotificationPresentationOptions {
            []
        }

        func userNotificationCenter(
            _ center: UNUserNotificationCenter,
            didReceive response: UNNotificationResponse
        ) async {
            let thread = response.notification.request.content.userInfo["nighthawk_chat_thread"] as? String
            if let thread, !thread.isEmpty {
                UserDefaults.standard.set(thread, forKey: ChatNotificationRouter.pendingKey)
            }
        }
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}

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

    struct NotificationEvent {
        let nick: String
        let body: String
        let thread: String
        let isOutgoing: Bool
        let timestamp: Date
        let ownNick: String
    }

    static func maybeNotify(_ event: NotificationEvent) {
        guard ChatNotificationPolicy.shouldAlert(
            isOutgoing: event.isOutgoing,
            ownNick: event.ownNick,
            nick: event.nick,
            timestamp: event.timestamp
        ) else { return }
        guard UIApplication.shared.applicationState != .active else { return }
        let content = UNMutableNotificationContent()
        content.title = "Nighthawk"
        content.body = ChatNotificationPolicy.lockscreenText
        content.userInfo = ["nighthawk_chat_thread": event.thread]
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: "chat-\(event.thread)-\(Int(event.timestamp.timeIntervalSince1970))",
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

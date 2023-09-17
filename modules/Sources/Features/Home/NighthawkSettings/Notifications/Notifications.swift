//
//  Notifications.swift
//  secant
//
//  Created by Matthew Watt on 5/14/23.
//

import ComposableArchitecture
import Date
import Generated
import Models
import UserPreferencesStorage
import UIKit
import UserNotifications
import UserNotificationCenter
import Utils

public struct Notifications: Reducer {
    public struct State: Equatable {
        @PresentationState public var alert: AlertState<Action.Alert>?
        @BindingState public var selectedSyncNotificationFrequency: NighthawkSetting.SyncNotificationFrequency = .off
        public var authorizationStatus: UNAuthorizationStatus = .notDetermined
        
        public init() {}
    }
    
    public enum Action: BindableAction, Equatable {
        case alert(PresentationAction<Alert>)
        case authorizationStatusResponse(Bool)
        case binding(BindingAction<State>)
        case notificationSettingsResponse(NotificationSettings)
        case onAppear
        case scheduleNotificationFailed
        
        public enum Alert: Equatable {
            case openSettings
        }
    }
    
    @Dependency(\.dateClient) var dateClient
    @Dependency(\.userStoredPreferences) var userStoredPreferences
    @Dependency(\.userNotificationCenter) var userNotificationCenter
    
    public var body: some ReducerOf<Self> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .alert(.presented(.openSettings)):
                if let appSettings = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(appSettings) {
                    UIApplication.shared.open(appSettings)
                }
                return .none
                
            case .alert(.dismiss):
                return .none
                
            case let .authorizationStatusResponse(granted):
                if granted {
                    userStoredPreferences.setSyncNotificationFrequency(state.selectedSyncNotificationFrequency)
                    return scheduleNotification(with: state.selectedSyncNotificationFrequency)
                } else {
                    userStoredPreferences.setSyncNotificationFrequency(.off)
                    state.selectedSyncNotificationFrequency = .off
                    state.alert = AlertState.notifyAppNeedsNotificationPermission()
                }
                return .none
            case .binding(\.$selectedSyncNotificationFrequency):
                if state.authorizationStatus.isAuthorized {
                    userStoredPreferences.setSyncNotificationFrequency(state.selectedSyncNotificationFrequency)
                    return scheduleNotification(with: state.selectedSyncNotificationFrequency)
                } else {
                    if state.authorizationStatus == .notDetermined {
                        return .run { send in
                            let status = (try? await userNotificationCenter.requestAuthorization([.alert, .badge, .sound])) ?? false
                            await send(.authorizationStatusResponse(status))
                        }
                    } else if state.authorizationStatus == .denied {
                        userStoredPreferences.setSyncNotificationFrequency(.off)
                        state.selectedSyncNotificationFrequency = .off
                        userNotificationCenter.removeAllPendingNotificationRequests()
                        state.alert = AlertState.notifyAppNeedsNotificationPermission()
                    }
                    
                    return .none
                }
                
            case let .notificationSettingsResponse(settings):
                state.authorizationStatus = settings.authorizationStatus
                if !settings.authorizationStatus.isAuthorized {
                    userStoredPreferences.setSyncNotificationFrequency(.off)
                    state.selectedSyncNotificationFrequency = .off
                    userNotificationCenter.removeAllPendingNotificationRequests()
                } else {
                    state.selectedSyncNotificationFrequency = userStoredPreferences.syncNotificationFrequency()
                }
                return .none
                
            case .onAppear:
                return .run { send in
                    await send(.notificationSettingsResponse(userNotificationCenter.notificationSettings()))
                }
                
            case .scheduleNotificationFailed:
                state.alert = AlertState.scheduleNotificationFailed()
                return .none
                
            case .alert, .binding:
                return .none
            }
        }
    }
    
    public init() {}
    
    private func scheduleNotification(with frequency: NighthawkSetting.SyncNotificationFrequency) -> Effect<Action> {
        guard frequency != .off else {
            userNotificationCenter.removeAllPendingNotificationRequests()
            return .none
        }
        
        let content = UNMutableNotificationContent()
        content.title = L10n.Nighthawk.SettingsTab.SyncNotifications.Notification.title
        content.body = L10n.Nighthawk.SettingsTab.SyncNotifications.Notification.detail
        content.sound = UNNotificationSound.default
        
        let today = dateClient.now()
        let trigger: UNCalendarNotificationTrigger
        if frequency == .weekly {
            guard let nextWeek = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: today) else {
                return .send(.scheduleNotificationFailed)
            }
            
            trigger = UNCalendarNotificationTrigger(
                dateMatching: Calendar.current.dateComponents([.weekday, .hour], from: nextWeek),
                repeats: true
            )
        } else {
            guard let nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: today) else {
                return .send(.scheduleNotificationFailed)
            }
            
            trigger = UNCalendarNotificationTrigger(
                dateMatching: Calendar.current.dateComponents([.month, .day, .hour], from: nextMonth),
                repeats: true
            )
        }
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        return .run { send in
            do {
                try await userNotificationCenter.add(request)
            } catch {
                await send(.scheduleNotificationFailed)
            }
        }
    }
}

// MARK: Alerts

extension AlertState where Action == Notifications.Action.Alert {
    public static func notifyAppNeedsNotificationPermission() -> AlertState {
        AlertState {
            TextState(L10n.Nighthawk.SettingsTab.SyncNotifications.PermissionDeniedAlert.title)
        } actions: {
            ButtonState(role: .cancel) {
                TextState(L10n.General.cancel)
            }
            
            ButtonState(action: .openSettings) {
                TextState(L10n.Nighthawk.SettingsTab.SyncNotifications.PermissionDeniedAlert.goToSettings)
            }
        } message: {
            TextState(L10n.Nighthawk.SettingsTab.SyncNotifications.PermissionDeniedAlert.description)
        }
    }
    
    public static func scheduleNotificationFailed() -> AlertState {
        AlertState {
            TextState(L10n.Nighthawk.SettingsTab.SyncNotifications.ScheduleNotificationFailedAlert.title)
        } actions: {
            ButtonState {
                TextState(L10n.General.ok)
            }
        } message: {
            TextState(L10n.Nighthawk.SettingsTab.SyncNotifications.ScheduleNotificationFailedAlert.details)
        }
    }
}

// MARK: - Placeholder
extension Notifications.State {
    public static let placeholder = Self()
}

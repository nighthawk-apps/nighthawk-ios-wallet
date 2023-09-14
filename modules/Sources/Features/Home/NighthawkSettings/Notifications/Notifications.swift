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

public struct Notifications: ReducerProtocol {
    public struct State: Equatable {
        @PresentationState public var alert: AlertState<Action>?
        @BindingState public var selectedSyncNotificationFrequency: NighthawkSetting.SyncNotificationFrequency = .off
        public var authorizationStatus: UNAuthorizationStatus = .notDetermined
        
        public init() {}
    }
    
    public enum Action: BindableAction, Equatable {
        case alert(PresentationAction<Action>)
        case authorizationStatusResponse(Bool)
        case binding(BindingAction<State>)
        case noOp
        case notificationSettingsResponse(NotificationSettings)
        case onAppear
        case openSettings
        case scheduleNotificationFailed
    }
    
    @Dependency(\.dateClient) var dateClient
    @Dependency(\.userStoredPreferences) var userStoredPreferences
    @Dependency(\.userNotificationCenter) var userNotificationCenter
    
    public var body: some ReducerProtocolOf<Self> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .alert(.presented(let action)):
                return EffectTask(value: action)
                
            case .alert(.dismiss):
                state.alert = nil
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
                        return .task {
                            return .authorizationStatusResponse(
                                (try? await userNotificationCenter.requestAuthorization([.alert, .badge, .sound])) ?? false
                            )
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
                return .task {
                    return await .notificationSettingsResponse(userNotificationCenter.notificationSettings())
                }
                
            case .openSettings:
                if let appSettings = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(appSettings) {
                    UIApplication.shared.open(appSettings)
                }
                return .none
                
            case .scheduleNotificationFailed:
                state.alert = AlertState.scheduleNotificationFailed()
                return .none
                
            case .alert, .binding, .noOp:
                return .none
            }
        }
    }
    
    public init() {}
    
    private func scheduleNotification(with frequency: NighthawkSetting.SyncNotificationFrequency) -> EffectTask<Action> {
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
                return .task { .scheduleNotificationFailed }
            }
            
            trigger = UNCalendarNotificationTrigger(
                dateMatching: Calendar.current.dateComponents([.weekday, .hour], from: nextWeek),
                repeats: true
            )
        } else {
            guard let nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: today) else {
                return .task { .scheduleNotificationFailed }
            }
            
            trigger = UNCalendarNotificationTrigger(
                dateMatching: Calendar.current.dateComponents([.month, .day, .hour], from: nextMonth),
                repeats: true
            )
        }
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        return .task {
            do {
                try await userNotificationCenter.add(request)
                return .noOp
            } catch {
                return .scheduleNotificationFailed
            }
        }
    }
}

// MARK: Alerts

extension AlertState where Action == Notifications.Action {
    public static func notifyAppNeedsNotificationPermission() -> AlertState {
        AlertState {
            TextState(L10n.Nighthawk.SettingsTab.SyncNotifications.PermissionDeniedAlert.title)
        } actions: {
            ButtonState(role: .cancel, action: .alert(.dismiss)) {
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
            ButtonState(action: .alert(.dismiss)) {
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

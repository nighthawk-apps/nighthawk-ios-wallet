//
//  AppVersionMocks.swift
//  stealth
//

extension AppVersionClient {
    public static let mock = Self(
        appVersion: { "0.0.1" },
        appBuild: { "31" }
    )
}

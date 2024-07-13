// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
public enum L10n {
  /// %@ %@
  public static func balance(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "balance", String(describing: p1), String(describing: p2), fallback: "%@ %@")
  }
  /// QR Code for %@
  public static func qrCodeFor(_ p1: Any) -> String {
    return L10n.tr("Localizable", "qrCodeFor", String(describing: p1), fallback: "QR Code for %@")
  }
  public enum Balance {
    /// %@ %@ Available
    public static func available(_ p1: Any, _ p2: Any) -> String {
      return L10n.tr("Localizable", "balance.available", String(describing: p1), String(describing: p2), fallback: "%@ %@ Available")
    }
  }
  public enum General {
    /// Back
    public static let back = L10n.tr("Localizable", "general.back", fallback: "Back")
    /// Cancel
    public static let cancel = L10n.tr("Localizable", "general.cancel", fallback: "Cancel")
    /// Clear
    public static let clear = L10n.tr("Localizable", "general.clear", fallback: "Clear")
    /// Close
    public static let close = L10n.tr("Localizable", "general.close", fallback: "Close")
    /// date not available
    public static let dateNotAvailable = L10n.tr("Localizable", "general.dateNotAvailable", fallback: "date not available")
    /// Done
    public static let done = L10n.tr("Localizable", "general.done", fallback: "Done")
    /// Max
    public static let max = L10n.tr("Localizable", "general.max", fallback: "Max")
    /// Next
    public static let next = L10n.tr("Localizable", "general.next", fallback: "Next")
    /// No
    public static let no = L10n.tr("Localizable", "general.no", fallback: "No")
    /// Ok
    public static let ok = L10n.tr("Localizable", "general.ok", fallback: "Ok")
    /// Send
    public static let send = L10n.tr("Localizable", "general.send", fallback: "Send")
    /// Skip
    public static let skip = L10n.tr("Localizable", "general.skip", fallback: "Skip")
    /// Success
    public static let success = L10n.tr("Localizable", "general.success", fallback: "Success")
    /// Terms and Conditions
    public static let termsAndConditions = L10n.tr("Localizable", "general.termsAndConditions", fallback: "Terms and Conditions")
    /// Unknown
    public static let unknown = L10n.tr("Localizable", "general.unknown", fallback: "Unknown")
    /// Yes
    public static let yes = L10n.tr("Localizable", "general.yes", fallback: "Yes")
  }
  public enum Nefs {
    /// Not enough space on disk to do synchronisation!
    public static let message = L10n.tr("Localizable", "nefs.message", fallback: "Not enough space on disk to do synchronisation!")
  }
  public enum Nighthawk {
    public enum About {
      /// Nighthawk is a Shielded-by-Default wallet for Zcash with Spend-before-Sync support & optional T-addresses support with Auto-Shielding technology.
      /// 
      /// As a non-custodial wallet for Zcash, you have sole responsibility over its funds. Please immediately and securely back up the seed words upon creating a wallet.
      /// 
      /// Zcash is a digital currency, or cryptocurrency, like Bitcoin. Zcash was built on the original Bitcoin code base. It was conceived by scientists at MIT, Johns Hopkins and other respected academic and scientific institutions.
      /// 
      /// Nighthawk Wallet requires trust in the default or custom lightwalletd server to display accurate transaction information and CoinGecko service for exchange rate feed. This software is provided "as is", without warranty of any kind, express or implied.
      public static let message = L10n.tr("Localizable", "nighthawk.about.message", fallback: "Nighthawk is a Shielded-by-Default wallet for Zcash with Spend-before-Sync support & optional T-addresses support with Auto-Shielding technology.\n\nAs a non-custodial wallet for Zcash, you have sole responsibility over its funds. Please immediately and securely back up the seed words upon creating a wallet.\n\nZcash is a digital currency, or cryptocurrency, like Bitcoin. Zcash was built on the original Bitcoin code base. It was conceived by scientists at MIT, Johns Hopkins and other respected academic and scientific institutions.\n\nNighthawk Wallet requires trust in the default or custom lightwalletd server to display accurate transaction information and CoinGecko service for exchange rate feed. This software is provided \"as is\", without warranty of any kind, express or implied.")
      /// Nighthawk friends
      public static let nighthawkFriends = L10n.tr("Localizable", "nighthawk.about.nighthawkFriends", fallback: "Nighthawk friends")
      /// About
      public static let title = L10n.tr("Localizable", "nighthawk.about.title", fallback: "About")
      /// View licenses
      public static let viewLicenses = L10n.tr("Localizable", "nighthawk.about.viewLicenses", fallback: "View licenses")
      /// View Source
      public static let viewSource = L10n.tr("Localizable", "nighthawk.about.viewSource", fallback: "View Source")
    }
    public enum App {
      public enum DeleteWallet {
        public enum Alert {
          public enum Failed {
            /// Wallet deletion failed
            public static let title = L10n.tr("Localizable", "nighthawk.app.deleteWallet.alert.failed.title", fallback: "Wallet deletion failed")
          }
        }
      }
      public enum Launch {
        public enum Alert {
          public enum Error {
            /// Error: %@ (code: %@)
            public static func message(_ p1: Any, _ p2: Any) -> String {
              return L10n.tr("Localizable", "nighthawk.app.launch.alert.error.message", String(describing: p1), String(describing: p2), fallback: "Error: %@ (code: %@)")
            }
          }
          public enum SdkInitFailed {
            /// Failed to initialize the SDK
            public static let title = L10n.tr("Localizable", "nighthawk.app.launch.alert.sdkInitFailed.title", fallback: "Failed to initialize the SDK")
          }
        }
      }
    }
    public enum Autoshield {
      /// Autoshielding
      public static let autoshielding = L10n.tr("Localizable", "nighthawk.autoshield.autoshielding", fallback: "Autoshielding")
      /// Learn more
      public static let buttonNeutral = L10n.tr("Localizable", "nighthawk.autoshield.buttonNeutral", fallback: "Learn more")
      /// Great!
      public static let buttonPositive = L10n.tr("Localizable", "nighthawk.autoshield.buttonPositive", fallback: "Great!")
      /// means any funds coming into your transparent address will automatically be moved to your shielded address.
      public static let detail1 = L10n.tr("Localizable", "nighthawk.autoshield.detail1", fallback: "means any funds coming into your transparent address will automatically be moved to your shielded address.")
      /// We are committed to providing regular updates on the latest privacy-preserving best practices and recommendations to keep you well-informed.
      public static let detail2 = L10n.tr("Localizable", "nighthawk.autoshield.detail2", fallback: "We are committed to providing regular updates on the latest privacy-preserving best practices and recommendations to keep you well-informed.")
      /// Shielded-by-Default.
      public static let shieldedByDefault = L10n.tr("Localizable", "nighthawk.autoshield.shieldedByDefault", fallback: "Shielded-by-Default.")
      /// Shielding…
      public static let shielding = L10n.tr("Localizable", "nighthawk.autoshield.shielding", fallback: "Shielding…")
      /// Failed
      public static let shieldingFailed = L10n.tr("Localizable", "nighthawk.autoshield.shieldingFailed", fallback: "Failed")
      /// Auto-shielding with Nighthawk 🛡️
      public static let shieldingMemo = L10n.tr("Localizable", "nighthawk.autoshield.shieldingMemo", fallback: "Auto-shielding with Nighthawk 🛡️")
      /// Success
      public static let shieldingSuccess = L10n.tr("Localizable", "nighthawk.autoshield.shieldingSuccess", fallback: "Success")
      /// Nighthawk is now
      public static let title1 = L10n.tr("Localizable", "nighthawk.autoshield.title1", fallback: "Nighthawk is now")
      /// We have implemented measures to guarantee the highest level of confidentiality for your funds.
      public static let title2 = L10n.tr("Localizable", "nighthawk.autoshield.title2", fallback: "We have implemented measures to guarantee the highest level of confidentiality for your funds.")
      public enum Alert {
        public enum Redirecting {
          /// Please confirm opening your device browser to learn more about Unified Addresses.
          public static let details = L10n.tr("Localizable", "nighthawk.autoshield.alert.redirecting.details", fallback: "Please confirm opening your device browser to learn more about Unified Addresses.")
          /// Open Browser
          public static let openBrowser = L10n.tr("Localizable", "nighthawk.autoshield.alert.redirecting.openBrowser", fallback: "Open Browser")
          /// Redirecting to ElectricCoin.co
          public static let title = L10n.tr("Localizable", "nighthawk.autoshield.alert.redirecting.title", fallback: "Redirecting to ElectricCoin.co")
        }
      }
    }
    public enum ExportSeed {
      /// Export the seed words to a password protected PDF which can be backed up to user secured portable storage devices.
      public static let description = L10n.tr("Localizable", "nighthawk.exportSeed.description", fallback: "Export the seed words to a password protected PDF which can be backed up to user secured portable storage devices.")
      /// Export PDF
      public static let export = L10n.tr("Localizable", "nighthawk.exportSeed.export", fallback: "Export PDF")
      /// Please Enter Password
      public static let passwordPlaceholder = L10n.tr("Localizable", "nighthawk.exportSeed.passwordPlaceholder", fallback: "Please Enter Password")
      /// Export as PDF
      public static let title = L10n.tr("Localizable", "nighthawk.exportSeed.title", fallback: "Export as PDF")
    }
    public enum HomeScreen {
      /// Expecting %@ %@
      public static func expectingFunds(_ p1: Any, _ p2: Any) -> String {
        return L10n.tr("Localizable", "nighthawk.homeScreen.expectingFunds", String(describing: p1), String(describing: p2), fallback: "Expecting %@ %@")
      }
      /// Settings
      public static let settings = L10n.tr("Localizable", "nighthawk.homeScreen.settings", fallback: "Settings")
      /// Transfer
      public static let transfer = L10n.tr("Localizable", "nighthawk.homeScreen.transfer", fallback: "Transfer")
      /// Wallet
      public static let wallet = L10n.tr("Localizable", "nighthawk.homeScreen.wallet", fallback: "Wallet")
    }
    public enum ImportWallet {
      /// Birthday Height (optional)
      public static let birthdayHeight = L10n.tr("Localizable", "nighthawk.importWallet.birthdayHeight", fallback: "Birthday Height (optional)")
      /// Continue
      public static let `continue` = L10n.tr("Localizable", "nighthawk.importWallet.continue", fallback: "Continue")
      /// Enter your 24 word seed phrase below. If you do not have this phrase, you will need to create a new wallet.
      public static let enterSeedPhrase = L10n.tr("Localizable", "nighthawk.importWallet.enterSeedPhrase", fallback: "Enter your 24 word seed phrase below. If you do not have this phrase, you will need to create a new wallet.")
      /// Error ⸱ This doesn't look like a valid birthday height
      public static let invalidBirthday = L10n.tr("Localizable", "nighthawk.importWallet.invalidBirthday", fallback: "Error ⸱ This doesn't look like a valid birthday height")
      /// Error ⸱ This doesn't look like a valid seed phrase
      public static let invalidMnemonic = L10n.tr("Localizable", "nighthawk.importWallet.invalidMnemonic", fallback: "Error ⸱ This doesn't look like a valid seed phrase")
      /// Restore from backup
      public static let restoreFromBackup = L10n.tr("Localizable", "nighthawk.importWallet.restoreFromBackup", fallback: "Restore from backup")
      /// Your seed phrase
      public static let yourSeedPhrase = L10n.tr("Localizable", "nighthawk.importWallet.yourSeedPhrase", fallback: "Your seed phrase")
      public enum Alert {
        public enum Failed {
          /// Error: %@ (code: %@)
          public static func message(_ p1: Any, _ p2: Any) -> String {
            return L10n.tr("Localizable", "nighthawk.importWallet.alert.failed.message", String(describing: p1), String(describing: p2), fallback: "Error: %@ (code: %@)")
          }
          /// Failed to restore wallet
          public static let title = L10n.tr("Localizable", "nighthawk.importWallet.alert.failed.title", fallback: "Failed to restore wallet")
        }
      }
    }
    public enum ImportWalletSuccess {
      /// Success
      public static let success = L10n.tr("Localizable", "nighthawk.importWalletSuccess.success", fallback: "Success")
      /// View wallet
      public static let viewWallet = L10n.tr("Localizable", "nighthawk.importWalletSuccess.viewWallet", fallback: "View wallet")
    }
    public enum ImportWarning {
      /// Please only import a seed phrase that was initially generated by Nighthawk. Other wallets operate differently, which may lead to inaccurate reporting of funds for your transactions.
      public static let description = L10n.tr("Localizable", "nighthawk.importWarning.description", fallback: "Please only import a seed phrase that was initially generated by Nighthawk. Other wallets operate differently, which may lead to inaccurate reporting of funds for your transactions.")
      /// Proceed
      public static let proceed = L10n.tr("Localizable", "nighthawk.importWarning.proceed", fallback: "Proceed")
      /// Before you continue
      public static let title = L10n.tr("Localizable", "nighthawk.importWarning.title", fallback: "Before you continue")
    }
    public enum Licenses {
      /// OSS Licenses
      public static let title = L10n.tr("Localizable", "nighthawk.licenses.title", fallback: "OSS Licenses")
    }
    public enum LocalAuthentication {
      /// You must authenticate to access your Nighthawk wallet.
      public static let accessWalletReason = L10n.tr("Localizable", "nighthawk.localAuthentication.accessWalletReason", fallback: "You must authenticate to access your Nighthawk wallet.")
      /// You must authenticate to send funds from your wallet.
      public static let sendFundsReason = L10n.tr("Localizable", "nighthawk.localAuthentication.sendFundsReason", fallback: "You must authenticate to send funds from your wallet.")
    }
    public enum MigrateScreen {
      /// Continue
      public static let `continue` = L10n.tr("Localizable", "nighthawk.migrateScreen.continue", fallback: "Continue")
      /// We have a new secured way to store data locally, so we need to migrate your seed words to restore your wallet. If you don't want to migrate automatically then you will have to restore your wallet by adding the seed words manually.
      /// 
      /// Would you like to proceed automatically?
      public static let explanation = L10n.tr("Localizable", "nighthawk.migrateScreen.explanation", fallback: "We have a new secured way to store data locally, so we need to migrate your seed words to restore your wallet. If you don't want to migrate automatically then you will have to restore your wallet by adding the seed words manually.\n\nWould you like to proceed automatically?")
      /// Restore manually
      public static let restoreManually = L10n.tr("Localizable", "nighthawk.migrateScreen.restoreManually", fallback: "Restore manually")
      /// Migrating from old app version
      public static let title = L10n.tr("Localizable", "nighthawk.migrateScreen.title", fallback: "Migrating from old app version")
      public enum MigrationFailed {
        /// An error occurred and we were unable to migrate your wallet automatically. Tap continue to import your wallet manually.
        public static let description = L10n.tr("Localizable", "nighthawk.migrateScreen.migrationFailed.description", fallback: "An error occurred and we were unable to migrate your wallet automatically. Tap continue to import your wallet manually.")
        /// Migration failed
        public static let title = L10n.tr("Localizable", "nighthawk.migrateScreen.migrationFailed.title", fallback: "Migration failed")
      }
    }
    public enum RecoveryPhraseDisplay {
      /// Wallet birthday:
      public static let birthday = L10n.tr("Localizable", "nighthawk.recoveryPhraseDisplay.birthday", fallback: "Wallet birthday:")
      /// I confirm I have saved my seed phrase.
      public static let confirmPhraseWrittenDownCheckBox = L10n.tr("Localizable", "nighthawk.recoveryPhraseDisplay.confirmPhraseWrittenDownCheckBox", fallback: "I confirm I have saved my seed phrase.")
      /// Continue
      public static let `continue` = L10n.tr("Localizable", "nighthawk.recoveryPhraseDisplay.continue", fallback: "Continue")
      /// Nighthawk Wallet
      public static let exportAppName = L10n.tr("Localizable", "nighthawk.recoveryPhraseDisplay.exportAppName", fallback: "Nighthawk Wallet")
      /// Export as PDF
      public static let exportAsPdf = L10n.tr("Localizable", "nighthawk.recoveryPhraseDisplay.exportAsPdf", fallback: "Export as PDF")
      /// If you lose access to your phone or Nighthawk wallet, the only way you can regain access to your Zcash is if you have this 24 word phrase and wallet birthday code.
      public static let instructions1 = L10n.tr("Localizable", "nighthawk.recoveryPhraseDisplay.instructions1", fallback: "If you lose access to your phone or Nighthawk wallet, the only way you can regain access to your Zcash is if you have this 24 word phrase and wallet birthday code.")
      /// Write it down on paper and store it somewhere safe.
      public static let instructions2 = L10n.tr("Localizable", "nighthawk.recoveryPhraseDisplay.instructions2", fallback: "Write it down on paper and store it somewhere safe.")
      /// These are seed words used to restore your Zcash in Nighthawk Wallet:
      public static let pdfHeader = L10n.tr("Localizable", "nighthawk.recoveryPhraseDisplay.pdfHeader", fallback: "These are seed words used to restore your Zcash in Nighthawk Wallet:")
      /// Backup PDF generated at %@
      public static func pdfTimestamp(_ p1: Any) -> String {
        return L10n.tr("Localizable", "nighthawk.recoveryPhraseDisplay.pdfTimestamp", String(describing: p1), fallback: "Backup PDF generated at %@")
      }
      /// Write down your backup seed
      public static let title = L10n.tr("Localizable", "nighthawk.recoveryPhraseDisplay.title", fallback: "Write down your backup seed")
    }
    public enum SettingsTab {
      /// Nighthawk v%@ & Licenses
      public static func aboutSubtitle(_ p1: Any) -> String {
        return L10n.tr("Localizable", "nighthawk.settingsTab.aboutSubtitle", String(describing: p1), fallback: "Nighthawk v%@ & Licenses")
      }
      /// About
      public static let aboutTitle = L10n.tr("Localizable", "nighthawk.settingsTab.aboutTitle", fallback: "About")
      /// Less common settings
      public static let advancedSubtitle = L10n.tr("Localizable", "nighthawk.settingsTab.advancedSubtitle", fallback: "Less common settings")
      /// Advanced
      public static let advancedTitle = L10n.tr("Localizable", "nighthawk.settingsTab.advancedTitle", fallback: "Advanced")
      /// Keep your wallet safe in case you lose your phone
      public static let backupSubtitle = L10n.tr("Localizable", "nighthawk.settingsTab.backupSubtitle", fallback: "Keep your wallet safe in case you lose your phone")
      /// Backup your wallet
      public static let backupTitle = L10n.tr("Localizable", "nighthawk.settingsTab.backupTitle", fallback: "Backup your wallet")
      /// Change backend lightwalletd server
      public static let changeServerSubtitle = L10n.tr("Localizable", "nighthawk.settingsTab.changeServerSubtitle", fallback: "Change backend lightwalletd server")
      /// Change server
      public static let changeServerTitle = L10n.tr("Localizable", "nighthawk.settingsTab.changeServerTitle", fallback: "Change server")
      /// Opt-in to our partner services
      public static let externalServicesSubtitle = L10n.tr("Localizable", "nighthawk.settingsTab.externalServicesSubtitle", fallback: "Opt-in to our partner services")
      /// External services
      public static let externalServicesTitle = L10n.tr("Localizable", "nighthawk.settingsTab.externalServicesTitle", fallback: "External services")
      /// Choose your local currency
      public static let fiatSubtitle = L10n.tr("Localizable", "nighthawk.settingsTab.fiatSubtitle", fallback: "Choose your local currency")
      /// Fiat Currency
      public static let fiatTitle = L10n.tr("Localizable", "nighthawk.settingsTab.fiatTitle", fallback: "Fiat Currency")
      /// Reminding you to keep the wallet up-to-date
      public static let notificationsSubtitle = L10n.tr("Localizable", "nighthawk.settingsTab.notificationsSubtitle", fallback: "Reminding you to keep the wallet up-to-date")
      /// Sync notifications
      public static let notificationsTitle = L10n.tr("Localizable", "nighthawk.settingsTab.notificationsTitle", fallback: "Sync notifications")
      /// Rescan wallet balances to troubleshoot issues
      public static let rescanSubtitle = L10n.tr("Localizable", "nighthawk.settingsTab.rescanSubtitle", fallback: "Rescan wallet balances to troubleshoot issues")
      /// Rescan wallet
      public static let rescanTitle = L10n.tr("Localizable", "nighthawk.settingsTab.rescanTitle", fallback: "Rescan wallet")
      /// Enable/Disable %@
      public static func securitySubtitle(_ p1: Any) -> String {
        return L10n.tr("Localizable", "nighthawk.settingsTab.securitySubtitle", String(describing: p1), fallback: "Enable/Disable %@")
      }
      /// Security
      public static let securityTitle = L10n.tr("Localizable", "nighthawk.settingsTab.securityTitle", fallback: "Security")
      /// Settings
      public static let settings = L10n.tr("Localizable", "nighthawk.settingsTab.settings", fallback: "Settings")
      public enum Advanced {
        /// Advanced settings
        public static let title = L10n.tr("Localizable", "nighthawk.settingsTab.advanced.title", fallback: "Advanced settings")
        public enum AppIcon {
          /// Default
          public static let `default` = L10n.tr("Localizable", "nighthawk.settingsTab.advanced.appIcon.default", fallback: "Default")
          /// Retro
          public static let retro = L10n.tr("Localizable", "nighthawk.settingsTab.advanced.appIcon.retro", fallback: "Retro")
          /// App icon
          public static let title = L10n.tr("Localizable", "nighthawk.settingsTab.advanced.appIcon.title", fallback: "App icon")
          public enum Toast {
            /// App icon updated!
            public static let updated = L10n.tr("Localizable", "nighthawk.settingsTab.advanced.appIcon.toast.updated", fallback: "App icon updated!")
          }
        }
        public enum DeleteWallet {
          /// CAUTION: This will completely wipe your wallet and you will be unable to recover funds without your seed words. Ensure you have you have them saved somewhere safe before proceeding. Wallet deletion is an extremely sensitive operation. So sensitive, in fact, that you must manually close the app and restart Nighthawk before creating a new wallet or restoring a wallet.
          public static let subtitle = L10n.tr("Localizable", "nighthawk.settingsTab.advanced.deleteWallet.subtitle", fallback: "CAUTION: This will completely wipe your wallet and you will be unable to recover funds without your seed words. Ensure you have you have them saved somewhere safe before proceeding. Wallet deletion is an extremely sensitive operation. So sensitive, in fact, that you must manually close the app and restart Nighthawk before creating a new wallet or restoring a wallet.")
          /// Delete wallet
          public static let title = L10n.tr("Localizable", "nighthawk.settingsTab.advanced.deleteWallet.title", fallback: "Delete wallet")
          public enum Alert {
            public enum LastWarning {
              /// This operation is IRREVERSIBLE. Restoring your funds will be impossible without your seed words. Be ABSOLUTELY sure you have you have them saved somewhere safe before proceeding. Do you still want to proceed?
              public static let message = L10n.tr("Localizable", "nighthawk.settingsTab.advanced.deleteWallet.alert.lastWarning.message", fallback: "This operation is IRREVERSIBLE. Restoring your funds will be impossible without your seed words. Be ABSOLUTELY sure you have you have them saved somewhere safe before proceeding. Do you still want to proceed?")
              /// ARE YOU SURE?
              public static let title = L10n.tr("Localizable", "nighthawk.settingsTab.advanced.deleteWallet.alert.lastWarning.title", fallback: "ARE YOU SURE?")
            }
            public enum RelaunchRequired {
              /// I confirm, delete wallet
              public static let confirm = L10n.tr("Localizable", "nighthawk.settingsTab.advanced.deleteWallet.alert.relaunchRequired.confirm", fallback: "I confirm, delete wallet")
              /// Wallet deletion is an extremely sensitive operation. So sensitive, in fact, that you must manually close the app and restart Nighthawk before creating a new wallet or restoring a wallet.
              public static let message = L10n.tr("Localizable", "nighthawk.settingsTab.advanced.deleteWallet.alert.relaunchRequired.message", fallback: "Wallet deletion is an extremely sensitive operation. So sensitive, in fact, that you must manually close the app and restart Nighthawk before creating a new wallet or restoring a wallet.")
              /// FINAL WARNING
              public static let title = L10n.tr("Localizable", "nighthawk.settingsTab.advanced.deleteWallet.alert.relaunchRequired.title", fallback: "FINAL WARNING")
            }
          }
        }
        public enum ScreenMode {
          /// Keep on
          public static let keepOn = L10n.tr("Localizable", "nighthawk.settingsTab.advanced.screenMode.keepOn", fallback: "Keep on")
          /// Off
          public static let off = L10n.tr("Localizable", "nighthawk.settingsTab.advanced.screenMode.off", fallback: "Off")
          /// If you haven't opened your wallet in a while, the sync process can take some time. Setting screen mode to 'Keep on' will ensure your phone doesn't fall asleep while syncing.
          public static let subtitle = L10n.tr("Localizable", "nighthawk.settingsTab.advanced.screenMode.subtitle", fallback: "If you haven't opened your wallet in a while, the sync process can take some time. Setting screen mode to 'Keep on' will ensure your phone doesn't fall asleep while syncing.")
          /// Keep screen on
          public static let title = L10n.tr("Localizable", "nighthawk.settingsTab.advanced.screenMode.title", fallback: "Keep screen on")
        }
        public enum Theme {
          /// Dark
          public static let dark = L10n.tr("Localizable", "nighthawk.settingsTab.advanced.theme.dark", fallback: "Dark")
          /// Default
          public static let `default` = L10n.tr("Localizable", "nighthawk.settingsTab.advanced.theme.default", fallback: "Default")
          /// Theme
          public static let title = L10n.tr("Localizable", "nighthawk.settingsTab.advanced.theme.title", fallback: "Theme")
        }
      }
      public enum Alert {
        public enum Rescan {
          /// Rescanning may take up to 10 hours depending on the length of history of your wallet's transactions. Would you like to start a rescan?
          public static let message = L10n.tr("Localizable", "nighthawk.settingsTab.alert.rescan.message", fallback: "Rescanning may take up to 10 hours depending on the length of history of your wallet's transactions. Would you like to start a rescan?")
          /// Rescan this wallet?
          public static let title = L10n.tr("Localizable", "nighthawk.settingsTab.alert.rescan.title", fallback: "Rescan this wallet?")
          /// Wipe
          public static let wipe = L10n.tr("Localizable", "nighthawk.settingsTab.alert.rescan.wipe", fallback: "Wipe")
          public enum CantStartSync {
            /// Error: %@ (code: %@)
            public static func message(_ p1: Any, _ p2: Any) -> String {
              return L10n.tr("Localizable", "nighthawk.settingsTab.alert.rescan.cantStartSync.message", String(describing: p1), String(describing: p2), fallback: "Error: %@ (code: %@)")
            }
            /// Can't start sync process after rewind
            public static let title = L10n.tr("Localizable", "nighthawk.settingsTab.alert.rescan.cantStartSync.title", fallback: "Can't start sync process after rewind")
          }
          public enum Failed {
            /// Error: %@ (code: %@)
            public static func message(_ p1: Any, _ p2: Any) -> String {
              return L10n.tr("Localizable", "nighthawk.settingsTab.alert.rescan.failed.message", String(describing: p1), String(describing: p2), fallback: "Error: %@ (code: %@)")
            }
            /// Rescan failed
            public static let title = L10n.tr("Localizable", "nighthawk.settingsTab.alert.rescan.failed.title", fallback: "Rescan failed")
          }
        }
      }
      public enum Backup {
        /// View seed
        public static let viewSeedWarningAlertConfirmAction = L10n.tr("Localizable", "nighthawk.settingsTab.backup.viewSeedWarningAlertConfirmAction", fallback: "View seed")
        /// WARNING: Please make sure that you are the only one viewing your phone as your wallet seed key will be shown in the next screen.
        public static let viewSeedWarningAlertMessage = L10n.tr("Localizable", "nighthawk.settingsTab.backup.viewSeedWarningAlertMessage", fallback: "WARNING: Please make sure that you are the only one viewing your phone as your wallet seed key will be shown in the next screen.")
        /// View seed words?
        public static let viewSeedWarningAlertTitle = L10n.tr("Localizable", "nighthawk.settingsTab.backup.viewSeedWarningAlertTitle", fallback: "View seed words?")
      }
      public enum ChangeServer {
        /// Custom
        public static let custom = L10n.tr("Localizable", "nighthawk.settingsTab.changeServer.custom", fallback: "Custom")
        /// Default (%@)
        public static func `default`(_ p1: Any) -> String {
          return L10n.tr("Localizable", "nighthawk.settingsTab.changeServer.default", String(describing: p1), fallback: "Default (%@)")
        }
        /// The servers are not operated by Nighthawk, and the privacy of communication and broadcasting transactions cannot be guaranteed. We recommend using a VPN or Tor for enhanced privacy before making transactions.
        public static let disclaimer = L10n.tr("Localizable", "nighthawk.settingsTab.changeServer.disclaimer", fallback: "The servers are not operated by Nighthawk, and the privacy of communication and broadcasting transactions cannot be guaranteed. We recommend using a VPN or Tor for enhanced privacy before making transactions.")
        /// Save
        public static let save = L10n.tr("Localizable", "nighthawk.settingsTab.changeServer.save", fallback: "Save")
        /// Change server
        public static let title = L10n.tr("Localizable", "nighthawk.settingsTab.changeServer.title", fallback: "Change server")
        public enum Alert {
          public enum ChangeServerFailed {
            /// Error: %@ (code: %@)
            public static func message(_ p1: Any, _ p2: Any) -> String {
              return L10n.tr("Localizable", "nighthawk.settingsTab.changeServer.alert.changeServerFailed.message", String(describing: p1), String(describing: p2), fallback: "Error: %@ (code: %@)")
            }
            /// Unable to change lightwalletd servers
            public static let title = L10n.tr("Localizable", "nighthawk.settingsTab.changeServer.alert.changeServerFailed.title", fallback: "Unable to change lightwalletd servers")
          }
        }
        public enum Custom {
          /// Error ⸱ This doesn't look like a valid lightwalletd server
          public static let invalidLightwalletd = L10n.tr("Localizable", "nighthawk.settingsTab.changeServer.custom.invalidLightwalletd", fallback: "Error ⸱ This doesn't look like a valid lightwalletd server")
        }
      }
      public enum ExternalServices {
        /// External services
        public static let title = L10n.tr("Localizable", "nighthawk.settingsTab.externalServices.title", fallback: "External services")
        /// Enable Unstoppable Domain Service
        public static let unstoppableDomainsToggle = L10n.tr("Localizable", "nighthawk.settingsTab.externalServices.unstoppableDomainsToggle", fallback: "Enable Unstoppable Domain Service")
      }
      public enum FiatCurrency {
        /// Australian Dollar
        public static let aud = L10n.tr("Localizable", "nighthawk.settingsTab.fiatCurrency.aud", fallback: "Australian Dollar")
        /// Canadian Dollar
        public static let cad = L10n.tr("Localizable", "nighthawk.settingsTab.fiatCurrency.cad", fallback: "Canadian Dollar")
        /// Swiss Franc
        public static let chf = L10n.tr("Localizable", "nighthawk.settingsTab.fiatCurrency.chf", fallback: "Swiss Franc")
        /// Chinese Yuan
        public static let cny = L10n.tr("Localizable", "nighthawk.settingsTab.fiatCurrency.cny", fallback: "Chinese Yuan")
        /// Choose your local currency so that we can show you a close estimate of how much your %@ is worth.
        /// 
        /// When you first open the app, the exchange rate is fetched from CoinGecko API v3 and used to calculate values. Your fund amounts are never revealed to any server.
        public static func description(_ p1: Any) -> String {
          return L10n.tr("Localizable", "nighthawk.settingsTab.fiatCurrency.description", String(describing: p1), fallback: "Choose your local currency so that we can show you a close estimate of how much your %@ is worth.\n\nWhen you first open the app, the exchange rate is fetched from CoinGecko API v3 and used to calculate values. Your fund amounts are never revealed to any server.")
        }
        /// Euro
        public static let eur = L10n.tr("Localizable", "nighthawk.settingsTab.fiatCurrency.eur", fallback: "Euro")
        /// British Pound
        public static let gbp = L10n.tr("Localizable", "nighthawk.settingsTab.fiatCurrency.gbp", fallback: "British Pound")
        /// Hong Kong Dollar
        public static let hkd = L10n.tr("Localizable", "nighthawk.settingsTab.fiatCurrency.hkd", fallback: "Hong Kong Dollar")
        /// Indian Rupee
        public static let inr = L10n.tr("Localizable", "nighthawk.settingsTab.fiatCurrency.inr", fallback: "Indian Rupee")
        /// Japanese Yen
        public static let jpy = L10n.tr("Localizable", "nighthawk.settingsTab.fiatCurrency.jpy", fallback: "Japanese Yen")
        /// Korean Won
        public static let krw = L10n.tr("Localizable", "nighthawk.settingsTab.fiatCurrency.krw", fallback: "Korean Won")
        /// Off
        public static let off = L10n.tr("Localizable", "nighthawk.settingsTab.fiatCurrency.off", fallback: "Off")
        /// Singapore Dollar
        public static let sgd = L10n.tr("Localizable", "nighthawk.settingsTab.fiatCurrency.sgd", fallback: "Singapore Dollar")
        /// Fiat Currency
        public static let title = L10n.tr("Localizable", "nighthawk.settingsTab.fiatCurrency.title", fallback: "Fiat Currency")
        /// United States Dollar
        public static let usd = L10n.tr("Localizable", "nighthawk.settingsTab.fiatCurrency.usd", fallback: "United States Dollar")
      }
      public enum Security {
        /// %@ disabled
        public static func biometricsDisabled(_ p1: Any) -> String {
          return L10n.tr("Localizable", "nighthawk.settingsTab.security.biometricsDisabled", String(describing: p1), fallback: "%@ disabled")
        }
        /// %@ enabled
        public static func biometricsEnabled(_ p1: Any) -> String {
          return L10n.tr("Localizable", "nighthawk.settingsTab.security.biometricsEnabled", String(describing: p1), fallback: "%@ enabled")
        }
        /// Authenticate to disable %@
        public static func disableValidationReason(_ p1: Any) -> String {
          return L10n.tr("Localizable", "nighthawk.settingsTab.security.disableValidationReason", String(describing: p1), fallback: "Authenticate to disable %@")
        }
        /// Authenticate to enable %@
        public static func enableValidationReason(_ p1: Any) -> String {
          return L10n.tr("Localizable", "nighthawk.settingsTab.security.enableValidationReason", String(describing: p1), fallback: "Authenticate to enable %@")
        }
      }
      public enum SyncNotifications {
        /// When Nighthawk wallet is closed for a long period of time, then it will take longer to start up when you do want to use it.
        public static let description = L10n.tr("Localizable", "nighthawk.settingsTab.syncNotifications.description", fallback: "When Nighthawk wallet is closed for a long period of time, then it will take longer to start up when you do want to use it.")
        /// Allow sync notifications to remind you to open the wallet every month.
        public static let monthlyDescription = L10n.tr("Localizable", "nighthawk.settingsTab.syncNotifications.monthlyDescription", fallback: "Allow sync notifications to remind you to open the wallet every month.")
        /// Monthly
        public static let monthlyOption = L10n.tr("Localizable", "nighthawk.settingsTab.syncNotifications.monthlyOption", fallback: "Monthly")
        /// Off
        public static let offOption = L10n.tr("Localizable", "nighthawk.settingsTab.syncNotifications.offOption", fallback: "Off")
        /// Sync notifications
        public static let title = L10n.tr("Localizable", "nighthawk.settingsTab.syncNotifications.title", fallback: "Sync notifications")
        /// Allow sync notifications to remind you to open the wallet every week.
        public static let weeklyDescription = L10n.tr("Localizable", "nighthawk.settingsTab.syncNotifications.weeklyDescription", fallback: "Allow sync notifications to remind you to open the wallet every week.")
        /// Weekly
        public static let weeklyOption = L10n.tr("Localizable", "nighthawk.settingsTab.syncNotifications.weeklyOption", fallback: "Weekly")
        public enum Notification {
          /// Open Nighthawk and sync your wallet so your funds are ready to spend when you need them!
          public static let detail = L10n.tr("Localizable", "nighthawk.settingsTab.syncNotifications.notification.detail", fallback: "Open Nighthawk and sync your wallet so your funds are ready to spend when you need them!")
          /// Time to sync!
          public static let title = L10n.tr("Localizable", "nighthawk.settingsTab.syncNotifications.notification.title", fallback: "Time to sync!")
        }
        public enum PermissionDeniedAlert {
          /// Nighthawk needs permission in order to send sync notifications. Please open settings and grant the necessary permissions.
          public static let description = L10n.tr("Localizable", "nighthawk.settingsTab.syncNotifications.permissionDeniedAlert.description", fallback: "Nighthawk needs permission in order to send sync notifications. Please open settings and grant the necessary permissions.")
          /// Go to settings
          public static let goToSettings = L10n.tr("Localizable", "nighthawk.settingsTab.syncNotifications.permissionDeniedAlert.goToSettings", fallback: "Go to settings")
          /// Permission denied
          public static let title = L10n.tr("Localizable", "nighthawk.settingsTab.syncNotifications.permissionDeniedAlert.title", fallback: "Permission denied")
        }
        public enum ScheduleNotificationFailedAlert {
          /// We were unable to schedule your sync notification at this time.
          public static let details = L10n.tr("Localizable", "nighthawk.settingsTab.syncNotifications.scheduleNotificationFailedAlert.details", fallback: "We were unable to schedule your sync notification at this time.")
          /// Failed to schedule notification
          public static let title = L10n.tr("Localizable", "nighthawk.settingsTab.syncNotifications.scheduleNotificationFailedAlert.title", fallback: "Failed to schedule notification")
        }
      }
    }
    public enum Splash {
      /// Retry
      public static let retry = L10n.tr("Localizable", "nighthawk.splash.retry", fallback: "Retry")
      /// Private money in your pocket.
      public static let subtitle = L10n.tr("Localizable", "nighthawk.splash.subtitle", fallback: "Private money in your pocket.")
      /// Nighthawk
      public static let title = L10n.tr("Localizable", "nighthawk.splash.title", fallback: "Nighthawk")
      public enum Initialization {
        public enum Alert {
          public enum Failed {
            /// Wallet initialisation failed.
            public static let title = L10n.tr("Localizable", "nighthawk.splash.initialization.alert.failed.title", fallback: "Wallet initialisation failed.")
          }
          public enum WalletStateFailed {
            /// App initialisation state: %@.
            public static func message(_ p1: Any) -> String {
              return L10n.tr("Localizable", "nighthawk.splash.initialization.alert.walletStateFailed.message", String(describing: p1), fallback: "App initialisation state: %@.")
            }
          }
        }
      }
    }
    public enum Sync {
      public enum Message {
        /// Error: %@
        public static func error(_ p1: Any) -> String {
          return L10n.tr("Localizable", "nighthawk.sync.message.error", String(describing: p1), fallback: "Error: %@")
        }
        /// Finalizing
        public static let finalizing = L10n.tr("Localizable", "nighthawk.sync.message.finalizing", fallback: "Finalizing")
        /// Preparing to scan
        public static let preparing = L10n.tr("Localizable", "nighthawk.sync.message.preparing", fallback: "Preparing to scan")
        /// Stopped
        public static let stopped = L10n.tr("Localizable", "nighthawk.sync.message.stopped", fallback: "Stopped")
        /// Scanning…%@%%
        public static func sync(_ p1: Any) -> String {
          return L10n.tr("Localizable", "nighthawk.sync.message.sync", String(describing: p1), fallback: "Scanning…%@%%")
        }
        /// Connecting…
        public static let unprepared = L10n.tr("Localizable", "nighthawk.sync.message.unprepared", fallback: "Connecting…")
        /// Up-To-Date
        public static let uptodate = L10n.tr("Localizable", "nighthawk.sync.message.uptodate", fallback: "Up-To-Date")
      }
    }
    public enum Transaction {
      /// Confirmed
      public static let confirmed = L10n.tr("Localizable", "nighthawk.transaction.confirmed", fallback: "Confirmed")
      /// Failed
      public static let failed = L10n.tr("Localizable", "nighthawk.transaction.failed", fallback: "Failed")
      /// Received
      public static let received = L10n.tr("Localizable", "nighthawk.transaction.received", fallback: "Received")
      /// Receiving
      public static let receiving = L10n.tr("Localizable", "nighthawk.transaction.receiving", fallback: "Receiving")
      /// Sending
      public static let sending = L10n.tr("Localizable", "nighthawk.transaction.sending", fallback: "Sending")
      /// Sent
      public static let sent = L10n.tr("Localizable", "nighthawk.transaction.sent", fallback: "Sent")
    }
    public enum TransactionDetails {
      /// Address
      public static let address = L10n.tr("Localizable", "nighthawk.transactionDetails.address", fallback: "Address")
      /// Block ID
      public static let blockId = L10n.tr("Localizable", "nighthawk.transactionDetails.blockId", fallback: "Block ID")
      /// Confirmations
      public static let confirmations = L10n.tr("Localizable", "nighthawk.transactionDetails.confirmations", fallback: "Confirmations")
      /// Leaving Nighthawk Wallet
      public static let leavingWallet = L10n.tr("Localizable", "nighthawk.transactionDetails.leavingWallet", fallback: "Leaving Nighthawk Wallet")
      /// While usually an acceptable risk, you will be possibly exposing your interest in this transaction id by visiting %@
      public static func leavingWarning(_ p1: Any) -> String {
        return L10n.tr("Localizable", "nighthawk.transactionDetails.leavingWarning", String(describing: p1), fallback: "While usually an acceptable risk, you will be possibly exposing your interest in this transaction id by visiting %@")
      }
      /// Memo
      public static let memo = L10n.tr("Localizable", "nighthawk.transactionDetails.memo", fallback: "Memo")
      /// Network fee
      public static let networkFee = L10n.tr("Localizable", "nighthawk.transactionDetails.networkFee", fallback: "Network fee")
      /// Transaction details are not available, please wait until scanning is finished
      public static let notAvailable = L10n.tr("Localizable", "nighthawk.transactionDetails.notAvailable", fallback: "Transaction details are not available, please wait until scanning is finished")
      /// Pool
      public static let pool = L10n.tr("Localizable", "nighthawk.transactionDetails.pool", fallback: "Pool")
      /// Recipient
      public static let recipient = L10n.tr("Localizable", "nighthawk.transactionDetails.recipient", fallback: "Recipient")
      /// Shielded
      public static let recipientShielded = L10n.tr("Localizable", "nighthawk.transactionDetails.recipientShielded", fallback: "Shielded")
      /// Transparent
      public static let recipientTransparent = L10n.tr("Localizable", "nighthawk.transactionDetails.recipientTransparent", fallback: "Transparent")
      /// Reply-to address copied!
      public static let replyToCopied = L10n.tr("Localizable", "nighthawk.transactionDetails.replyToCopied", fallback: "Reply-to address copied!")
      /// Sapling
      public static let sapling = L10n.tr("Localizable", "nighthawk.transactionDetails.sapling", fallback: "Sapling")
      /// Time (UTC)
      public static let time = L10n.tr("Localizable", "nighthawk.transactionDetails.time", fallback: "Time (UTC)")
      /// Transaction details
      public static let title = L10n.tr("Localizable", "nighthawk.transactionDetails.title", fallback: "Transaction details")
      /// Total amount
      public static let totalAmount = L10n.tr("Localizable", "nighthawk.transactionDetails.totalAmount", fallback: "Total amount")
      /// Transaction ID
      public static let transactionId = L10n.tr("Localizable", "nighthawk.transactionDetails.transactionId", fallback: "Transaction ID")
      /// Transparent
      public static let transparent = L10n.tr("Localizable", "nighthawk.transactionDetails.transparent", fallback: "Transparent")
      /// Unconfirmed
      public static let unconfirmed = L10n.tr("Localizable", "nighthawk.transactionDetails.unconfirmed", fallback: "Unconfirmed")
      /// View on Block Explorer
      public static let viewOnBlockExplorer = L10n.tr("Localizable", "nighthawk.transactionDetails.viewOnBlockExplorer", fallback: "View on Block Explorer")
      /// View on explorer
      public static let viewOnExplorer = L10n.tr("Localizable", "nighthawk.transactionDetails.viewOnExplorer", fallback: "View on explorer")
      /// View TX details
      public static let viewTxDetails = L10n.tr("Localizable", "nighthawk.transactionDetails.viewTxDetails", fallback: "View TX details")
      public enum Fiat {
        /// around %@ %@
        public static func around(_ p1: Any, _ p2: Any) -> String {
          return L10n.tr("Localizable", "nighthawk.transactionDetails.fiat.around", String(describing: p1), String(describing: p2), fallback: "around %@ %@")
        }
      }
    }
    public enum TransactionHistory {
      /// Auto-shielded funds
      public static let autoshieldedFunds = L10n.tr("Localizable", "nighthawk.transactionHistory.autoshieldedFunds", fallback: "Auto-shielded funds")
      /// Transaction History
      public static let title = L10n.tr("Localizable", "nighthawk.transactionHistory.title", fallback: "Transaction History")
      /// %@ %@
      public static func zecAmount(_ p1: Any, _ p2: Any) -> String {
        return L10n.tr("Localizable", "nighthawk.transactionHistory.zecAmount", String(describing: p1), String(describing: p2), fallback: "%@ %@")
      }
    }
    public enum TransferTab {
      /// Display your QR code or copy your address.
      public static let receiveMoneyDescription = L10n.tr("Localizable", "nighthawk.transferTab.receiveMoneyDescription", fallback: "Display your QR code or copy your address.")
      /// Receive money
      public static let receiveMoneyTitle = L10n.tr("Localizable", "nighthawk.transferTab.receiveMoneyTitle", fallback: "Receive money")
      /// Send and receive Zcash
      public static let sendAndReceiveZcash = L10n.tr("Localizable", "nighthawk.transferTab.sendAndReceiveZcash", fallback: "Send and receive Zcash")
      /// Let someone scan to send you money.
      public static let sendMoneyDescription = L10n.tr("Localizable", "nighthawk.transferTab.sendMoneyDescription", fallback: "Let someone scan to send you money.")
      /// Send money
      public static let sendMoneyTitle = L10n.tr("Localizable", "nighthawk.transferTab.sendMoneyTitle", fallback: "Send money")
      /// Securely buy Zcash through our partners.
      public static let topUpWalletDescription = L10n.tr("Localizable", "nighthawk.transferTab.topUpWalletDescription", fallback: "Securely buy Zcash through our partners.")
      /// Top up your wallet
      public static let topUpWalletTitle = L10n.tr("Localizable", "nighthawk.transferTab.topUpWalletTitle", fallback: "Top up your wallet")
      public enum AddMemo {
        /// Add a message to your payment
        public static let addMessageToPayment = L10n.tr("Localizable", "nighthawk.transferTab.addMemo.addMessageToPayment", fallback: "Add a message to your payment")
        /// Include reply-to
        public static let includeReplyTo = L10n.tr("Localizable", "nighthawk.transferTab.addMemo.includeReplyTo", fallback: "Include reply-to")
        /// Write something...
        public static let writeSomething = L10n.tr("Localizable", "nighthawk.transferTab.addMemo.writeSomething", fallback: "Write something...")
      }
      public enum Failed {
        /// Cancel
        public static let cancel = L10n.tr("Localizable", "nighthawk.transferTab.failed.cancel", fallback: "Cancel")
        /// Failed
        public static let title = L10n.tr("Localizable", "nighthawk.transferTab.failed.title", fallback: "Failed")
        /// Try again
        public static let tryAgain = L10n.tr("Localizable", "nighthawk.transferTab.failed.tryAgain", fallback: "Try again")
      }
      public enum Receive {
        /// This will copy your t-address.
        public static let copyNonPrivateAddressDescription = L10n.tr("Localizable", "nighthawk.transferTab.receive.copyNonPrivateAddressDescription", fallback: "This will copy your t-address.")
        /// Copy a non-private address
        public static let copyNonPrivateAddressTitle = L10n.tr("Localizable", "nighthawk.transferTab.receive.copyNonPrivateAddressTitle", fallback: "Copy a non-private address")
        /// Your wallet address will be copied to the clipboard.
        public static let copyUnifiedAddressDescription = L10n.tr("Localizable", "nighthawk.transferTab.receive.copyUnifiedAddressDescription", fallback: "Your wallet address will be copied to the clipboard.")
        /// Copy unified address
        public static let copyUnifiedAddressTitle = L10n.tr("Localizable", "nighthawk.transferTab.receive.copyUnifiedAddressTitle", fallback: "Copy unified address")
        /// Receive money publicly
        public static let receiveMoneyPublicly = L10n.tr("Localizable", "nighthawk.transferTab.receive.receiveMoneyPublicly", fallback: "Receive money publicly")
        /// Receive money privately
        public static let receiveMoneySecurely = L10n.tr("Localizable", "nighthawk.transferTab.receive.receiveMoneySecurely", fallback: "Receive money privately")
        /// Show QR Code
        public static let showQrCodeTitle = L10n.tr("Localizable", "nighthawk.transferTab.receive.showQrCodeTitle", fallback: "Show QR Code")
      }
      public enum Recipient {
        /// Add address here
        public static let addAddress = L10n.tr("Localizable", "nighthawk.transferTab.recipient.addAddress", fallback: "Add address here")
        /// Choose who to send it to
        public static let chooseRecipient = L10n.tr("Localizable", "nighthawk.transferTab.recipient.chooseRecipient", fallback: "Choose who to send it to")
        /// Continue
        public static let `continue` = L10n.tr("Localizable", "nighthawk.transferTab.recipient.continue", fallback: "Continue")
        /// Sending to this recipient is currently not possible
        public static let currentlyUnsupported = L10n.tr("Localizable", "nighthawk.transferTab.recipient.currentlyUnsupported", fallback: "Sending to this recipient is currently not possible")
        /// Please enter a valid recipient
        public static let invalid = L10n.tr("Localizable", "nighthawk.transferTab.recipient.invalid", fallback: "Please enter a valid recipient")
        /// Paste from clipboard
        public static let pasteFromClipboard = L10n.tr("Localizable", "nighthawk.transferTab.recipient.pasteFromClipboard", fallback: "Paste from clipboard")
      }
      public enum Review {
        /// Send Zcash
        public static let send = L10n.tr("Localizable", "nighthawk.transferTab.review.send", fallback: "Send Zcash")
        /// Review and send
        public static let title = L10n.tr("Localizable", "nighthawk.transferTab.review.title", fallback: "Review and send")
      }
      public enum Scan {
        /// Scan a Payment Request
        public static let scanPaymentRequest = L10n.tr("Localizable", "nighthawk.transferTab.scan.scanPaymentRequest", fallback: "Scan a Payment Request")
        /// If you have a payment request, you can scan the QR code here to auto-fill all the details.
        public static let scanPaymentRequestDetails = L10n.tr("Localizable", "nighthawk.transferTab.scan.scanPaymentRequestDetails", fallback: "If you have a payment request, you can scan the QR code here to auto-fill all the details.")
      }
      public enum Send {
        /// around %@ %@
        public static func around(_ p1: Any, _ p2: Any) -> String {
          return L10n.tr("Localizable", "nighthawk.transferTab.send.around", String(describing: p1), String(describing: p2), fallback: "around %@ %@")
        }
        /// Choose how much to send
        public static let chooseHowMuch = L10n.tr("Localizable", "nighthawk.transferTab.send.chooseHowMuch", fallback: "Choose how much to send")
        /// Continue
        public static let `continue` = L10n.tr("Localizable", "nighthawk.transferTab.send.continue", fallback: "Continue")
        /// Error
        public static let error = L10n.tr("Localizable", "nighthawk.transferTab.send.error", fallback: "Error")
        /// %@
        public static func proposalFailed(_ p1: Any) -> String {
          return L10n.tr("Localizable", "nighthawk.transferTab.send.proposalFailed", String(describing: p1), fallback: "%@")
        }
        /// Scan a payment code
        public static let scanCode = L10n.tr("Localizable", "nighthawk.transferTab.send.scanCode", fallback: "Scan a payment code")
        /// Spendable balance (incl. tx fee) is %@ %@
        public static func spendableBalance(_ p1: Any, _ p2: Any) -> String {
          return L10n.tr("Localizable", "nighthawk.transferTab.send.spendableBalance", String(describing: p1), String(describing: p2), fallback: "Spendable balance (incl. tx fee) is %@ %@")
        }
        /// Top up wallet
        public static let topUpWallet = L10n.tr("Localizable", "nighthawk.transferTab.send.topUpWallet", fallback: "Top up wallet")
        public enum Toast {
          /// Not enough Zcash!
          public static let notEnoughZcash = L10n.tr("Localizable", "nighthawk.transferTab.send.toast.notEnoughZcash", fallback: "Not enough Zcash!")
        }
      }
      public enum Sending {
        /// Sending
        public static let title = L10n.tr("Localizable", "nighthawk.transferTab.sending.title", fallback: "Sending")
      }
      public enum Success {
        /// Done
        public static let done = L10n.tr("Localizable", "nighthawk.transferTab.success.done", fallback: "Done")
        /// More details
        public static let moreDetails = L10n.tr("Localizable", "nighthawk.transferTab.success.moreDetails", fallback: "More details")
        /// Success
        public static let title = L10n.tr("Localizable", "nighthawk.transferTab.success.title", fallback: "Success")
      }
      public enum TopUpWallet {
        /// Your %@ has been copied to the clipboard.
        /// 
        /// Choose "Open Browser" below, select '%@' as the receiving coin on the %@ site, and then paste your %@
        public static func fundWalletAlertMessage(_ p1: Any, _ p2: Any, _ p3: Any, _ p4: Any) -> String {
          return L10n.tr("Localizable", "nighthawk.transferTab.topUpWallet.fundWalletAlertMessage", String(describing: p1), String(describing: p2), String(describing: p3), String(describing: p4), fallback: "Your %@ has been copied to the clipboard.\n\nChoose \"Open Browser\" below, select '%@' as the receiving coin on the %@ site, and then paste your %@")
        }
        /// Fund wallet with %@?
        public static func fundWalletAlertTitle(_ p1: Any) -> String {
          return L10n.tr("Localizable", "nighthawk.transferTab.topUpWallet.fundWalletAlertTitle", String(describing: p1), fallback: "Fund wallet with %@?")
        }
        /// Open Browser
        public static let openBrowser = L10n.tr("Localizable", "nighthawk.transferTab.topUpWallet.openBrowser", fallback: "Open Browser")
        /// Swap between 30+ coins. No sign-up required.
        public static let sideshiftDescription = L10n.tr("Localizable", "nighthawk.transferTab.topUpWallet.sideshiftDescription", fallback: "Swap between 30+ coins. No sign-up required.")
        /// Swap with SideShift.ai
        public static let sideshiftTitle = L10n.tr("Localizable", "nighthawk.transferTab.topUpWallet.sideshiftTitle", fallback: "Swap with SideShift.ai")
        /// Swap transparent coins without limits.
        public static let stealthExIoDescription = L10n.tr("Localizable", "nighthawk.transferTab.topUpWallet.stealthExIoDescription", fallback: "Swap transparent coins without limits.")
        /// Swap with StealthEx.io
        public static let stealthExIoTitle = L10n.tr("Localizable", "nighthawk.transferTab.topUpWallet.stealthExIoTitle", fallback: "Swap with StealthEx.io")
      }
    }
    public enum WalletCreated {
      /// Backup your wallet
      public static let backup = L10n.tr("Localizable", "nighthawk.walletCreated.backup", fallback: "Backup your wallet")
      /// For the safety of your funds and to prevent unintended consequences, we STRONGLY recommend that you backup your wallet. Please remember, this is a self-custody wallet, and you are solely responsible for managing your funds.
      public static let backupImmediately = L10n.tr("Localizable", "nighthawk.walletCreated.backupImmediately", fallback: "For the safety of your funds and to prevent unintended consequences, we STRONGLY recommend that you backup your wallet. Please remember, this is a self-custody wallet, and you are solely responsible for managing your funds.")
      /// Skip for now
      public static let skip = L10n.tr("Localizable", "nighthawk.walletCreated.skip", fallback: "Skip for now")
      /// Wallet created! Congratulations!
      public static let title = L10n.tr("Localizable", "nighthawk.walletCreated.title", fallback: "Wallet created! Congratulations!")
    }
    public enum WalletTab {
      /// Recent activity
      public static let recentActivity = L10n.tr("Localizable", "nighthawk.walletTab.recentActivity", fallback: "Recent activity")
      /// Shielded balance
      public static let shieldedBalance = L10n.tr("Localizable", "nighthawk.walletTab.shieldedBalance", fallback: "Shielded balance")
      /// Shield now
      public static let shieldNow = L10n.tr("Localizable", "nighthawk.walletTab.shieldNow", fallback: "Shield now")
      /// Swipe left to show your balance
      public static let swipeToShowBalances = L10n.tr("Localizable", "nighthawk.walletTab.swipeToShowBalances", fallback: "Swipe left to show your balance")
      /// Total balance
      public static let totalBalance = L10n.tr("Localizable", "nighthawk.walletTab.totalBalance", fallback: "Total balance")
      /// Transparent balance
      public static let transparentBalance = L10n.tr("Localizable", "nighthawk.walletTab.transparentBalance", fallback: "Transparent balance")
      /// View transaction history
      public static let viewTransactionHistory = L10n.tr("Localizable", "nighthawk.walletTab.viewTransactionHistory", fallback: "View transaction history")
      /// ZEC
      public static let zec = L10n.tr("Localizable", "nighthawk.walletTab.zec", fallback: "ZEC")
      public enum Addresses {
        /// Copied to clipboard!
        public static let copiedToClipboard = L10n.tr("Localizable", "nighthawk.walletTab.addresses.copiedToClipboard", fallback: "Copied to clipboard!")
        /// Copy
        public static let copy = L10n.tr("Localizable", "nighthawk.walletTab.addresses.copy", fallback: "Copy")
        /// Loading…
        public static let loading = L10n.tr("Localizable", "nighthawk.walletTab.addresses.loading", fallback: "Loading…")
        /// Legacy shielded address
        public static let saplingAddress = L10n.tr("Localizable", "nighthawk.walletTab.addresses.saplingAddress", fallback: "Legacy shielded address")
        /// See more
        public static let seeMore = L10n.tr("Localizable", "nighthawk.walletTab.addresses.seeMore", fallback: "See more")
        /// Top up your wallet
        public static let topUpYourWallet = L10n.tr("Localizable", "nighthawk.walletTab.addresses.topUpYourWallet", fallback: "Top up your wallet")
        /// Buy or trade Zcash through our specially selected partners.
        public static let topUpYourWalletDescription = L10n.tr("Localizable", "nighthawk.walletTab.addresses.topUpYourWalletDescription", fallback: "Buy or trade Zcash through our specially selected partners.")
        /// Transparent address
        public static let transparentAddress = L10n.tr("Localizable", "nighthawk.walletTab.addresses.transparentAddress", fallback: "Transparent address")
        /// Unified address
        public static let unifiedAddress = L10n.tr("Localizable", "nighthawk.walletTab.addresses.unifiedAddress", fallback: "Unified address")
      }
    }
    public enum Welcome {
      /// If it’s your first time using Nighthawk, you’ll need to create a wallet. If you are returning to Nighthawk, you can restore your previous wallet.
      public static let body = L10n.tr("Localizable", "nighthawk.welcome.body", fallback: "If it’s your first time using Nighthawk, you’ll need to create a wallet. If you are returning to Nighthawk, you can restore your previous wallet.")
      /// Create Wallet
      public static let create = L10n.tr("Localizable", "nighthawk.welcome.create", fallback: "Create Wallet")
      /// Restore From Backup
      public static let restore = L10n.tr("Localizable", "nighthawk.welcome.restore", fallback: "Restore From Backup")
      /// Get started
      public static let subtitle = L10n.tr("Localizable", "nighthawk.welcome.subtitle", fallback: "Get started")
      /// By using this app you accept our
      public static let terms1 = L10n.tr("Localizable", "nighthawk.welcome.terms1", fallback: "By using this app you accept our")
      public enum Initialization {
        public enum Alert {
          public enum CantCreateNewWallet {
            /// Can't create new wallet. Error: %@ (code: %@)
            public static func message(_ p1: Any, _ p2: Any) -> String {
              return L10n.tr("Localizable", "nighthawk.welcome.initialization.alert.cantCreateNewWallet.message", String(describing: p1), String(describing: p2), fallback: "Can't create new wallet. Error: %@ (code: %@)")
            }
          }
          public enum Failed {
            /// Wallet initialisation failed.
            public static let title = L10n.tr("Localizable", "nighthawk.welcome.initialization.alert.failed.title", fallback: "Wallet initialisation failed.")
          }
        }
      }
    }
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg..., fallback value: String) -> String {
    let format = BundleToken.bundle.localizedString(forKey: key, value: value, table: table)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type

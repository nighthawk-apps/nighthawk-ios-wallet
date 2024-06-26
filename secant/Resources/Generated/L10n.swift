// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {
  /// %@ %@
  internal static func balance(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "balance", String(describing: p1), String(describing: p2), fallback: "%@ %@")
  }
  /// QR Code for %@
  internal static func qrCodeFor(_ p1: Any) -> String {
    return L10n.tr("Localizable", "qrCodeFor", String(describing: p1), fallback: "QR Code for %@")
  }
  internal enum AddressDetails {
    /// Sapling Address
    internal static let sa = L10n.tr("Localizable", "addressDetails.sa", fallback: "Sapling Address")
    /// Transparent Address
    internal static let ta = L10n.tr("Localizable", "addressDetails.ta", fallback: "Transparent Address")
    /// Unified Address
    internal static let ua = L10n.tr("Localizable", "addressDetails.ua", fallback: "Unified Address")
    internal enum Error {
      /// could not extract sapling receiver from UA
      internal static let cantExtractSaplingAddress = L10n.tr("Localizable", "addressDetails.error.cantExtractSaplingAddress", fallback: "could not extract sapling receiver from UA")
      /// could not extract transparent receiver from UA
      internal static let cantExtractTransparentAddress = L10n.tr("Localizable", "addressDetails.error.cantExtractTransparentAddress", fallback: "could not extract transparent receiver from UA")
      /// could not extract UA
      internal static let cantExtractUnifiedAddress = L10n.tr("Localizable", "addressDetails.error.cantExtractUnifiedAddress", fallback: "could not extract UA")
    }
  }
  internal enum Balance {
    /// %@ %@ Available
    internal static func available(_ p1: Any, _ p2: Any) -> String {
      return L10n.tr("Localizable", "balance.available", String(describing: p1), String(describing: p2), fallback: "%@ %@ Available")
    }
  }
  internal enum BalanceBreakdown {
    /// Shielding Threshold: %@ %@
    internal static func autoShieldingThreshold(_ p1: Any, _ p2: Any) -> String {
      return L10n.tr("Localizable", "balanceBreakdown.autoShieldingThreshold", String(describing: p1), String(describing: p2), fallback: "Shielding Threshold: %@ %@")
    }
    /// Block: %@
    internal static func blockId(_ p1: Any) -> String {
      return L10n.tr("Localizable", "balanceBreakdown.blockId", String(describing: p1), fallback: "Block: %@")
    }
    /// SHIELDED %@ (SPENDABLE)
    internal static func shieldedZec(_ p1: Any) -> String {
      return L10n.tr("Localizable", "balanceBreakdown.shieldedZec", String(describing: p1), fallback: "SHIELDED %@ (SPENDABLE)")
    }
    /// Shield funds
    internal static let shieldFunds = L10n.tr("Localizable", "balanceBreakdown.shieldFunds", fallback: "Shield funds")
    /// Shielding funds
    internal static let shieldingFunds = L10n.tr("Localizable", "balanceBreakdown.shieldingFunds", fallback: "Shielding funds")
    /// TOTAL BALANCE
    internal static let totalSpendableBalance = L10n.tr("Localizable", "balanceBreakdown.totalSpendableBalance", fallback: "TOTAL BALANCE")
    /// TRANSPARENT BALANCE
    internal static let transparentBalance = L10n.tr("Localizable", "balanceBreakdown.transparentBalance", fallback: "TRANSPARENT BALANCE")
    internal enum Alert {
      internal enum ShieldFunds {
        internal enum Failure {
          /// Error: %@ (code: %@)
          internal static func message(_ p1: Any, _ p2: Any) -> String {
            return L10n.tr("Localizable", "balanceBreakdown.alert.shieldFunds.failure.message", String(describing: p1), String(describing: p2), fallback: "Error: %@ (code: %@)")
          }
          /// Failed to shield funds
          internal static let title = L10n.tr("Localizable", "balanceBreakdown.alert.shieldFunds.failure.title", fallback: "Failed to shield funds")
        }
        internal enum Success {
          /// Shielding transaction created
          internal static let message = L10n.tr("Localizable", "balanceBreakdown.alert.shieldFunds.success.message", fallback: "Shielding transaction created")
          /// Done
          internal static let title = L10n.tr("Localizable", "balanceBreakdown.alert.shieldFunds.success.title", fallback: "Done")
        }
      }
    }
  }
  internal enum Error {
    /// possible roll back
    internal static let rollBack = L10n.tr("Localizable", "error.rollBack", fallback: "possible roll back")
  }
  internal enum ExportLogs {
    internal enum Alert {
      internal enum Failed {
        /// Error: %@ (code: %@)
        internal static func message(_ p1: Any, _ p2: Any) -> String {
          return L10n.tr("Localizable", "exportLogs.alert.failed.message", String(describing: p1), String(describing: p2), fallback: "Error: %@ (code: %@)")
        }
        /// Error when exporting logs
        internal static let title = L10n.tr("Localizable", "exportLogs.alert.failed.title", fallback: "Error when exporting logs")
      }
    }
  }
  internal enum Field {
    internal enum Multiline {
      /// char limit exceeded
      internal static let charLimitExceeded = L10n.tr("Localizable", "field.multiline.charLimitExceeded", fallback: "char limit exceeded")
    }
    internal enum TransactionAddress {
      /// To:
      internal static let to = L10n.tr("Localizable", "field.transactionAddress.to", fallback: "To:")
      /// Valid Zcash Address
      internal static let validZcashAddress = L10n.tr("Localizable", "field.transactionAddress.validZcashAddress", fallback: "Valid Zcash Address")
    }
    internal enum TransactionAmount {
      /// Amount:
      internal static let amount = L10n.tr("Localizable", "field.transactionAmount.amount", fallback: "Amount:")
      /// %@ Amount
      internal static func zecAmount(_ p1: Any) -> String {
        return L10n.tr("Localizable", "field.transactionAmount.zecAmount", String(describing: p1), fallback: "%@ Amount")
      }
    }
  }
  internal enum General {
    /// Back
    internal static let back = L10n.tr("Localizable", "general.back", fallback: "Back")
    /// Cancel
    internal static let cancel = L10n.tr("Localizable", "general.cancel", fallback: "Cancel")
    /// Clear
    internal static let clear = L10n.tr("Localizable", "general.clear", fallback: "Clear")
    /// Close
    internal static let close = L10n.tr("Localizable", "general.close", fallback: "Close")
    /// date not available
    internal static let dateNotAvailable = L10n.tr("Localizable", "general.dateNotAvailable", fallback: "date not available")
    /// Max
    internal static let max = L10n.tr("Localizable", "general.max", fallback: "Max")
    /// Next
    internal static let next = L10n.tr("Localizable", "general.next", fallback: "Next")
    /// No
    internal static let no = L10n.tr("Localizable", "general.no", fallback: "No")
    /// Ok
    internal static let ok = L10n.tr("Localizable", "general.ok", fallback: "Ok")
    /// Send
    internal static let send = L10n.tr("Localizable", "general.send", fallback: "Send")
    /// Skip
    internal static let skip = L10n.tr("Localizable", "general.skip", fallback: "Skip")
    /// Success
    internal static let success = L10n.tr("Localizable", "general.success", fallback: "Success")
    /// Unknown
    internal static let unknown = L10n.tr("Localizable", "general.unknown", fallback: "Unknown")
    /// Yes
    internal static let yes = L10n.tr("Localizable", "general.yes", fallback: "Yes")
  }
  internal enum Home {
    /// Receive %@
    internal static func receiveZec(_ p1: Any) -> String {
      return L10n.tr("Localizable", "home.receiveZec", String(describing: p1), fallback: "Receive %@")
    }
    /// Send %@
    internal static func sendZec(_ p1: Any) -> String {
      return L10n.tr("Localizable", "home.sendZec", String(describing: p1), fallback: "Send %@")
    }
    /// Secant Wallet
    internal static let title = L10n.tr("Localizable", "home.title", fallback: "Secant Wallet")
    /// See transaction history
    internal static let transactionHistory = L10n.tr("Localizable", "home.transactionHistory", fallback: "See transaction history")
    internal enum SyncFailed {
      /// Dismiss
      internal static let dismiss = L10n.tr("Localizable", "home.syncFailed.dismiss", fallback: "Dismiss")
      /// Retry
      internal static let retry = L10n.tr("Localizable", "home.syncFailed.retry", fallback: "Retry")
      /// Sync failed!
      internal static let title = L10n.tr("Localizable", "home.syncFailed.title", fallback: "Sync failed!")
    }
  }
  internal enum ImportWallet {
    /// Enter your secret backup seed phrase.
    internal static let description = L10n.tr("Localizable", "importWallet.description", fallback: "Enter your secret backup seed phrase.")
    /// Wallet Import
    internal static let title = L10n.tr("Localizable", "importWallet.title", fallback: "Wallet Import")
    internal enum Alert {
      internal enum Failed {
        /// Error: %@ (code: %@)
        internal static func message(_ p1: Any, _ p2: Any) -> String {
          return L10n.tr("Localizable", "importWallet.alert.failed.message", String(describing: p1), String(describing: p2), fallback: "Error: %@ (code: %@)")
        }
        /// Failed to restore wallet
        internal static let title = L10n.tr("Localizable", "importWallet.alert.failed.title", fallback: "Failed to restore wallet")
      }
      internal enum Success {
        /// The wallet has been successfully recovered.
        internal static let message = L10n.tr("Localizable", "importWallet.alert.success.message", fallback: "The wallet has been successfully recovered.")
        /// Success
        internal static let title = L10n.tr("Localizable", "importWallet.alert.success.title", fallback: "Success")
      }
    }
    internal enum Birthday {
      /// Do you know the wallet's creation date? This will allow a faster sync. If you don't know the wallet's birthday, don't worry!
      internal static let description = L10n.tr("Localizable", "importWallet.birthday.description", fallback: "Do you know the wallet's creation date? This will allow a faster sync. If you don't know the wallet's birthday, don't worry!")
      /// Enter birthday height
      internal static let placeholder = L10n.tr("Localizable", "importWallet.birthday.placeholder", fallback: "Enter birthday height")
    }
    internal enum Button {
      /// Import a private or viewing key
      internal static let importPrivateKey = L10n.tr("Localizable", "importWallet.button.importPrivateKey", fallback: "Import a private or viewing key")
      /// Restore wallet
      internal static let restoreWallet = L10n.tr("Localizable", "importWallet.button.restoreWallet", fallback: "Restore wallet")
    }
    internal enum Seed {
      /// VALID SEED PHRASE
      internal static let valid = L10n.tr("Localizable", "importWallet.seed.valid", fallback: "VALID SEED PHRASE")
    }
  }
  internal enum LocalAuthentication {
    /// The Following content requires authentication.
    internal static let reason = L10n.tr("Localizable", "localAuthentication.reason", fallback: "The Following content requires authentication.")
  }
  internal enum Nefs {
    /// Not enough space on disk to do synchronisation!
    internal static let message = L10n.tr("Localizable", "nefs.message", fallback: "Not enough space on disk to do synchronisation!")
  }
  internal enum Nighthawk {
    internal enum HomeScreen {
      /// Settings
      internal static let settings = L10n.tr("Localizable", "nighthawk.homeScreen.settings", fallback: "Settings")
      /// Transfer
      internal static let transfer = L10n.tr("Localizable", "nighthawk.homeScreen.transfer", fallback: "Transfer")
      /// Wallet
      internal static let wallet = L10n.tr("Localizable", "nighthawk.homeScreen.wallet", fallback: "Wallet")
    }
    internal enum ImportWallet {
      /// Birthday Height (optional)
      internal static let birthdayHeight = L10n.tr("Localizable", "nighthawk.importWallet.birthdayHeight", fallback: "Birthday Height (optional)")
      /// Continue
      internal static let `continue` = L10n.tr("Localizable", "nighthawk.importWallet.continue", fallback: "Continue")
      /// Enter your 24 word seed phrase below. If you do not have this phrase, you will need to create a new wallet.
      internal static let enterSeedPhrase = L10n.tr("Localizable", "nighthawk.importWallet.enterSeedPhrase", fallback: "Enter your 24 word seed phrase below. If you do not have this phrase, you will need to create a new wallet.")
      /// Error ⸱ This doesn't look like a valid birthday height
      internal static let invalidBirthday = L10n.tr("Localizable", "nighthawk.importWallet.invalidBirthday", fallback: "Error ⸱ This doesn't look like a valid birthday height")
      /// Error ⸱ This doesn't look like a valid seed phrase
      internal static let invalidMnemonic = L10n.tr("Localizable", "nighthawk.importWallet.invalidMnemonic", fallback: "Error ⸱ This doesn't look like a valid seed phrase")
      /// Restore from backup
      internal static let restoreFromBackup = L10n.tr("Localizable", "nighthawk.importWallet.restoreFromBackup", fallback: "Restore from backup")
      /// Your seed phrase
      internal static let yourSeedPhrase = L10n.tr("Localizable", "nighthawk.importWallet.yourSeedPhrase", fallback: "Your seed phrase")
    }
    internal enum ImportWalletSuccess {
      /// Success
      internal static let success = L10n.tr("Localizable", "nighthawk.importWalletSuccess.success", fallback: "Success")
      /// View wallet
      internal static let viewWallet = L10n.tr("Localizable", "nighthawk.importWalletSuccess.viewWallet", fallback: "View wallet")
    }
    internal enum PlainOnboarding {
      /// If it’s your first time using Nighthawk, you’ll need to create a wallet. If you are returning to Nighthawk, you can restore your previous wallet.
      internal static let body = L10n.tr("Localizable", "nighthawk.plainOnboarding.body", fallback: "If it’s your first time using Nighthawk, you’ll need to create a wallet. If you are returning to Nighthawk, you can restore your previous wallet.")
      /// Create Wallet
      internal static let create = L10n.tr("Localizable", "nighthawk.plainOnboarding.create", fallback: "Create Wallet")
      /// Restore From Backup
      internal static let restore = L10n.tr("Localizable", "nighthawk.plainOnboarding.restore", fallback: "Restore From Backup")
      /// Get started
      internal static let subtitle = L10n.tr("Localizable", "nighthawk.plainOnboarding.subtitle", fallback: "Get started")
      /// By using this app you accept our
      internal static let terms1 = L10n.tr("Localizable", "nighthawk.plainOnboarding.terms1", fallback: "By using this app you accept our")
      /// Terms and Conditions
      internal static let terms2 = L10n.tr("Localizable", "nighthawk.plainOnboarding.terms2", fallback: "Terms and Conditions")
    }
    internal enum RecoveryPhraseDisplay {
      /// Wallet birthday:
      internal static let birthday = L10n.tr("Localizable", "nighthawk.recoveryPhraseDisplay.birthday", fallback: "Wallet birthday:")
      /// I confirm I have saved my seed phrase.
      internal static let confirmPhraseWrittenDownCheckBox = L10n.tr("Localizable", "nighthawk.recoveryPhraseDisplay.confirmPhraseWrittenDownCheckBox", fallback: "I confirm I have saved my seed phrase.")
      /// Continue
      internal static let `continue` = L10n.tr("Localizable", "nighthawk.recoveryPhraseDisplay.continue", fallback: "Continue")
      /// Nighthawk Wallet
      internal static let exportAppName = L10n.tr("Localizable", "nighthawk.recoveryPhraseDisplay.exportAppName", fallback: "Nighthawk Wallet")
      /// Export as PDF
      internal static let exportAsPdf = L10n.tr("Localizable", "nighthawk.recoveryPhraseDisplay.exportAsPdf", fallback: "Export as PDF")
      /// If you lose access to your phone or Nighthawk wallet, the only way you can regain access to your Zcash is if you have this 24 word phrase and wallet birthday code.
      internal static let instructions1 = L10n.tr("Localizable", "nighthawk.recoveryPhraseDisplay.instructions1", fallback: "If you lose access to your phone or Nighthawk wallet, the only way you can regain access to your Zcash is if you have this 24 word phrase and wallet birthday code.")
      /// Write it down on paper and store it somewhere safe.
      internal static let instructions2 = L10n.tr("Localizable", "nighthawk.recoveryPhraseDisplay.instructions2", fallback: "Write it down on paper and store it somewhere safe.")
      /// These are seed words used to restore your Zcash in Nighthawk Wallet:
      internal static let pdfHeader = L10n.tr("Localizable", "nighthawk.recoveryPhraseDisplay.pdfHeader", fallback: "These are seed words used to restore your Zcash in Nighthawk Wallet:")
      /// Backup PDF generated at %@
      internal static func pdfTimestamp(_ p1: Any) -> String {
        return L10n.tr("Localizable", "nighthawk.recoveryPhraseDisplay.pdfTimestamp", String(describing: p1), fallback: "Backup PDF generated at %@")
      }
      /// Write down your backup seed
      internal static let title = L10n.tr("Localizable", "nighthawk.recoveryPhraseDisplay.title", fallback: "Write down your backup seed")
    }
    internal enum SettingsTab {
      /// Nighthawk v%@ & Licenses
      internal static func aboutSubtitle(_ p1: Any) -> String {
        return L10n.tr("Localizable", "nighthawk.settingsTab.aboutSubtitle", String(describing: p1), fallback: "Nighthawk v%@ & Licenses")
      }
      /// About
      internal static let aboutTitle = L10n.tr("Localizable", "nighthawk.settingsTab.aboutTitle", fallback: "About")
      /// Keep your wallet safe in case you lose your phone
      internal static let backupSubtitle = L10n.tr("Localizable", "nighthawk.settingsTab.backupSubtitle", fallback: "Keep your wallet safe in case you lose your phone")
      /// Backup your wallet
      internal static let backupTitle = L10n.tr("Localizable", "nighthawk.settingsTab.backupTitle", fallback: "Backup your wallet")
      /// Change backend lightwalletd server
      internal static let changeServerSubtitle = L10n.tr("Localizable", "nighthawk.settingsTab.changeServerSubtitle", fallback: "Change backend lightwalletd server")
      /// Change server
      internal static let changeServerTitle = L10n.tr("Localizable", "nighthawk.settingsTab.changeServerTitle", fallback: "Change server")
      /// Opt-in to our partner services
      internal static let externalServicesSubtitle = L10n.tr("Localizable", "nighthawk.settingsTab.externalServicesSubtitle", fallback: "Opt-in to our partner services")
      /// External services
      internal static let externalServicesTitle = L10n.tr("Localizable", "nighthawk.settingsTab.externalServicesTitle", fallback: "External services")
      /// Choose your local currency
      internal static let fiatSubtitle = L10n.tr("Localizable", "nighthawk.settingsTab.fiatSubtitle", fallback: "Choose your local currency")
      /// Fiat Currency
      internal static let fiatTitle = L10n.tr("Localizable", "nighthawk.settingsTab.fiatTitle", fallback: "Fiat Currency")
      /// Reminding you to keep the wallet up-to-date
      internal static let notificationsSubtitle = L10n.tr("Localizable", "nighthawk.settingsTab.notificationsSubtitle", fallback: "Reminding you to keep the wallet up-to-date")
      /// Sync notifications
      internal static let notificationsTitle = L10n.tr("Localizable", "nighthawk.settingsTab.notificationsTitle", fallback: "Sync notifications")
      /// Rescan wallet balances to troubleshoot issues
      internal static let rescanSubtitle = L10n.tr("Localizable", "nighthawk.settingsTab.rescanSubtitle", fallback: "Rescan wallet balances to troubleshoot issues")
      /// Rescan wallet
      internal static let rescanTitle = L10n.tr("Localizable", "nighthawk.settingsTab.rescanTitle", fallback: "Rescan wallet")
      /// Set/Change Pin Code & Biometric
      internal static let securitySubtitle = L10n.tr("Localizable", "nighthawk.settingsTab.securitySubtitle", fallback: "Set/Change Pin Code & Biometric")
      /// Security
      internal static let securityTitle = L10n.tr("Localizable", "nighthawk.settingsTab.securityTitle", fallback: "Security")
      /// Settings
      internal static let settings = L10n.tr("Localizable", "nighthawk.settingsTab.settings", fallback: "Settings")
    }
    internal enum Sync {
      internal enum Message {
        /// Reconnecting…
        internal static let disconnected = L10n.tr("Localizable", "nighthawk.sync.message.disconnected", fallback: "Reconnecting…")
        /// Enhancing…
        internal static let enhancing = L10n.tr("Localizable", "nighthawk.sync.message.enhancing", fallback: "Enhancing…")
        /// Error: %@
        internal static func error(_ p1: Any) -> String {
          return L10n.tr("Localizable", "nighthawk.sync.message.error", String(describing: p1), fallback: "Error: %@")
        }
        /// Fetching UTXOs…
        internal static let fetchingUTXO = L10n.tr("Localizable", "nighthawk.sync.message.fetchingUTXO", fallback: "Fetching UTXOs…")
        /// Finalizing
        internal static let finalizing = L10n.tr("Localizable", "nighthawk.sync.message.finalizing", fallback: "Finalizing")
        /// Preparing to scan
        internal static let preparing = L10n.tr("Localizable", "nighthawk.sync.message.preparing", fallback: "Preparing to scan")
        /// Stopped
        internal static let stopped = L10n.tr("Localizable", "nighthawk.sync.message.stopped", fallback: "Stopped")
        /// Scanning…%@%%
        internal static func sync(_ p1: Any) -> String {
          return L10n.tr("Localizable", "nighthawk.sync.message.sync", String(describing: p1), fallback: "Scanning…%@%%")
        }
        /// Connecting…
        internal static let unprepared = L10n.tr("Localizable", "nighthawk.sync.message.unprepared", fallback: "Connecting…")
        /// Up-To-Date
        internal static let uptodate = L10n.tr("Localizable", "nighthawk.sync.message.uptodate", fallback: "Up-To-Date")
      }
    }
    internal enum TransactionHistory {
      /// %@ %@
      internal static func zecAmount(_ p1: Any, _ p2: Any) -> String {
        return L10n.tr("Localizable", "nighthawk.transactionHistory.zecAmount", String(describing: p1), String(describing: p2), fallback: "%@ %@")
      }
    }
    internal enum WalletCreated {
      /// Backup your wallet
      internal static let backup = L10n.tr("Localizable", "nighthawk.walletCreated.backup", fallback: "Backup your wallet")
      /// Skip for now
      internal static let skip = L10n.tr("Localizable", "nighthawk.walletCreated.skip", fallback: "Skip for now")
      /// Wallet created! Congratulations!
      internal static let title = L10n.tr("Localizable", "nighthawk.walletCreated.title", fallback: "Wallet created! Congratulations!")
    }
    internal enum WalletTab {
      /// Recent activity
      internal static let recentActivity = L10n.tr("Localizable", "nighthawk.walletTab.recentActivity", fallback: "Recent activity")
      /// Shielded balance
      internal static let shieldedBalance = L10n.tr("Localizable", "nighthawk.walletTab.shieldedBalance", fallback: "Shielded balance")
      /// Swipe left to show your balance
      internal static let swipeToShowBalances = L10n.tr("Localizable", "nighthawk.walletTab.swipeToShowBalances", fallback: "Swipe left to show your balance")
      /// Total balance
      internal static let totalBalance = L10n.tr("Localizable", "nighthawk.walletTab.totalBalance", fallback: "Total balance")
      /// Transparent balance
      internal static let transparentBalance = L10n.tr("Localizable", "nighthawk.walletTab.transparentBalance", fallback: "Transparent balance")
      /// View transaction history
      internal static let viewTransactionHistory = L10n.tr("Localizable", "nighthawk.walletTab.viewTransactionHistory", fallback: "View transaction history")
      /// ZEC
      internal static let zec = L10n.tr("Localizable", "nighthawk.walletTab.zec", fallback: "ZEC")
    }
    internal enum WelcomeScreen {
      /// Private money in your pocket.
      internal static let subtitle = L10n.tr("Localizable", "nighthawk.welcomeScreen.subtitle", fallback: "Private money in your pocket.")
      /// Nighthawk
      internal static let title = L10n.tr("Localizable", "nighthawk.welcomeScreen.title", fallback: "Nighthawk")
    }
  }
  internal enum Onboarding {
    internal enum Button {
      /// Import an Existing Wallet
      internal static let importWallet = L10n.tr("Localizable", "onboarding.button.importWallet", fallback: "Import an Existing Wallet")
      /// Create New Wallet
      internal static let newWallet = L10n.tr("Localizable", "onboarding.button.newWallet", fallback: "Create New Wallet")
    }
    internal enum Step1 {
      /// As a privacy focused wallet, we shield by default. Your wallet uses the shielded address for sending and moves transparent funds to that address automatically.
      /// 
      /// In other words, the 'privacy-please' sign is on the knob.
      internal static let description = L10n.tr("Localizable", "onboarding.step1.description", fallback: "As a privacy focused wallet, we shield by default. Your wallet uses the shielded address for sending and moves transparent funds to that address automatically.\n\nIn other words, the 'privacy-please' sign is on the knob.")
      /// Welcome!
      internal static let title = L10n.tr("Localizable", "onboarding.step1.title", fallback: "Welcome!")
    }
    internal enum Step2 {
      /// You now have a unified address that includes and up-to-date shielded address for legacy systems.
      /// 
      /// This makes your wallet friendlier, and gives you and address that you won't have to upgrade again.
      internal static let description = L10n.tr("Localizable", "onboarding.step2.description", fallback: "You now have a unified address that includes and up-to-date shielded address for legacy systems.\n\nThis makes your wallet friendlier, and gives you and address that you won't have to upgrade again.")
      /// Unified Addresses
      internal static let title = L10n.tr("Localizable", "onboarding.step2.title", fallback: "Unified Addresses")
    }
    internal enum Step3 {
      /// Due to Zcash's increased popularity, we are optimizing our syncing schemes to be faster and more efficient!
      /// 
      /// The future is fast!
      internal static let description = L10n.tr("Localizable", "onboarding.step3.description", fallback: "Due to Zcash's increased popularity, we are optimizing our syncing schemes to be faster and more efficient!\n\nThe future is fast!")
      /// And so much more...
      internal static let title = L10n.tr("Localizable", "onboarding.step3.title", fallback: "And so much more...")
    }
    internal enum Step4 {
      /// Choose between creating a new wallet and importing and existing Secret Recovery Phrase
      internal static let description = L10n.tr("Localizable", "onboarding.step4.description", fallback: "Choose between creating a new wallet and importing and existing Secret Recovery Phrase")
      /// Let's get started
      internal static let title = L10n.tr("Localizable", "onboarding.step4.title", fallback: "Let's get started")
    }
  }
  internal enum PlainOnboarding {
    /// We need to create a new wallet or restore an existing one. Select your path:
    internal static let caption = L10n.tr("Localizable", "plainOnboarding.caption", fallback: "We need to create a new wallet or restore an existing one. Select your path:")
    /// It's time to setup your Secant, powered by Zcash, no-frills wallet.
    internal static let title = L10n.tr("Localizable", "plainOnboarding.title", fallback: "It's time to setup your Secant, powered by Zcash, no-frills wallet.")
    internal enum Button {
      /// Create a new Wallet
      internal static let createNewWallet = L10n.tr("Localizable", "plainOnboarding.button.createNewWallet", fallback: "Create a new Wallet")
      /// Restore an existing wallet
      internal static let restoreWallet = L10n.tr("Localizable", "plainOnboarding.button.restoreWallet", fallback: "Restore an existing wallet")
    }
  }
  internal enum ReceiveZec {
    /// Your Address
    internal static let yourAddress = L10n.tr("Localizable", "receiveZec.yourAddress", fallback: "Your Address")
    internal enum Error {
      /// could not extract UA
      internal static let cantExtractUnifiedAddress = L10n.tr("Localizable", "receiveZec.error.cantExtractUnifiedAddress", fallback: "could not extract UA")
    }
  }
  internal enum RecoveryPhraseBackupValidation {
    /// Drag the words below to match your backed-up copy.
    internal static let description = L10n.tr("Localizable", "recoveryPhraseBackupValidation.description", fallback: "Drag the words below to match your backed-up copy.")
    /// Your placed words did not match your secret recovery phrase
    internal static let failedResult = L10n.tr("Localizable", "recoveryPhraseBackupValidation.failedResult", fallback: "Your placed words did not match your secret recovery phrase")
    /// Congratulations! You validated your secret recovery phrase.
    internal static let successResult = L10n.tr("Localizable", "recoveryPhraseBackupValidation.successResult", fallback: "Congratulations! You validated your secret recovery phrase.")
    /// Verify Your Backup
    internal static let title = L10n.tr("Localizable", "recoveryPhraseBackupValidation.title", fallback: "Verify Your Backup")
  }
  internal enum RecoveryPhraseDisplay {
    /// The following 24 words represent your funds and the security used to protect them. Back them up now!
    internal static let description = L10n.tr("Localizable", "recoveryPhraseDisplay.description", fallback: "The following 24 words represent your funds and the security used to protect them. Back them up now!")
    /// Oops no words
    internal static let noWords = L10n.tr("Localizable", "recoveryPhraseDisplay.noWords", fallback: "Oops no words")
    /// Your Secret Recovery Phrase
    internal static let title = L10n.tr("Localizable", "recoveryPhraseDisplay.title", fallback: "Your Secret Recovery Phrase")
    internal enum Button {
      /// Copy To Buffer
      internal static let copyToBuffer = L10n.tr("Localizable", "recoveryPhraseDisplay.button.copyToBuffer", fallback: "Copy To Buffer")
      /// I wrote it down!
      internal static let wroteItDown = L10n.tr("Localizable", "recoveryPhraseDisplay.button.wroteItDown", fallback: "I wrote it down!")
    }
  }
  internal enum RecoveryPhraseTestPreamble {
    /// It is important to understand that you are in charge here. Great, right? YOU get to be the bank!
    internal static let paragraph1 = L10n.tr("Localizable", "recoveryPhraseTestPreamble.paragraph1", fallback: "It is important to understand that you are in charge here. Great, right? YOU get to be the bank!")
    /// But it also means that YOU are the customer, and you need to be self-reliant.
    internal static let paragraph2 = L10n.tr("Localizable", "recoveryPhraseTestPreamble.paragraph2", fallback: "But it also means that YOU are the customer, and you need to be self-reliant.")
    /// So how do you recover funds that you've hidden on a completely decentralized and private block-chain?
    internal static let paragraph3 = L10n.tr("Localizable", "recoveryPhraseTestPreamble.paragraph3", fallback: "So how do you recover funds that you've hidden on a completely decentralized and private block-chain?")
    /// First things first
    internal static let title = L10n.tr("Localizable", "recoveryPhraseTestPreamble.title", fallback: "First things first")
    internal enum Button {
      /// By understanding and preparing
      internal static let goNext = L10n.tr("Localizable", "recoveryPhraseTestPreamble.button.goNext", fallback: "By understanding and preparing")
    }
  }
  internal enum Root {
    internal enum Debug {
      /// Feature flags
      internal static let featureFlags = L10n.tr("Localizable", "root.debug.featureFlags", fallback: "Feature flags")
      /// Startup
      internal static let navigationTitle = L10n.tr("Localizable", "root.debug.navigationTitle", fallback: "Startup")
      /// Debug options
      internal static let title = L10n.tr("Localizable", "root.debug.title", fallback: "Debug options")
      internal enum Alert {
        internal enum Rewind {
          internal enum CantStartSync {
            /// Error: %@ (code: %@)
            internal static func message(_ p1: Any, _ p2: Any) -> String {
              return L10n.tr("Localizable", "root.debug.alert.rewind.cantStartSync.message", String(describing: p1), String(describing: p2), fallback: "Error: %@ (code: %@)")
            }
            /// Can't start sync process after rewind
            internal static let title = L10n.tr("Localizable", "root.debug.alert.rewind.cantStartSync.title", fallback: "Can't start sync process after rewind")
          }
          internal enum Failed {
            /// Error: %@ (code: %@)
            internal static func message(_ p1: Any, _ p2: Any) -> String {
              return L10n.tr("Localizable", "root.debug.alert.rewind.failed.message", String(describing: p1), String(describing: p2), fallback: "Error: %@ (code: %@)")
            }
            /// Rewind failed
            internal static let title = L10n.tr("Localizable", "root.debug.alert.rewind.failed.title", fallback: "Rewind failed")
          }
        }
      }
      internal enum Dialog {
        internal enum Rescan {
          /// Select the rescan you want
          internal static let message = L10n.tr("Localizable", "root.debug.dialog.rescan.message", fallback: "Select the rescan you want")
          /// Rescan
          internal static let title = L10n.tr("Localizable", "root.debug.dialog.rescan.title", fallback: "Rescan")
          internal enum Option {
            /// Full rescan
            internal static let full = L10n.tr("Localizable", "root.debug.dialog.rescan.option.full", fallback: "Full rescan")
            /// Quick rescan
            internal static let quick = L10n.tr("Localizable", "root.debug.dialog.rescan.option.quick", fallback: "Quick rescan")
          }
        }
      }
      internal enum Option {
        /// Rate the app
        internal static let appReview = L10n.tr("Localizable", "root.debug.option.appReview", fallback: "Rate the app")
        /// Export logs
        internal static let exportLogs = L10n.tr("Localizable", "root.debug.option.exportLogs", fallback: "Export logs")
        /// Go To Onboarding
        internal static let gotoOnboarding = L10n.tr("Localizable", "root.debug.option.gotoOnboarding", fallback: "Go To Onboarding")
        /// Go To Phrase Validation Demo
        internal static let gotoPhraseValidationDemo = L10n.tr("Localizable", "root.debug.option.gotoPhraseValidationDemo", fallback: "Go To Phrase Validation Demo")
        /// Go To Sandbox (navigation proof)
        internal static let gotoSandbox = L10n.tr("Localizable", "root.debug.option.gotoSandbox", fallback: "Go To Sandbox (navigation proof)")
        /// [Be careful] Nuke Wallet
        internal static let nukeWallet = L10n.tr("Localizable", "root.debug.option.nukeWallet", fallback: "[Be careful] Nuke Wallet")
        /// Rescan Blockchain
        internal static let rescanBlockchain = L10n.tr("Localizable", "root.debug.option.rescanBlockchain", fallback: "Rescan Blockchain")
        /// Restart the app
        internal static let restartApp = L10n.tr("Localizable", "root.debug.option.restartApp", fallback: "Restart the app")
        /// Test Crash Reporter
        internal static let testCrashReporter = L10n.tr("Localizable", "root.debug.option.testCrashReporter", fallback: "Test Crash Reporter")
      }
    }
    internal enum Destination {
      internal enum Alert {
        internal enum FailedToProcessDeeplink {
          /// Deeplink: (%@))
          /// Error: (%@) (code: %@)
          internal static func message(_ p1: Any, _ p2: Any, _ p3: Any) -> String {
            return L10n.tr("Localizable", "root.destination.alert.failedToProcessDeeplink.message", String(describing: p1), String(describing: p2), String(describing: p3), fallback: "Deeplink: (%@))\nError: (%@) (code: %@)")
          }
          /// Failed to process deeplink.
          internal static let title = L10n.tr("Localizable", "root.destination.alert.failedToProcessDeeplink.title", fallback: "Failed to process deeplink.")
        }
      }
    }
    internal enum Initialization {
      internal enum Alert {
        internal enum CantCreateNewWallet {
          /// Can't create new wallet. Error: %@ (code: %@)
          internal static func message(_ p1: Any, _ p2: Any) -> String {
            return L10n.tr("Localizable", "root.initialization.alert.cantCreateNewWallet.message", String(describing: p1), String(describing: p2), fallback: "Can't create new wallet. Error: %@ (code: %@)")
          }
        }
        internal enum CantLoadSeedPhrase {
          /// Can't load seed phrase from local storage.
          internal static let message = L10n.tr("Localizable", "root.initialization.alert.cantLoadSeedPhrase.message", fallback: "Can't load seed phrase from local storage.")
        }
        internal enum CantStoreThatUserPassedPhraseBackupTest {
          /// Can't store information that user passed phrase backup test. Error: %@ (code: %@)
          internal static func message(_ p1: Any, _ p2: Any) -> String {
            return L10n.tr("Localizable", "root.initialization.alert.cantStoreThatUserPassedPhraseBackupTest.message", String(describing: p1), String(describing: p2), fallback: "Can't store information that user passed phrase backup test. Error: %@ (code: %@)")
          }
        }
        internal enum Error {
          /// Error: %@ (code: %@)
          internal static func message(_ p1: Any, _ p2: Any) -> String {
            return L10n.tr("Localizable", "root.initialization.alert.error.message", String(describing: p1), String(describing: p2), fallback: "Error: %@ (code: %@)")
          }
        }
        internal enum Failed {
          /// Wallet initialisation failed.
          internal static let title = L10n.tr("Localizable", "root.initialization.alert.failed.title", fallback: "Wallet initialisation failed.")
        }
        internal enum SdkInitFailed {
          /// Failed to initialize the SDK
          internal static let title = L10n.tr("Localizable", "root.initialization.alert.sdkInitFailed.title", fallback: "Failed to initialize the SDK")
        }
        internal enum WalletStateFailed {
          /// App initialisation state: %@.
          internal static func message(_ p1: Any) -> String {
            return L10n.tr("Localizable", "root.initialization.alert.walletStateFailed.message", String(describing: p1), fallback: "App initialisation state: %@.")
          }
        }
        internal enum Wipe {
          /// Are you sure?
          internal static let message = L10n.tr("Localizable", "root.initialization.alert.wipe.message", fallback: "Are you sure?")
          /// Wipe of the wallet
          internal static let title = L10n.tr("Localizable", "root.initialization.alert.wipe.title", fallback: "Wipe of the wallet")
        }
        internal enum WipeFailed {
          /// Nuke of the wallet failed
          internal static let title = L10n.tr("Localizable", "root.initialization.alert.wipeFailed.title", fallback: "Nuke of the wallet failed")
        }
      }
    }
  }
  internal enum Scan {
    /// We will validate any Zcash URI and take you to the appropriate action.
    internal static let info = L10n.tr("Localizable", "scan.info", fallback: "We will validate any Zcash URI and take you to the appropriate action.")
    /// Scanning...
    internal static let scanning = L10n.tr("Localizable", "scan.scanning", fallback: "Scanning...")
    internal enum Alert {
      internal enum CantInitializeCamera {
        /// Error: %@ (code: %@)
        internal static func message(_ p1: Any, _ p2: Any) -> String {
          return L10n.tr("Localizable", "scan.alert.cantInitializeCamera.message", String(describing: p1), String(describing: p2), fallback: "Error: %@ (code: %@)")
        }
        /// Can't initialize the camera
        internal static let title = L10n.tr("Localizable", "scan.alert.cantInitializeCamera.title", fallback: "Can't initialize the camera")
      }
    }
  }
  internal enum Send {
    ///  address: %@
    internal static func address(_ p1: Any) -> String {
      return L10n.tr("Localizable", "send.address", String(describing: p1), fallback: " address: %@")
    }
    /// amount: %@
    internal static func amount(_ p1: Any) -> String {
      return L10n.tr("Localizable", "send.amount", String(describing: p1), fallback: "amount: %@")
    }
    /// Memo included. Tap to edit.
    internal static let editMemo = L10n.tr("Localizable", "send.editMemo", fallback: "Memo included. Tap to edit.")
    /// Sending transaction failed
    internal static let failed = L10n.tr("Localizable", "send.failed", fallback: "Sending transaction failed")
    /// Aditional funds may be in transit
    internal static let fundsInfo = L10n.tr("Localizable", "send.fundsInfo", fallback: "Aditional funds may be in transit")
    /// Want to include memo? Tap here.
    internal static let includeMemo = L10n.tr("Localizable", "send.includeMemo", fallback: "Want to include memo? Tap here.")
    ///  memo: %@
    internal static func memo(_ p1: Any) -> String {
      return L10n.tr("Localizable", "send.memo", String(describing: p1), fallback: " memo: %@")
    }
    /// Write a private message here
    internal static let memoPlaceholder = L10n.tr("Localizable", "send.memoPlaceholder", fallback: "Write a private message here")
    /// Sending %@ %@ to
    internal static func sendingTo(_ p1: Any, _ p2: Any) -> String {
      return L10n.tr("Localizable", "send.sendingTo", String(describing: p1), String(describing: p2), fallback: "Sending %@ %@ to")
    }
    /// Sending transaction succeeded
    internal static let succeeded = L10n.tr("Localizable", "send.succeeded", fallback: "Sending transaction succeeded")
    /// Send Zcash
    internal static let title = L10n.tr("Localizable", "send.title", fallback: "Send Zcash")
  }
  internal enum Settings {
    /// About
    internal static let about = L10n.tr("Localizable", "settings.about", fallback: "About")
    /// Backup Wallet
    internal static let backupWallet = L10n.tr("Localizable", "settings.backupWallet", fallback: "Backup Wallet")
    /// Enable Crash Reporting
    internal static let crashReporting = L10n.tr("Localizable", "settings.crashReporting", fallback: "Enable Crash Reporting")
    /// Exporting...
    internal static let exporting = L10n.tr("Localizable", "settings.exporting", fallback: "Exporting...")
    /// Export & share logs
    internal static let exportLogs = L10n.tr("Localizable", "settings.exportLogs", fallback: "Export & share logs")
    /// Send us feedback!
    internal static let feedback = L10n.tr("Localizable", "settings.feedback", fallback: "Send us feedback!")
    /// Settings
    internal static let title = L10n.tr("Localizable", "settings.title", fallback: "Settings")
    /// Version %@ (%@)
    internal static func version(_ p1: Any, _ p2: Any) -> String {
      return L10n.tr("Localizable", "settings.version", String(describing: p1), String(describing: p2), fallback: "Version %@ (%@)")
    }
    internal enum Alert {
      internal enum CantBackupWallet {
        /// Error: %@ (code: %@)
        internal static func message(_ p1: Any, _ p2: Any) -> String {
          return L10n.tr("Localizable", "settings.alert.cantBackupWallet.message", String(describing: p1), String(describing: p2), fallback: "Error: %@ (code: %@)")
        }
        /// Can't backup wallet
        internal static let title = L10n.tr("Localizable", "settings.alert.cantBackupWallet.title", fallback: "Can't backup wallet")
      }
      internal enum CantSendEmail {
        /// It looks like that you don't have any email account configured on your device. Therefore it's not possible to send a support email.
        internal static let message = L10n.tr("Localizable", "settings.alert.cantSendEmail.message", fallback: "It looks like that you don't have any email account configured on your device. Therefore it's not possible to send a support email.")
        /// Can't send email
        internal static let title = L10n.tr("Localizable", "settings.alert.cantSendEmail.title", fallback: "Can't send email")
      }
    }
  }
  internal enum SupportData {
    internal enum AppVersionItem {
      /// App identifier
      internal static let bundleIdentifier = L10n.tr("Localizable", "supportData.appVersionItem.bundleIdentifier", fallback: "App identifier")
      /// App version
      internal static let version = L10n.tr("Localizable", "supportData.appVersionItem.version", fallback: "App version")
    }
    internal enum DeviceModelItem {
      /// Device
      internal static let device = L10n.tr("Localizable", "supportData.deviceModelItem.device", fallback: "Device")
    }
    internal enum FreeDiskSpaceItem {
      /// Usable storage
      internal static let freeDiskSpace = L10n.tr("Localizable", "supportData.freeDiskSpaceItem.freeDiskSpace", fallback: "Usable storage")
    }
    internal enum LocaleItem {
      /// Currency decimal separator
      internal static let decimalSeparator = L10n.tr("Localizable", "supportData.localeItem.decimalSeparator", fallback: "Currency decimal separator")
      /// Currency grouping separator
      internal static let groupingSeparator = L10n.tr("Localizable", "supportData.localeItem.groupingSeparator", fallback: "Currency grouping separator")
      /// Locale
      internal static let locale = L10n.tr("Localizable", "supportData.localeItem.locale", fallback: "Locale")
    }
    internal enum PermissionItem {
      /// Camera access
      internal static let camera = L10n.tr("Localizable", "supportData.permissionItem.camera", fallback: "Camera access")
      /// FaceID available
      internal static let faceID = L10n.tr("Localizable", "supportData.permissionItem.faceID", fallback: "FaceID available")
      /// Permissions
      internal static let permissions = L10n.tr("Localizable", "supportData.permissionItem.permissions", fallback: "Permissions")
      /// TouchID available
      internal static let touchID = L10n.tr("Localizable", "supportData.permissionItem.touchID", fallback: "TouchID available")
    }
    internal enum SystemVersionItem {
      /// iOS version
      internal static let version = L10n.tr("Localizable", "supportData.systemVersionItem.version", fallback: "iOS version")
    }
    internal enum TimeItem {
      /// Current time
      internal static let time = L10n.tr("Localizable", "supportData.timeItem.time", fallback: "Current time")
    }
  }
  internal enum Sync {
    internal enum Message {
      /// Error: %@
      internal static func error(_ p1: Any) -> String {
        return L10n.tr("Localizable", "sync.message.error", String(describing: p1), fallback: "Error: %@")
      }
      /// %@%% Synced
      internal static func sync(_ p1: Any) -> String {
        return L10n.tr("Localizable", "sync.message.sync", String(describing: p1), fallback: "%@%% Synced")
      }
      /// Unprepared
      internal static let unprepared = L10n.tr("Localizable", "sync.message.unprepared", fallback: "Unprepared")
      /// Up-To-Date
      internal static let uptodate = L10n.tr("Localizable", "sync.message.uptodate", fallback: "Up-To-Date")
    }
  }
  internal enum Transaction {
    /// Confirmed
    internal static let confirmed = L10n.tr("Localizable", "transaction.confirmed", fallback: "Confirmed")
    /// %@ times
    internal static func confirmedTimes(_ p1: Any) -> String {
      return L10n.tr("Localizable", "transaction.confirmedTimes", String(describing: p1), fallback: "%@ times")
    }
    /// Confirming ~%@mins
    internal static func confirming(_ p1: Any) -> String {
      return L10n.tr("Localizable", "transaction.confirming", String(describing: p1), fallback: "Confirming ~%@mins")
    }
    /// Failed
    internal static let failed = L10n.tr("Localizable", "transaction.failed", fallback: "Failed")
    /// Received
    internal static let received = L10n.tr("Localizable", "transaction.received", fallback: "Received")
    /// RECEIVING
    internal static let receiving = L10n.tr("Localizable", "transaction.receiving", fallback: "RECEIVING")
    /// SENDING
    internal static let sending = L10n.tr("Localizable", "transaction.sending", fallback: "SENDING")
    /// Sent
    internal static let sent = L10n.tr("Localizable", "transaction.sent", fallback: "Sent")
    /// to
    internal static let to = L10n.tr("Localizable", "transaction.to", fallback: "to")
    /// unconfirmed
    internal static let unconfirmed = L10n.tr("Localizable", "transaction.unconfirmed", fallback: "unconfirmed")
    /// With memo:
    internal static let withMemo = L10n.tr("Localizable", "transaction.withMemo", fallback: "With memo:")
    /// You are receiving %@ %@
    internal static func youAreReceiving(_ p1: Any, _ p2: Any) -> String {
      return L10n.tr("Localizable", "transaction.youAreReceiving", String(describing: p1), String(describing: p2), fallback: "You are receiving %@ %@")
    }
    /// You are sending %@ %@
    internal static func youAreSending(_ p1: Any, _ p2: Any) -> String {
      return L10n.tr("Localizable", "transaction.youAreSending", String(describing: p1), String(describing: p2), fallback: "You are sending %@ %@")
    }
    /// You DID NOT send %@ %@
    internal static func youDidNotSent(_ p1: Any, _ p2: Any) -> String {
      return L10n.tr("Localizable", "transaction.youDidNotSent", String(describing: p1), String(describing: p2), fallback: "You DID NOT send %@ %@")
    }
    /// You received %@ %@
    internal static func youReceived(_ p1: Any, _ p2: Any) -> String {
      return L10n.tr("Localizable", "transaction.youReceived", String(describing: p1), String(describing: p2), fallback: "You received %@ %@")
    }
    /// You sent %@ %@
    internal static func youSent(_ p1: Any, _ p2: Any) -> String {
      return L10n.tr("Localizable", "transaction.youSent", String(describing: p1), String(describing: p2), fallback: "You sent %@ %@")
    }
  }
  internal enum TransactionDetail {
    /// Error: %@
    internal static func error(_ p1: Any) -> String {
      return L10n.tr("Localizable", "transactionDetail.error", String(describing: p1), fallback: "Error: %@")
    }
    /// Transaction detail
    internal static let title = L10n.tr("Localizable", "transactionDetail.title", fallback: "Transaction detail")
  }
  internal enum Transactions {
    /// Transactions
    internal static let title = L10n.tr("Localizable", "transactions.title", fallback: "Transactions")
  }
  internal enum ValidationFailed {
    /// Your placed words did not match your secret recovery phrase.
    internal static let description = L10n.tr("Localizable", "validationFailed.description", fallback: "Your placed words did not match your secret recovery phrase.")
    /// Remember, you can't recover your funds if you lose (or incorrectly save) these 24 words.
    internal static let incorrectBackupDescription = L10n.tr("Localizable", "validationFailed.incorrectBackupDescription", fallback: "Remember, you can't recover your funds if you lose (or incorrectly save) these 24 words.")
    /// Ouch, sorry, no.
    internal static let title = L10n.tr("Localizable", "validationFailed.title", fallback: "Ouch, sorry, no.")
    internal enum Button {
      /// Try again
      internal static let tryAgain = L10n.tr("Localizable", "validationFailed.button.tryAgain", fallback: "Try again")
    }
  }
  internal enum ValidationSuccess {
    /// Place that backup somewhere safe and venture forth in security.
    internal static let description = L10n.tr("Localizable", "validationSuccess.description", fallback: "Place that backup somewhere safe and venture forth in security.")
    /// Success!
    internal static let title = L10n.tr("Localizable", "validationSuccess.title", fallback: "Success!")
    internal enum Button {
      /// Take me to my wallet!
      internal static let goToWallet = L10n.tr("Localizable", "validationSuccess.button.goToWallet", fallback: "Take me to my wallet!")
      /// Show me my phrase again
      internal static let phraseAgain = L10n.tr("Localizable", "validationSuccess.button.phraseAgain", fallback: "Show me my phrase again")
    }
  }
  internal enum WalletEvent {
    internal enum Alert {
      internal enum LeavingApp {
        /// While usually an acceptable risk, you will possibly exposing your behavior and interest in this transaction by going online. OH NOES! What will you do?
        internal static let message = L10n.tr("Localizable", "walletEvent.alert.leavingApp.message", fallback: "While usually an acceptable risk, you will possibly exposing your behavior and interest in this transaction by going online. OH NOES! What will you do?")
        /// You are exiting your wallet
        internal static let title = L10n.tr("Localizable", "walletEvent.alert.leavingApp.title", fallback: "You are exiting your wallet")
        internal enum Button {
          /// NEVERMIND
          internal static let nevermind = L10n.tr("Localizable", "walletEvent.alert.leavingApp.button.nevermind", fallback: "NEVERMIND")
          /// SEE TX ONLINE
          internal static let seeOnline = L10n.tr("Localizable", "walletEvent.alert.leavingApp.button.seeOnline", fallback: "SEE TX ONLINE")
        }
      }
    }
    internal enum Detail {
      /// wallet import wallet event
      internal static let `import` = L10n.tr("Localizable", "walletEvent.detail.import", fallback: "wallet import wallet event")
      /// shielded %@ detail
      internal static func shielded(_ p1: Any) -> String {
        return L10n.tr("Localizable", "walletEvent.detail.shielded", String(describing: p1), fallback: "shielded %@ detail")
      }
    }
    internal enum Row {
      /// wallet import wallet event
      internal static let `import` = L10n.tr("Localizable", "walletEvent.row.import", fallback: "wallet import wallet event")
      /// shielded wallet event %@
      internal static func shielded(_ p1: Any) -> String {
        return L10n.tr("Localizable", "walletEvent.row.shielded", String(describing: p1), fallback: "shielded wallet event %@")
      }
    }
  }
  internal enum WelcomeScreen {
    /// Just Loading, one sec
    internal static let subtitle = L10n.tr("Localizable", "welcomeScreen.subtitle", fallback: "Just Loading, one sec")
    /// Powered by Zcash
    internal static let title = L10n.tr("Localizable", "welcomeScreen.title", fallback: "Powered by Zcash")
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

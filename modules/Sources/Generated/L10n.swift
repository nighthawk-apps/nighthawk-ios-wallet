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
            /// Nighthawk is a Private-by-Default wallet for DarkFi. All transactions are fully private with no transparent address support.
            ///
            /// As a non-custodial wallet, you have sole responsibility over your funds. Please immediately and securely back up the seed words upon creating a wallet.
            ///
            /// DarkFi is a layer-1 blockchain designed for anonymous applications and private finance. It was designed by the DarkFi community to enable financial freedom.
            ///
            /// Nighthawk Wallet connects directly to the DarkFi P2P network. This software is provided "as is", without warranty of any kind, express or implied.
            public static let message = L10n.tr("Localizable", "nighthawk.about.message", fallback: "Nighthawk is a Private-by-Default wallet for DarkFi. All transactions are fully private with no transparent address support.\n\nAs a non-custodial wallet, you have sole responsibility over your funds. Please immediately and securely back up the seed words upon creating a wallet.\n\nDarkFi is a layer-1 blockchain designed for anonymous applications and private finance. It was designed by the DarkFi community to enable financial freedom.\n\nNighthawk Wallet connects directly to the DarkFi P2P network. This software is provided \"as is\", without warranty of any kind, express or implied.")
            /// Nighthawk friends
            public static let nighthawkFriends = L10n.tr("Localizable", "nighthawk.about.nighthawkFriends", fallback: "Nighthawk friends")
            /// About
            public static let title = L10n.tr("Localizable", "nighthawk.about.title", fallback: "About")
            /// View licenses
            public static let viewLicenses = L10n.tr("Localizable", "nighthawk.about.viewLicenses", fallback: "View licenses")
            /// View Source
            public static let viewSource = L10n.tr("Localizable", "nighthawk.about.viewSource", fallback: "View Source")
            /// Open Source Licenses
            public static let openSourceLicenses = L10n.tr("Localizable", "nighthawk.about.openSourceLicenses", fallback: "Open Source Licenses")
            /// Version %@ (%@)
            public static func versionWithBuild(_ p1: Any, _ p2: Any) -> String {
                return L10n.tr("Localizable", "nighthawk.about.versionWithBuild", String(describing: p1), String(describing: p2), fallback: "Version %@ (%@)")
            }
            /// Version %@
            public static func versionOnly(_ p1: Any) -> String {
                return L10n.tr("Localizable", "nighthawk.about.versionOnly", String(describing: p1), fallback: "Version %@")
            }
        }
        public enum Chat {
            public static let peers = L10n.tr("Localizable", "nighthawk.chat.peers", fallback: "Peers")
            public static let retry = L10n.tr("Localizable", "nighthawk.chat.retry", fallback: "Retry")
            public static let outboundPeers = L10n.tr("Localizable", "nighthawk.chat.outboundPeers", fallback: "Outbound peers")
            public static let title = L10n.tr("Localizable", "nighthawk.chat.title", fallback: "DarkFi IRC")
            public static let subtitle = L10n.tr("Localizable", "nighthawk.chat.subtitle", fallback: "End-to-end encrypted chat\npowered by the DarkFi P2P network")
            public static let connect = L10n.tr("Localizable", "nighthawk.chat.connect", fallback: "Connect")
            public static let networkHint = L10n.tr("Localizable", "nighthawk.chat.networkHint", fallback: "Check your network settings or configure Tor in Settings.")
            public static let newDm = L10n.tr("Localizable", "nighthawk.chat.newDm", fallback: "New DM")
            public static let request = L10n.tr("Localizable", "nighthawk.chat.request", fallback: "Request")
            public static let settings = L10n.tr("Localizable", "nighthawk.chat.settings", fallback: "Settings")
            public static let shareKey = L10n.tr("Localizable", "nighthawk.chat.shareKey", fallback: "Share Key")
            public static let noMessages = L10n.tr("Localizable", "nighthawk.chat.noMessages", fallback: "No messages yet")
            /// Could not decrypt
            public static let couldNotDecrypt = L10n.tr("Localizable", "nighthawk.chat.couldNotDecrypt", fallback: "Could not decrypt")
            public static func ircStatus(_ p1: Any) -> String {
                L10n.tr("Localizable", "nighthawk.chat.ircStatus", String(describing: p1), fallback: "IRC: %@")
            }
            public static func nodeStatus(_ p1: Any) -> String {
                L10n.tr("Localizable", "nighthawk.chat.nodeStatus", String(describing: p1), fallback: "Node: %@")
            }
            public static let clearnetAlertTitle = L10n.tr("Localizable", "nighthawk.chat.clearnetAlertTitle", fallback: "Open clearnet link?")
            public static let clearnetOpenBrowser = L10n.tr("Localizable", "nighthawk.chat.clearnetOpenBrowser", fallback: "Open in browser")
            public static let clearnetCopyLink = L10n.tr("Localizable", "nighthawk.chat.clearnetCopyLink", fallback: "Copy link")
            public static let clearnetAlertMessage = L10n.tr("Localizable", "nighthawk.chat.clearnetAlertMessage", fallback: "This opens http(s) outside Nym/Tor and can leak your IP.")
            public static let routeNym = L10n.tr("Localizable", "nighthawk.chat.routeNym", fallback: "Nym mixnet")
            public static let routeTor = L10n.tr("Localizable", "nighthawk.chat.routeTor", fallback: "Tor")
            public static let routeDirect = L10n.tr("Localizable", "nighthawk.chat.routeDirect", fallback: "Direct (clearnet)")
            public static let routeBootstrapping = L10n.tr("Localizable", "nighthawk.chat.routeBootstrapping", fallback: "Bootstrapping…")
            public static let routeDegraded = L10n.tr("Localizable", "nighthawk.chat.routeDegraded", fallback: "Degraded")
            public static let routeOffline = L10n.tr("Localizable", "nighthawk.chat.routeOffline", fallback: "Offline")
            public static let activePrivacyRoute = L10n.tr("Localizable", "nighthawk.chat.activePrivacyRoute", fallback: "Active privacy route")
            public static func lightwalletdHeight(_ p1: Any) -> String {
                L10n.tr("Localizable", "nighthawk.chat.lightwalletdHeight", String(describing: p1), fallback: "Lightwalletd height %@")
            }
            public static let lightwalletdHeightUnavailable = L10n.tr("Localizable", "nighthawk.chat.lightwalletdHeightUnavailable", fallback: "Lightwalletd height unavailable")
            public static func transportSummary(_ p1: Any) -> String {
                L10n.tr("Localizable", "nighthawk.chat.transportSummary", String(describing: p1), fallback: "Transport: %@")
            }
            public static let directE2eBadge = L10n.tr("Localizable", "nighthawk.chat.directE2eBadge", fallback: "Direct message · E2E")
            public static let publicPlaintextBadge = L10n.tr("Localizable", "nighthawk.chat.publicPlaintextBadge", fallback: "Public channel · plaintext on the DAG")
            public static let sharePubkeyTitle = L10n.tr("Localizable", "nighthawk.chat.sharePubkeyTitle", fallback: "Share Your Public Key")
            public static let sharePubkeyCopy = L10n.tr("Localizable", "nighthawk.chat.sharePubkeyCopy", fallback: "Copy public key")
            public static let sharePubkeyMessage = L10n.tr("Localizable", "nighthawk.chat.sharePubkeyMessage", fallback: "Copies your DM public key. A keypair is created only the first time. Share it over a channel you trust. Anyone with this key can send you encrypted DMs.")
            public static let myPublicKeyCopied = L10n.tr("Localizable", "nighthawk.chat.myPublicKeyCopied", fallback: "MY PUBLIC KEY (copied)")
            public static let noDmContactsTitle = L10n.tr("Localizable", "nighthawk.chat.noDmContactsTitle", fallback: "No DM contacts")
            public static let noDmContactsBody = L10n.tr("Localizable", "nighthawk.chat.noDmContactsBody", fallback: "Tap \"New DM\" to exchange ChaCha20 public keys with a peer and start an encrypted conversation.")
            public static let e2eEncrypted = L10n.tr("Localizable", "nighthawk.chat.e2eEncrypted", fallback: "E2E encrypted")
            public static let copyMessage = L10n.tr("Localizable", "nighthawk.chat.copyMessage", fallback: "Copy Message")
            public static func queueFile(_ p1: Any) -> String {
                L10n.tr("Localizable", "nighthawk.chat.queueFile", String(describing: p1), fallback: "Queue %@")
            }
            public static let paymentRequest = L10n.tr("Localizable", "nighthawk.chat.paymentRequest", fallback: "Payment request")
            public static let pay = L10n.tr("Localizable", "nighthawk.chat.pay", fallback: "Pay")
            public static func paymentPhase(_ p1: Any) -> String {
                L10n.tr("Localizable", "nighthawk.chat.paymentPhase", String(describing: p1), fallback: "Payment %@")
            }
            public static let link = L10n.tr("Localizable", "nighthawk.chat.link", fallback: "Link")
            public static let sendOrRequestDrk = L10n.tr("Localizable", "nighthawk.chat.sendOrRequestDrk", fallback: "Send or request DRK")
            public static let messagePlaceholder = L10n.tr("Localizable", "nighthawk.chat.messagePlaceholder", fallback: "Message")
            public static let amountDrkPlaceholder = L10n.tr("Localizable", "nighthawk.chat.amountDrkPlaceholder", fallback: "Amount (DRK)")
            public static let payToAddressPlaceholder = L10n.tr("Localizable", "nighthawk.chat.payToAddressPlaceholder", fallback: "Pay to address")
            public static let tip = L10n.tr("Localizable", "nighthawk.chat.tip", fallback: "Tip")
            public enum NewDm {
                public static let title = L10n.tr("Localizable", "nighthawk.chat.newDm.title", fallback: "New DM Conversation")
                public static let subtitle = L10n.tr("Localizable", "nighthawk.chat.newDm.subtitle", fallback: "Exchange public keys with your peer to start an end-to-end encrypted DM using ChaCha20.")
                public static let contactLabelSection = L10n.tr("Localizable", "nighthawk.chat.newDm.contactLabelSection", fallback: "CONTACT LABEL")
                public static let contactLabelPlaceholder = L10n.tr("Localizable", "nighthawk.chat.newDm.contactLabelPlaceholder", fallback: "e.g. alice")
                public static let peerPubkeySection = L10n.tr("Localizable", "nighthawk.chat.newDm.peerPubkeySection", fallback: "PEER'S PUBLIC KEY")
                public static let peerPubkeyPlaceholder = L10n.tr("Localizable", "nighthawk.chat.newDm.peerPubkeyPlaceholder", fallback: "Base58 public key")
                public static let pasteClipboard = L10n.tr("Localizable", "nighthawk.chat.newDm.pasteClipboard", fallback: "Paste from Clipboard")
                public static let myKeypairSection = L10n.tr("Localizable", "nighthawk.chat.newDm.myKeypairSection", fallback: "MY KEYPAIR")
                public static let generateKeys = L10n.tr("Localizable", "nighthawk.chat.newDm.generateKeys", fallback: "Generate My Keys")
                public static let myPublicKeyLabel = L10n.tr("Localizable", "nighthawk.chat.newDm.myPublicKeyLabel", fallback: "My Public Key:")
                public static let copyToShare = L10n.tr("Localizable", "nighthawk.chat.newDm.copyToShare", fallback: "Copy to Share")
                public static let shareKeyHint = L10n.tr("Localizable", "nighthawk.chat.newDm.shareKeyHint", fallback: "Share this key with your peer so they can message you.")
                public static let startDm = L10n.tr("Localizable", "nighthawk.chat.newDm.startDm", fallback: "Start DM")
                public static let pasteAlertTitle = L10n.tr("Localizable", "nighthawk.chat.newDm.pasteAlertTitle", fallback: "Paste Public Key")
                public static let pasteAction = L10n.tr("Localizable", "nighthawk.chat.newDm.pasteAction", fallback: "Paste")
                public static let pasteAlertMessage = L10n.tr("Localizable", "nighthawk.chat.newDm.pasteAlertMessage", fallback: "Paste the DM public key from clipboard? The key will be extracted from !darkfi-dm-pubkey: format if present.")
                public static let errorKeygen = L10n.tr("Localizable", "nighthawk.chat.newDm.errorKeygen", fallback: "Failed to generate DM keypair")
                public static let errorInvalidClipboard = L10n.tr("Localizable", "nighthawk.chat.newDm.errorInvalidClipboard", fallback: "Clipboard does not contain a valid base58 public key.")
                public static let errorSaveKeychain = L10n.tr("Localizable", "nighthawk.chat.newDm.errorSaveKeychain", fallback: "Could not save this contact to the Keychain.")
            }
        }
        public enum Receive {
            public static let sendAndReceive = L10n.tr("Localizable", "nighthawk.receive.sendAndReceive", fallback: "Send and receive DRK")
            public static let receivePrivately = L10n.tr("Localizable", "nighthawk.receive.receivePrivately", fallback: "Receive money privately")
            public static let showQr = L10n.tr("Localizable", "nighthawk.receive.showQr", fallback: "Show QR Code")
            public static let showQrDetail = L10n.tr("Localizable", "nighthawk.receive.showQrDetail", fallback: "Let someone scan to send you money.")
            public static let copyAddress = L10n.tr("Localizable", "nighthawk.receive.copyAddress", fallback: "Copy private address")
            public static let copyAddressDetail = L10n.tr("Localizable", "nighthawk.receive.copyAddressDetail", fallback: "Your wallet address will be copied to the clipboard.")
            public static let newAddressGenerated = L10n.tr("Localizable", "nighthawk.receive.newAddressGenerated", fallback: "New address generated")
            public static let generateFailed = L10n.tr("Localizable", "nighthawk.receive.generateFailed", fallback: "Failed to generate address")
        }
        public enum RequestMoney {
            public static let title = L10n.tr("Localizable", "nighthawk.requestMoney.title", fallback: "Request money")
            public static let subtitle = L10n.tr("Localizable", "nighthawk.requestMoney.subtitle", fallback: "One receive address. The QR is a drk: invoice with the amount and memo you enter.")
            public static let amount = L10n.tr("Localizable", "nighthawk.requestMoney.amount", fallback: "Amount")
            public static let memo = L10n.tr("Localizable", "nighthawk.requestMoney.memo", fallback: "Memo")
            public static let copied = L10n.tr("Localizable", "nighthawk.requestMoney.copied", fallback: "Copied")
            public static let copyInvoice = L10n.tr("Localizable", "nighthawk.requestMoney.copyInvoice", fallback: "Copy invoice")
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
            /// Privacy
            public static let autoshielding = L10n.tr("Localizable", "nighthawk.autoshield.autoshielding", fallback: "Privacy")
            /// Learn more
            public static let buttonNeutral = L10n.tr("Localizable", "nighthawk.autoshield.buttonNeutral", fallback: "Learn more")
            /// Great!
            public static let buttonPositive = L10n.tr("Localizable", "nighthawk.autoshield.buttonPositive", fallback: "Great!")
            /// All funds are always private. DarkFi has no transparent address concept.
            public static let detail1 = L10n.tr("Localizable", "nighthawk.autoshield.detail1", fallback: "All funds are always private. DarkFi has no transparent address concept.")
            /// We are committed to providing regular updates on the latest privacy-preserving best practices and recommendations to keep you well-informed.
            public static let detail2 = L10n.tr("Localizable", "nighthawk.autoshield.detail2", fallback: "We are committed to providing regular updates on the latest privacy-preserving best practices and recommendations to keep you well-informed.")
            /// Private-by-Default.
            public static let shieldedByDefault = L10n.tr("Localizable", "nighthawk.autoshield.shieldedByDefault", fallback: "Private-by-Default.")
            /// Processing…
            public static let shielding = L10n.tr("Localizable", "nighthawk.autoshield.shielding", fallback: "Processing…")
            /// Failed
            public static let shieldingFailed = L10n.tr("Localizable", "nighthawk.autoshield.shieldingFailed", fallback: "Failed")
            /// Nighthawk 🛡️
            public static let shieldingMemo = L10n.tr("Localizable", "nighthawk.autoshield.shieldingMemo", fallback: "Nighthawk 🛡️")
            /// Success
            public static let shieldingSuccess = L10n.tr("Localizable", "nighthawk.autoshield.shieldingSuccess", fallback: "Success")
            /// Nighthawk is
            public static let title1 = L10n.tr("Localizable", "nighthawk.autoshield.title1", fallback: "Nighthawk is")
            /// All transactions on DarkFi are private. There is no transparent address or shielded pool — everything is private.
            public static let title2 = L10n.tr("Localizable", "nighthawk.autoshield.title2", fallback: "All transactions on DarkFi are private. There is no transparent address or shielded pool — everything is private.")
            public enum Alert {
                public enum Redirecting {
                    /// Please confirm opening your device browser to learn more about DarkFi privacy.
                    public static let details = L10n.tr("Localizable", "nighthawk.autoshield.alert.redirecting.details", fallback: "Please confirm opening your device browser to learn more about DarkFi privacy.")
                    /// Open Browser
                    public static let openBrowser = L10n.tr("Localizable", "nighthawk.autoshield.alert.redirecting.openBrowser", fallback: "Open Browser")
                    /// Redirecting to DarkFi
                    public static let title = L10n.tr("Localizable", "nighthawk.autoshield.alert.redirecting.title", fallback: "Redirecting to DarkFi")
                }
            }
        }
        public enum DaoHub {
            /// Add funds
            public static let addFunds = L10n.tr("Localizable", "nighthawk.daoHub.addFunds", fallback: "Add funds")
            /// This marks the coins so the DAO can pay them out later.
            public static let addFundsHint = L10n.tr("Localizable", "nighthawk.daoHub.addFundsHint", fallback: "This marks the coins so the DAO can pay them out later.")
            /// Admin
            public static let admin = L10n.tr("Localizable", "nighthawk.daoHub.admin", fallback: "Admin")
            /// This phone holds every role, including the keys that pay from the treasury.
            public static let allRolesHint = L10n.tr("Localizable", "nighthawk.daoHub.allRolesHint", fallback: "This phone holds every role, including the keys that pay from the treasury.")
            /// Amount
            public static let amount = L10n.tr("Localizable", "nighthawk.daoHub.amount", fallback: "Amount")
            /// Block windows
            public static let blockWindows = L10n.tr("Localizable", "nighthawk.daoHub.blockWindows", fallback: "Block windows")
            /// Browse DAOs, proposals, and the treasury.
            public static let browseDescription = L10n.tr("Localizable", "nighthawk.daoHub.browseDescription", fallback: "Browse DAOs, proposals, and the treasury.")
            /// Screen recording or screenshot detected. Secret hidden.
            public static let captured = L10n.tr("Localizable", "nighthawk.daoHub.captured", fallback: "Screen recording or screenshot detected. Secret hidden.")
            /// Close
            public static let close = L10n.tr("Localizable", "nighthawk.daoHub.close", fallback: "Close")
            /// Copy
            public static let copy = L10n.tr("Localizable", "nighthawk.daoHub.copy", fallback: "Copy")
            /// DAO
            public static let dao = L10n.tr("Localizable", "nighthawk.daoHub.dao", fallback: "DAO")
            /// DAO not found
            public static let daoNotFound = L10n.tr("Localizable", "nighthawk.daoHub.daoNotFound", fallback: "DAO not found")
            /// Details
            public static let details = L10n.tr("Localizable", "nighthawk.daoHub.details", fallback: "Details")
            /// Duration
            public static let duration = L10n.tr("Localizable", "nighthawk.daoHub.duration", fallback: "Duration")
            /// Leave early quorum empty to use the same number as votes needed.
            public static let earlyQuorum = L10n.tr("Localizable", "nighthawk.daoHub.earlyQuorum", fallback: "Early quorum")
            /// Leave empty to use the same number as votes needed.
            public static let earlyQuorumHint = L10n.tr("Localizable", "nighthawk.daoHub.earlyQuorumHint", fallback: "Leave empty to use the same number as votes needed.")
            /// Refresh, or start a DAO from this wallet.
            public static let emptyBody = L10n.tr("Localizable", "nighthawk.daoHub.emptyBody", fallback: "Refresh, or start a DAO from this wallet.")
            /// Sync has not found a DAO yet.
            public static let emptyTitle = L10n.tr("Localizable", "nighthawk.daoHub.emptyTitle", fallback: "Sync has not found a DAO yet.")
            /// Exec height
            public static let execHeight = L10n.tr("Localizable", "nighthawk.daoHub.execHeight", fallback: "Exec height")
            /// Exec tx
            public static let execTx = L10n.tr("Localizable", "nighthawk.daoHub.execTx", fallback: "Exec tx")
            /// Executor
            public static let executor = L10n.tr("Localizable", "nighthawk.daoHub.executor", fallback: "Executor")
            /// Freeze supply
            public static let freezeSupply = L10n.tr("Localizable", "nighthawk.daoHub.freezeSupply", fallback: "Freeze supply")
            /// Full copy
            public static let fullCopy = L10n.tr("Localizable", "nighthawk.daoHub.fullCopy", fallback: "Full copy")
            /// Funds sent to the treasury
            public static let fundsSent = L10n.tr("Localizable", "nighthawk.daoHub.fundsSent", fallback: "Funds sent to the treasury")
            /// Governance token
            public static let governanceToken = L10n.tr("Localizable", "nighthawk.daoHub.governanceToken", fallback: "Governance token")
            /// Group id
            public static let groupId = L10n.tr("Localizable", "nighthawk.daoHub.groupId", fallback: "DAO id")
            /// Group imported
            public static let groupImported = L10n.tr("Localizable", "nighthawk.daoHub.groupImported", fallback: "DAO imported")
            /// Group submitted
            public static let groupSubmitted = L10n.tr("Localizable", "nighthawk.daoHub.groupSubmitted", fallback: "DAO submitted")
            /// DAOs this wallet has scanned. A payment from the treasury waits for a vote.
            public static let hubIntro = L10n.tr("Localizable", "nighthawk.daoHub.hubIntro", fallback: "DAOs this wallet has scanned. A payment from the treasury waits for a vote.")
            /// Import group
            public static let importGroup = L10n.tr("Localizable", "nighthawk.daoHub.importGroup", fallback: "Import DAO")
            /// Group file
            public static let importToml = L10n.tr("Localizable", "nighthawk.daoHub.importToml", fallback: "DAO file")
            /// The chain stores 8 decimals.
            public static let issueHint = L10n.tr("Localizable", "nighthawk.daoHub.issueHint", fallback: "The chain stores 8 decimals.")
            /// Issue more
            public static let issueMore = L10n.tr("Localizable", "nighthawk.daoHub.issueMore", fallback: "Issue more")
            /// Issue a token
            public static let issueToken = L10n.tr("Localizable", "nighthawk.daoHub.issueToken", fallback: "Issue a token")
            /// Mint height
            public static let mintHeight = L10n.tr("Localizable", "nighthawk.daoHub.mintHeight", fallback: "Mint height")
            /// Name
            public static let name = L10n.tr("Localizable", "nighthawk.daoHub.name", fallback: "Name")
            /// No votes yet.
            public static let noVotes = L10n.tr("Localizable", "nighthawk.daoHub.noVotes", fallback: "No votes yet.")
            /// Not scanned yet
            public static let notScannedYet = L10n.tr("Localizable", "nighthawk.daoHub.notScannedYet", fallback: "Not scanned yet")
            /// Observer
            public static let observer = L10n.tr("Localizable", "nighthawk.daoHub.observer", fallback: "Observer")
            /// 1 payment
            public static let onePayment = L10n.tr("Localizable", "nighthawk.daoHub.onePayment", fallback: "1 payment")
            /// Open
            public static let statusOpen = L10n.tr("Localizable", "nighthawk.daoHub.open", fallback: "Open")
            /// Paid
            public static let paid = L10n.tr("Localizable", "nighthawk.daoHub.paid", fallback: "Paid")
            /// Pay from treasury
            public static let payFromTreasury = L10n.tr("Localizable", "nighthawk.daoHub.payFromTreasury", fallback: "Pay from treasury")
            /// Sends the payment from the treasury.
            public static let payHint = L10n.tr("Localizable", "nighthawk.daoHub.payHint", fallback: "Sends the payment from the treasury.")
            /// Payment sent from the treasury
            public static let paymentSent = L10n.tr("Localizable", "nighthawk.daoHub.paymentSent", fallback: "Payment sent from the treasury")
            /// Proposal
            public static let proposal = L10n.tr("Localizable", "nighthawk.daoHub.proposal", fallback: "Proposal")
            /// Proposal id
            public static let proposalId = L10n.tr("Localizable", "nighthawk.daoHub.proposalId", fallback: "Proposal id")
            /// Proposal not found
            public static let proposalNotFound = L10n.tr("Localizable", "nighthawk.daoHub.proposalNotFound", fallback: "Proposal not found")
            /// Proposal submitted! %@…
            public static func proposalSubmitted(_ p1: Any) -> String {
                return L10n.tr("Localizable", "nighthawk.daoHub.proposalSubmitted", String(describing: p1), fallback: "Proposal submitted! %@…")
            }
            /// Propose a payment
            public static let proposePayment = L10n.tr("Localizable", "nighthawk.daoHub.proposePayment", fallback: "Propose a payment")
            /// This will generate ZK proofs on-device and broadcast the proposal transaction.
            public static let proposeBroadcast = L10n.tr("Localizable", "nighthawk.daoHub.proposeBroadcast", fallback: "This will generate ZK proofs on-device and broadcast the proposal transaction.")
            /// Propose tx
            public static let proposeTx = L10n.tr("Localizable", "nighthawk.daoHub.proposeTx", fallback: "Propose tx")
            /// Proposer
            public static let proposer = L10n.tr("Localizable", "nighthawk.daoHub.proposer", fallback: "Proposer")
            /// Proposer minimum
            public static let proposerMinimum = L10n.tr("Localizable", "nighthawk.daoHub.proposerMinimum", fallback: "Proposer minimum")
            /// Recipient
            public static let recipient = L10n.tr("Localizable", "nighthawk.daoHub.recipient", fallback: "Recipient")
            /// Recipient address
            public static let recipientAddress = L10n.tr("Localizable", "nighthawk.daoHub.recipientAddress", fallback: "Recipient address")
            /// Refresh
            public static let refresh = L10n.tr("Localizable", "nighthawk.daoHub.refresh", fallback: "Refresh")
            /// This code holds the role secret.
            public static let roleExportHint = L10n.tr("Localizable", "nighthawk.daoHub.roleExportHint", fallback: "This code holds the role secret.")
            /// Role export
            public static let roleExportTitle = L10n.tr("Localizable", "nighthawk.daoHub.roleExportTitle", fallback: "Role export")
            /// Start a group
            public static let startGroup = L10n.tr("Localizable", "nighthawk.daoHub.startGroup", fallback: "Start a DAO")
            /// Supply frozen
            public static let supplyFrozen = L10n.tr("Localizable", "nighthawk.daoHub.supplyFrozen", fallback: "Supply frozen")
            /// DAO Hub
            public static let title = L10n.tr("Localizable", "nighthawk.daoHub.title", fallback: "DAO")
            /// Token
            public static let token = L10n.tr("Localizable", "nighthawk.daoHub.token", fallback: "Token")
            /// Token created
            public static let tokenCreated = L10n.tr("Localizable", "nighthawk.daoHub.tokenCreated", fallback: "Token created")
            /// Token ID (default: DRK)
            public static let tokenIdPlaceholder = L10n.tr("Localizable", "nighthawk.daoHub.tokenIdPlaceholder", fallback: "Token ID (default: DRK)")
            /// Token (optional)
            public static let tokenOptional = L10n.tr("Localizable", "nighthawk.daoHub.tokenOptional", fallback: "Token (optional)")
            /// Tokens
            public static let tokens = L10n.tr("Localizable", "nighthawk.daoHub.tokens", fallback: "Tokens")
            /// Tokens issued
            public static let tokensIssued = L10n.tr("Localizable", "nighthawk.daoHub.tokensIssued", fallback: "Tokens issued")
            /// Treasury
            public static let treasury = L10n.tr("Localizable", "nighthawk.daoHub.treasury", fallback: "Treasury")
            /// Coins sent to the DAO without the treasury mark cannot be paid out later.
            public static let treasuryHint = L10n.tr("Localizable", "nighthawk.daoHub.treasuryHint", fallback: "Coins sent to the DAO without the treasury mark cannot be paid out later.")
            /// Vote NO submitted! TX: %@…
            public static func voteNoSubmitted(_ p1: Any) -> String {
                return L10n.tr("Localizable", "nighthawk.daoHub.voteNoSubmitted", String(describing: p1), fallback: "Vote NO submitted! TX: %@…")
            }
            /// Your full governance token balance is the vote weight.
            public static let voteWeight = L10n.tr("Localizable", "nighthawk.daoHub.voteWeight", fallback: "Your full governance token balance is the vote weight.")
            /// Vote YES submitted! TX: %@…
            public static func voteYesSubmitted(_ p1: Any) -> String {
                return L10n.tr("Localizable", "nighthawk.daoHub.voteYesSubmitted", String(describing: p1), fallback: "Vote YES submitted! TX: %@…")
            }
            /// Voter
            public static let voter = L10n.tr("Localizable", "nighthawk.daoHub.voter", fallback: "Voter")
            /// Votes
            public static let votes = L10n.tr("Localizable", "nighthawk.daoHub.votes", fallback: "Votes")
            /// Votes needed to count
            public static let votesNeeded = L10n.tr("Localizable", "nighthawk.daoHub.votesNeeded", fallback: "Votes needed to count")
            /// Voting window: %@ block windows (%@ hours).
            public static func votingWindow(_ p1: Any, _ p2: Any) -> String {
                return L10n.tr("Localizable", "nighthawk.daoHub.votingWindow", String(describing: p1), String(describing: p2), fallback: "Voting window: %@ block windows (%@ hours).")
            }
            /// Waiting
            public static let waiting = L10n.tr("Localizable", "nighthawk.daoHub.waiting", fallback: "Waiting")
            /// Wallet sync failed: %@
            public static func walletSyncFailed(_ p1: Any) -> String {
                return L10n.tr("Localizable", "nighthawk.daoHub.walletSyncFailed", String(describing: p1), fallback: "Wallet sync failed: %@")
            }
            /// Wallet sync is still in progress. Open DAO Hub again once your wallet is up to date.
            public static let walletSyncing = L10n.tr("Localizable", "nighthawk.daoHub.walletSyncing", fallback: "Wallet sync is still in progress. Open DAO Hub again once your wallet is up to date.")
            /// Wallet is not ready yet. Finish setup or wait for the wallet to initialize.
            public static let walletNotReady = L10n.tr("Localizable", "nighthawk.daoHub.walletNotReady", fallback: "Wallet is not ready yet. Finish setup or wait for the wallet to initialize.")
            /// Wallet sync is stopped. Resume sync from the Wallet tab, then open DAO Hub again.
            public static let walletStopped = L10n.tr("Localizable", "nighthawk.daoHub.walletStopped", fallback: "Wallet sync is stopped. Resume sync from the Wallet tab, then open DAO Hub again.")
            /// Yes share
            public static let yesShare = L10n.tr("Localizable", "nighthawk.daoHub.yesShare", fallback: "Yes share")
            /// Yes share required
            public static let yesShareRequired = L10n.tr("Localizable", "nighthawk.daoHub.yesShareRequired", fallback: "Yes share required")
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
        public enum Dex {
            /// Coming soon
            public static let comingSoon = L10n.tr("Localizable", "nighthawk.dex.comingSoon", fallback: "Coming soon")
            /// The DarkFi DEX will live here. Send, receive, and request stay on Wallet.
            public static let comingSoonBody = L10n.tr("Localizable", "nighthawk.dex.comingSoonBody", fallback: "The DarkFi DEX will live here. Send, receive, and request stay on Wallet.")
            /// DEX
            public static let title = L10n.tr("Localizable", "nighthawk.dex.title", fallback: "DEX")
        }
        public enum HomeScreen {
            /// Chat
            public static let chat = L10n.tr("Localizable", "nighthawk.homeScreen.chat", fallback: "Chat")
            /// Expecting %@ %@
            public static func expectingFunds(_ p1: Any, _ p2: Any) -> String {
                return L10n.tr("Localizable", "nighthawk.homeScreen.expectingFunds", String(describing: p1), String(describing: p2), fallback: "Expecting %@ %@")
            }
            /// DEX
            public static let dex = L10n.tr("Localizable", "nighthawk.homeScreen.dex", fallback: "DEX")
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
            /// Enter your 22 word seed phrase below. If you do not have this phrase, you will need to create a new wallet.
            public static let enterSeedPhrase = L10n.tr("Localizable", "nighthawk.importWallet.enterSeedPhrase", fallback: "Enter your 22 word seed phrase below. If you do not have this phrase, you will need to create a new wallet.")
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
            /// If you lose access to your phone or Nighthawk wallet, the only way you can regain access to your DarkFi is if you have this 22 word phrase and wallet birthday code.
            public static let instructions1 = L10n.tr("Localizable", "nighthawk.recoveryPhraseDisplay.instructions1", fallback: "If you lose access to your phone or Nighthawk wallet, the only way you can regain access to your DarkFi is if you have this 22 word phrase and wallet birthday code.")
            /// Write it down on paper and store it somewhere safe.
            public static let instructions2 = L10n.tr("Localizable", "nighthawk.recoveryPhraseDisplay.instructions2", fallback: "Write it down on paper and store it somewhere safe.")
            /// These are seed words used to restore your DarkFi in Nighthawk Wallet:
            public static let pdfHeader = L10n.tr("Localizable", "nighthawk.recoveryPhraseDisplay.pdfHeader", fallback: "These are seed words used to restore your DarkFi in Nighthawk Wallet:")
            /// Backup PDF generated at %@
            public static func pdfTimestamp(_ p1: Any) -> String {
                return L10n.tr("Localizable", "nighthawk.recoveryPhraseDisplay.pdfTimestamp", String(describing: p1), fallback: "Backup PDF generated at %@")
            }
            /// Write down your backup seed
            public static let title = L10n.tr("Localizable", "nighthawk.recoveryPhraseDisplay.title", fallback: "Write down your backup seed")
            public static let screenCaptured = L10n.tr("Localizable", "nighthawk.recoveryPhraseDisplay.screenCaptured", fallback: "Screen recording or screenshot detected.\nSeed phrase hidden for security.")
            public static let quizTitle = L10n.tr("Localizable", "nighthawk.recoveryPhraseDisplay.quizTitle", fallback: "Confirm Backup (3 Words)")
            public static let quizSubtitle = L10n.tr("Localizable", "nighthawk.recoveryPhraseDisplay.quizSubtitle", fallback: "Enter the requested words from your recovery phrase to confirm you wrote it down.")
            public static func wordPlaceholder(_ p1: Any) -> String {
                return L10n.tr("Localizable", "nighthawk.recoveryPhraseDisplay.wordPlaceholder", String(describing: p1), fallback: "Word #%@")
            }
            public static func wordMismatch(_ p1: Any) -> String {
                return L10n.tr("Localizable", "nighthawk.recoveryPhraseDisplay.wordMismatch", String(describing: p1), fallback: "Word #%@ does not match")
            }
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
            /// Change backend server
            public static let changeServerSubtitle = L10n.tr("Localizable", "nighthawk.settingsTab.changeServerSubtitle", fallback: "Change backend server")
            /// Change server
            public static let changeServerTitle = L10n.tr("Localizable", "nighthawk.settingsTab.changeServerTitle", fallback: "Change server")
            /// E2E encryption, DAG sync, embedded darkirc
            public static let chatSettingsSubtitle = L10n.tr("Localizable", "nighthawk.settingsTab.chatSettingsSubtitle", fallback: "E2E encryption, DAG sync, embedded darkirc")
            /// Chat Settings
            public static let chatSettingsTitle = L10n.tr("Localizable", "nighthawk.settingsTab.chatSettingsTitle", fallback: "Chat Settings")
            /// Wallet over Nym, Tor or direct; chat over Tor
            public static let networkPrivacySubtitle = L10n.tr("Localizable", "nighthawk.settingsTab.networkPrivacySubtitle", fallback: "Wallet over Nym, Tor or direct; chat over Tor")
            /// Network privacy
            public static let networkPrivacyTitle = L10n.tr("Localizable", "nighthawk.settingsTab.networkPrivacyTitle", fallback: "Network privacy")
            /// Select a setting on the left to open it.
            public static let selectSettingPrompt = L10n.tr("Localizable", "nighthawk.settingsTab.selectSettingPrompt", fallback: "Select a setting on the left to open it.")
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
            public static func securityBiometricsAndPin(_ p1: Any) -> String {
                return L10n.tr("Localizable", "nighthawk.settingsTab.securityBiometricsAndPin", String(describing: p1), fallback: "%@ & 6-digit PIN")
            }
            public static let securityPinOnly = L10n.tr("Localizable", "nighthawk.settingsTab.securityPinOnly", fallback: "6-digit App PIN")
            public static let shareTitle = L10n.tr("Localizable", "nighthawk.settingsTab.shareTitle", fallback: "Share Nighthawk")
            public static let shareSubtitle = L10n.tr("Localizable", "nighthawk.settingsTab.shareSubtitle", fallback: "Invite friends to Nighthawk Wallet")
            public static let shareSubject = L10n.tr("Localizable", "nighthawk.settingsTab.shareSubject", fallback: "Nighthawk Wallet")
            public static let shareMessage = L10n.tr("Localizable", "nighthawk.settingsTab.shareMessage", fallback: "Private DarkFi wallet & encrypted DarkIRC chat — Nighthawk Wallet")
            public enum Advanced {
                /// Advanced settings
                public static let title = L10n.tr("Localizable", "nighthawk.settingsTab.advanced.title", fallback: "Advanced settings")
                public enum Mesh {
                    public static let title = L10n.tr("Localizable", "nighthawk.settingsTab.advanced.mesh.title", fallback: "Nearby mesh")
                    public static let subtitle = L10n.tr("Localizable", "nighthawk.settingsTab.advanced.mesh.subtitle", fallback: "Relay DarkIRC with nearby Nighthawk phones over Bluetooth. Share-internet stays off.")
                }
                public enum UnifOmr {
                    public static let title = L10n.tr("Localizable", "nighthawk.settingsTab.advanced.unifOmr.title", fallback: "Experimental UnifOMR")
                    public static let subtitle = L10n.tr("Localizable", "nighthawk.settingsTab.advanced.unifOmr.subtitle", fallback: "Off is the default. Trial decryption finds every payment, including ones from Dark Wallet or another server. On is experimental: both wallets must register on this same lightwalletd first, or funds can stay invisible. It also uploads a large detection key.")
                }
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
                    public static let subtitle = L10n.tr("Localizable", "nighthawk.settingsTab.advanced.deleteWallet.subtitle", fallback: "CAUTION: Completely nukes this wallet — seed words, SQLCipher pass, and on-device databases. You cannot recover funds without your seed. Close and relaunch the app before creating or restoring a wallet.")
                    /// Nuke wallet
                    public static let title = L10n.tr("Localizable", "nighthawk.settingsTab.advanced.deleteWallet.title", fallback: "Nuke wallet")
                    public enum Alert {
                        public enum LastWarning {
                            /// This operation is IRREVERSIBLE. Restoring your funds will be impossible without your seed words. Be ABSOLUTELY sure you have them saved somewhere safe before proceeding. Do you still want to proceed?
                            public static let message = L10n.tr("Localizable", "nighthawk.settingsTab.advanced.deleteWallet.alert.lastWarning.message", fallback: "This operation is IRREVERSIBLE. Restoring your funds will be impossible without your seed words. Be ABSOLUTELY sure you have them saved somewhere safe before proceeding. Do you still want to proceed?")
                            /// ARE YOU SURE?
                            public static let title = L10n.tr("Localizable", "nighthawk.settingsTab.advanced.deleteWallet.alert.lastWarning.title", fallback: "ARE YOU SURE?")
                        }
                        public enum RelaunchRequired {
                            /// I confirm, nuke wallet
                            public static let confirm = L10n.tr("Localizable", "nighthawk.settingsTab.advanced.deleteWallet.alert.relaunchRequired.confirm", fallback: "I confirm, nuke wallet")
                            /// Nuking the wallet is an extremely sensitive operation. So sensitive, in fact, that you must manually close the app and restart Nighthawk before creating a new wallet or restoring a wallet.
                            public static let message = L10n.tr("Localizable", "nighthawk.settingsTab.advanced.deleteWallet.alert.relaunchRequired.message", fallback: "Nuking the wallet is an extremely sensitive operation. So sensitive, in fact, that you must manually close the app and restart Nighthawk before creating a new wallet or restoring a wallet.")
                            /// FINAL WARNING
                            public static let title = L10n.tr("Localizable", "nighthawk.settingsTab.advanced.deleteWallet.alert.relaunchRequired.title", fallback: "FINAL WARNING")
                        }
                    }
                }
                public enum NukeLocalDatabases {
                    /// Delete local databases
                    public static let title = L10n.tr("Localizable", "nighthawk.settingsTab.advanced.nukeLocalDatabases.title", fallback: "Delete local databases")
                    /// Removes the on-device wallet DB and sync cache only. Your seed words stay in Keychain so you can reopen and rescan. Use this after a native upgrade that cannot open an older database.
                    public static let subtitle = L10n.tr("Localizable", "nighthawk.settingsTab.advanced.nukeLocalDatabases.subtitle", fallback: "Removes the on-device wallet DB and sync cache only. Your seed words stay in Keychain so you can reopen and rescan. Use this after a native upgrade that cannot open an older database.")
                    public enum Alert {
                        /// Delete local databases?
                        public static let title = L10n.tr("Localizable", "nighthawk.settingsTab.advanced.nukeLocalDatabases.alert.title", fallback: "Delete local databases?")
                        /// This deletes darkfi_wallet.db and darkfi_cache on this device. Your recovery phrase is kept. The wallet will reopen and rescan from the network.
                        public static let message = L10n.tr("Localizable", "nighthawk.settingsTab.advanced.nukeLocalDatabases.alert.message", fallback: "This deletes darkfi_wallet.db and darkfi_cache on this device. Your recovery phrase is kept. The wallet will reopen and rescan from the network.")
                        /// Delete databases
                        public static let confirm = L10n.tr("Localizable", "nighthawk.settingsTab.advanced.nukeLocalDatabases.alert.confirm", fallback: "Delete databases")
                        public enum Success {
                            /// Local databases cleared
                            public static let title = L10n.tr("Localizable", "nighthawk.settingsTab.advanced.nukeLocalDatabases.alert.success.title", fallback: "Local databases cleared")
                            /// Wallet data was removed. Reopening from your seed and starting a fresh scan.
                            public static let message = L10n.tr("Localizable", "nighthawk.settingsTab.advanced.nukeLocalDatabases.alert.success.message", fallback: "Wallet data was removed. Reopening from your seed and starting a fresh scan.")
                        }
                        public enum Failed {
                            /// Could not delete local databases
                            public static let title = L10n.tr("Localizable", "nighthawk.settingsTab.advanced.nukeLocalDatabases.alert.failed.title", fallback: "Could not delete local databases")
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
                    /// Cyberpunk
                    public static let cyberpunk = L10n.tr("Localizable", "nighthawk.settingsTab.advanced.theme.cyberpunk", fallback: "Cyberpunk")
                    /// enter nighthawk with style
                    public static let cyberpunkDetail = L10n.tr("Localizable", "nighthawk.settingsTab.advanced.theme.cyberpunkDetail", fallback: "enter nighthawk with style")
                    /// Dark
                    public static let dark = L10n.tr("Localizable", "nighthawk.settingsTab.advanced.theme.dark", fallback: "Dark")
                    /// Default
                    public static let `default` = L10n.tr("Localizable", "nighthawk.settingsTab.advanced.theme.default", fallback: "System (Cyberpunk)")
                    /// Light
                    public static let light = L10n.tr("Localizable", "nighthawk.settingsTab.advanced.theme.light", fallback: "Light")
                    /// Mist neutrals with a graphite accent.
                    public static let lightDetail = L10n.tr("Localizable", "nighthawk.settingsTab.advanced.theme.lightDetail", fallback: "Mist neutrals with a graphite accent.")
                    /// Midnight
                    public static let midnight = L10n.tr("Localizable", "nighthawk.settingsTab.advanced.theme.midnight", fallback: "Midnight")
                    /// Deeper base with a violet accent.
                    public static let midnightDetail = L10n.tr("Localizable", "nighthawk.settingsTab.advanced.theme.midnightDetail", fallback: "Deeper base with a violet accent.")
                    /// Paper
                    public static let paper = L10n.tr("Localizable", "nighthawk.settingsTab.advanced.theme.paper", fallback: "Paper")
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
                /// Custom servers are not operated by Nighthawk. We recommend using Tor for enhanced privacy when making transactions.
                public static let disclaimer = L10n.tr("Localizable", "nighthawk.settingsTab.changeServer.disclaimer", fallback: "Custom servers are not operated by Nighthawk. We recommend using Tor for enhanced privacy when making transactions.")
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
                        /// Unable to change server
                        public static let title = L10n.tr("Localizable", "nighthawk.settingsTab.changeServer.alert.changeServerFailed.title", fallback: "Unable to change server")
                    }
                }
                public enum Custom {
                    /// Error ⸱ This doesn't look like a valid server address
                    public static let invalidLightwalletd = L10n.tr("Localizable", "nighthawk.settingsTab.changeServer.custom.invalidLightwalletd", fallback: "Error ⸱ This doesn't look like a valid server address")
                }
                public static let placeholder = L10n.tr("Localizable", "nighthawk.settingsTab.changeServer.placeholder", fallback: "https://host:443 or 127.0.0.1:9067")
                public static let useTlsTitle = L10n.tr("Localizable", "nighthawk.settingsTab.changeServer.useTlsTitle", fallback: "Use TLS (HTTPS)")
                public static let useTlsSubtitle = L10n.tr("Localizable", "nighthawk.settingsTab.changeServer.useTlsSubtitle", fallback: "Required for remote servers; pinned by SHA-256 certificate digest.")
                public static let presets = L10n.tr("Localizable", "nighthawk.settingsTab.changeServer.presets", fallback: "Presets")
                public static let presetTestnet = L10n.tr("Localizable", "nighthawk.settingsTab.changeServer.presetTestnet", fallback: "Nighthawk Testnet (HTTPS)")
                public static let presetLocal = L10n.tr("Localizable", "nighthawk.settingsTab.changeServer.presetLocal", fallback: "Local Lightwalletd")
                public static let portWarningTitle = L10n.tr("Localizable", "nighthawk.settingsTab.changeServer.portWarningTitle", fallback: "Non-Standard Port")
                public static let portWarningUseAnyway = L10n.tr("Localizable", "nighthawk.settingsTab.changeServer.portWarningUseAnyway", fallback: "Use Anyway")
                public static let portWarningMessage = L10n.tr("Localizable", "nighthawk.settingsTab.changeServer.portWarningMessage", fallback: "The port you entered is not a standard DarkFi lightwallet port (9067 or 443 for TLS). Using a non-standard port may prevent sync.")
            }
            public enum ChatSettings {
                public static let fileOffersSection = L10n.tr("Localizable", "nighthawk.settingsTab.chatSettings.fileOffersSection", fallback: "FILE OFFERS")
                public static let allowFudTitle = L10n.tr("Localizable", "nighthawk.settingsTab.chatSettings.allowFudTitle", fallback: "Allow fud:// file offers")
                public static let allowFudSubtitle = L10n.tr("Localizable", "nighthawk.settingsTab.chatSettings.allowFudSubtitle", fallback: "A tap queues the offer on this phone. It is sent only over Nym, Tor, or nearby mesh, and the file is not downloaded automatically.")
                public static let embeddedNodeSection = L10n.tr("Localizable", "nighthawk.settingsTab.chatSettings.embeddedNodeSection", fallback: "EMBEDDED NODE SYNC")
                public static let useEmbeddedTitle = L10n.tr("Localizable", "nighthawk.settingsTab.chatSettings.useEmbeddedTitle", fallback: "Use embedded darkirc")
                public static let useEmbeddedSubtitle = L10n.tr("Localizable", "nighthawk.settingsTab.chatSettings.useEmbeddedSubtitle", fallback: "Run darkirc inside the app")
                public static let dagHistoryTitle = L10n.tr("Localizable", "nighthawk.settingsTab.chatSettings.dagHistoryTitle", fallback: "DAG history hours (1–24)")
                public static let dagHistorySubtitle = L10n.tr("Localizable", "nighthawk.settingsTab.chatSettings.dagHistorySubtitle", fallback: "Each DAG is about one hour of channel history. Default is 8 (upstream darkirc).")
                public static let fastSyncTitle = L10n.tr("Localizable", "nighthawk.settingsTab.chatSettings.fastSyncTitle", fallback: "Fast sync (header-only)")
                public static let fastSyncSubtitle = L10n.tr("Localizable", "nighthawk.settingsTab.chatSettings.fastSyncSubtitle", fallback: "Matches upstream fast_mod: quicker DAG sync with less history fetch.")
                public static let channelPrivacySection = L10n.tr("Localizable", "nighthawk.settingsTab.chatSettings.channelPrivacySection", fallback: "CHANNEL PRIVACY")
                public static let channelPrivacyBody = L10n.tr("Localizable", "nighthawk.settingsTab.chatSettings.channelPrivacyBody", fallback: "Public #channels are plaintext on DarkIRC. Only 1:1 DMs use ChaChaBox end-to-end encryption. Group/channel E2E is not available yet.")
                public static let encryptedContactsSection = L10n.tr("Localizable", "nighthawk.settingsTab.chatSettings.encryptedContactsSection", fallback: "ENCRYPTED CONTACTS (DM)")
                public static let yourPublicKey = L10n.tr("Localizable", "nighthawk.settingsTab.chatSettings.yourPublicKey", fallback: "Your public key (share with contact):")
                public static let safetyNumber = L10n.tr("Localizable", "nighthawk.settingsTab.chatSettings.safetyNumber", fallback: "Safety number")
                public static let generateDmKeys = L10n.tr("Localizable", "nighthawk.settingsTab.chatSettings.generateDmKeys", fallback: "Generate my DM keys")
                public static let noContacts = L10n.tr("Localizable", "nighthawk.settingsTab.chatSettings.noContacts", fallback: "No encrypted contacts configured.")
                public static let remove = L10n.tr("Localizable", "nighthawk.settingsTab.chatSettings.remove", fallback: "Remove")
                public static let addContact = L10n.tr("Localizable", "nighthawk.settingsTab.chatSettings.addContact", fallback: "Add encrypted contact")
                public static let applyReconnect = L10n.tr("Localizable", "nighthawk.settingsTab.chatSettings.applyReconnect", fallback: "Apply & reconnect")
                public static let inviteQrTitle = L10n.tr("Localizable", "nighthawk.settingsTab.chatSettings.inviteQrTitle", fallback: "Contact Invite QR (nighthawk://contact)")
                public static let copyInviteUri = L10n.tr("Localizable", "nighthawk.settingsTab.chatSettings.copyInviteUri", fallback: "Copy contact invite URI")
                public static let pasteInvitePlaceholder = L10n.tr("Localizable", "nighthawk.settingsTab.chatSettings.pasteInvitePlaceholder", fallback: "Paste nighthawk://contact?... invite")
                public static let fill = L10n.tr("Localizable", "nighthawk.settingsTab.chatSettings.fill", fallback: "Fill")
                public static let nickname = L10n.tr("Localizable", "nighthawk.settingsTab.chatSettings.nickname", fallback: "Nickname")
                public static let peerDmPubkeyPlaceholder = L10n.tr("Localizable", "nighthawk.settingsTab.chatSettings.peerDmPubkeyPlaceholder", fallback: "Peer DM public key (Base58)")
                public static let myDmSecretPlaceholder = L10n.tr("Localizable", "nighthawk.settingsTab.chatSettings.myDmSecretPlaceholder", fallback: "My DM secret key (Base58)")
                public static let generateKeypair = L10n.tr("Localizable", "nighthawk.settingsTab.chatSettings.generateKeypair", fallback: "Generate my DM keypair")
                public static func myPublicKeyValue(_ p1: Any) -> String {
                    return L10n.tr("Localizable", "nighthawk.settingsTab.chatSettings.myPublicKeyValue", String(describing: p1), fallback: "My public key: %@")
                }
                public static let walletAddressOptional = L10n.tr("Localizable", "nighthawk.settingsTab.chatSettings.walletAddressOptional", fallback: "DarkFi wallet address (optional)")
                public static let addContactButton = L10n.tr("Localizable", "nighthawk.settingsTab.chatSettings.addContactButton", fallback: "Add contact")
                public static let addContactSheetTitle = L10n.tr("Localizable", "nighthawk.settingsTab.chatSettings.addContactSheetTitle", fallback: "Add Encrypted Contact")
                public static let errorInvalidInvite = L10n.tr("Localizable", "nighthawk.settingsTab.chatSettings.errorInvalidInvite", fallback: "Unrecognized invite URI. Expected nighthawk://contact?... or drk:...")
                public static let errorInvalidNick = L10n.tr("Localizable", "nighthawk.settingsTab.chatSettings.errorInvalidNick", fallback: "Enter a valid contact nickname (cannot start with #).")
                public static let errorInvalidDmKeys = L10n.tr("Localizable", "nighthawk.settingsTab.chatSettings.errorInvalidDmKeys", fallback: "Provide valid 32-byte Base58 DM keys.")
                public static let errorMissingContactData = L10n.tr("Localizable", "nighthawk.settingsTab.chatSettings.errorMissingContactData", fallback: "Enter DM keys or a DarkFi wallet address.")
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
                public static let biometricsTitle = L10n.tr("Localizable", "nighthawk.settingsTab.security.biometricsTitle", fallback: "Biometrics")
                public static let biometricsUnavailable = L10n.tr("Localizable", "nighthawk.settingsTab.security.biometricsUnavailable", fallback: "Face ID / Touch ID is not configured on this device. You can still protect the wallet with a 6-digit App PIN below.")
                public static let pinTitle = L10n.tr("Localizable", "nighthawk.settingsTab.security.pinTitle", fallback: "App PIN (6-digit)")
                public static let pinEnabled = L10n.tr("Localizable", "nighthawk.settingsTab.security.pinEnabled", fallback: "Enabled")
                public static let pinOff = L10n.tr("Localizable", "nighthawk.settingsTab.security.pinOff", fallback: "Off")
                public static let pinDescription = L10n.tr("Localizable", "nighthawk.settingsTab.security.pinDescription", fallback: "Locks wallet launch and resume after 10 minutes away. Stored in Keychain as a salted PBKDF2-SHA256 hash.")
                public static let pinChange = L10n.tr("Localizable", "nighthawk.settingsTab.security.pinChange", fallback: "Change PIN")
                public static let pinVerify = L10n.tr("Localizable", "nighthawk.settingsTab.security.pinVerify", fallback: "Verify PIN")
                public static let pinDisable = L10n.tr("Localizable", "nighthawk.settingsTab.security.pinDisable", fallback: "Disable PIN")
                public static let pinSet = L10n.tr("Localizable", "nighthawk.settingsTab.security.pinSet", fallback: "Set 6-digit PIN")
                public static let pinConfirm = L10n.tr("Localizable", "nighthawk.settingsTab.security.pinConfirm", fallback: "Confirm")
                public static let pinPromptSetupEnter = L10n.tr("Localizable", "nighthawk.settingsTab.security.pinPromptSetupEnter", fallback: "Enter a new 6-digit PIN")
                public static let pinPromptSetupConfirm = L10n.tr("Localizable", "nighthawk.settingsTab.security.pinPromptSetupConfirm", fallback: "Re-enter your 6-digit PIN to confirm")
                public static let pinPromptChangeCurrent = L10n.tr("Localizable", "nighthawk.settingsTab.security.pinPromptChangeCurrent", fallback: "Enter your current 6-digit PIN")
                public static let pinPromptChangeNew = L10n.tr("Localizable", "nighthawk.settingsTab.security.pinPromptChangeNew", fallback: "Enter your new 6-digit PIN")
                public static let pinPromptChangeConfirm = L10n.tr("Localizable", "nighthawk.settingsTab.security.pinPromptChangeConfirm", fallback: "Re-enter your new 6-digit PIN")
                public static let pinPromptDisable = L10n.tr("Localizable", "nighthawk.settingsTab.security.pinPromptDisable", fallback: "Enter your current PIN to disable")
                public static let pinPromptVerify = L10n.tr("Localizable", "nighthawk.settingsTab.security.pinPromptVerify", fallback: "Enter your 6-digit PIN to verify")
                public static func pinErrorDigits(_ p1: Any) -> String {
                    return L10n.tr("Localizable", "nighthawk.settingsTab.security.pinErrorDigits", String(describing: p1), fallback: "Enter exactly %@ digits.")
                }
                public static let pinErrorNewMismatch = L10n.tr("Localizable", "nighthawk.settingsTab.security.pinErrorNewMismatch", fallback: "New PINs did not match. Try again.")
                public static let pinErrorMismatch = L10n.tr("Localizable", "nighthawk.settingsTab.security.pinErrorMismatch", fallback: "PINs did not match. Try again.")
                public static let pinErrorUpdateKeychain = L10n.tr("Localizable", "nighthawk.settingsTab.security.pinErrorUpdateKeychain", fallback: "Could not update PIN in Keychain.")
                public static let pinErrorStoreKeychain = L10n.tr("Localizable", "nighthawk.settingsTab.security.pinErrorStoreKeychain", fallback: "Could not store PIN in Keychain.")
                public static let pinErrorCurrentIncorrect = L10n.tr("Localizable", "nighthawk.settingsTab.security.pinErrorCurrentIncorrect", fallback: "Incorrect current PIN.")
                public static let pinErrorIncorrect = L10n.tr("Localizable", "nighthawk.settingsTab.security.pinErrorIncorrect", fallback: "Incorrect PIN.")
                public static func pinErrorLockedOut(_ p1: Any) -> String {
                    return L10n.tr("Localizable", "nighthawk.settingsTab.security.pinErrorLockedOut", String(describing: p1), fallback: "Too many attempts. Try again in %@.")
                }
                public static let pinStatusUpdated = L10n.tr("Localizable", "nighthawk.settingsTab.security.pinStatusUpdated", fallback: "App PIN updated.")
                public static let pinStatusEnabled = L10n.tr("Localizable", "nighthawk.settingsTab.security.pinStatusEnabled", fallback: "6-digit App PIN enabled.")
                public static let pinStatusDisabled = L10n.tr("Localizable", "nighthawk.settingsTab.security.pinStatusDisabled", fallback: "App PIN disabled.")
                public static let pinStatusVerified = L10n.tr("Localizable", "nighthawk.settingsTab.security.pinStatusVerified", fallback: "PIN verified.")
            }
            public enum TorNetwork {
                public static let intro = L10n.tr("Localizable", "nighthawk.settingsTab.torNetwork.intro", fallback: "Wallet, chat, and node traffic go over the Nym mixnet by default, which hides your IP address from servers. Chat reaches the public DarkIRC seeds through that same tunnel. Onion-only peers need Tor. The first connection usually takes a few seconds and can take up to a minute.")
                public static let walletNetworkTitle = L10n.tr("Localizable", "nighthawk.settingsTab.torNetwork.walletNetworkTitle", fallback: "Wallet network")
                public static let walletNetworkSubtitle = L10n.tr("Localizable", "nighthawk.settingsTab.torNetwork.walletNetworkSubtitle", fallback: "Used for lightwalletd sync and transaction broadcast. Changing it reconnects the wallet.")
                public static func nymStatus(_ p1: Any) -> String {
                    return L10n.tr("Localizable", "nighthawk.settingsTab.torNetwork.nymStatus", String(describing: p1), fallback: "Nym: %@")
                }
                public static let nymTitle = L10n.tr("Localizable", "nighthawk.settingsTab.torNetwork.nymTitle", fallback: "Nym mixnet (recommended)")
                public static let nymSubtitle = L10n.tr("Localizable", "nighthawk.settingsTab.torNetwork.nymSubtitle", fallback: "Mixes packets across five hops. Chat uses the clearnet seeds through the mixnet. Cannot reach .onion addresses.")
                public static let torTitle = L10n.tr("Localizable", "nighthawk.settingsTab.torNetwork.torTitle", fallback: "Tor")
                public static let torSubtitle = L10n.tr("Localizable", "nighthawk.settingsTab.torNetwork.torSubtitle", fallback: "Onion routing through built-in Arti or the SOCKS endpoint below.")
                public static let directTitle = L10n.tr("Localizable", "nighthawk.settingsTab.torNetwork.directTitle", fallback: "Direct")
                public static let directSubtitle = L10n.tr("Localizable", "nighthawk.settingsTab.torNetwork.directSubtitle", fallback: "Connects straight to the server. It sees your IP address.")
                public static let builtInTorTitle = L10n.tr("Localizable", "nighthawk.settingsTab.torNetwork.builtInTorTitle", fallback: "Built-in Tor (Arti)")
                public static let builtInTorSubtitle = L10n.tr("Localizable", "nighthawk.settingsTab.torNetwork.builtInTorSubtitle", fallback: "Runs Arti (Rust Tor) inside the app and exposes a loopback SOCKS listener. This is separate from an external Tor/SOCKS app you configure below.")
                public static let useBuiltInArti = L10n.tr("Localizable", "nighthawk.settingsTab.torNetwork.useBuiltInArti", fallback: "Use built-in Arti")
                public static let enableTorHint = L10n.tr("Localizable", "nighthawk.settingsTab.torNetwork.enableTorHint", fallback: "Enable app-wide Tor routing above to use built-in Arti.")
                public static let socksEndpointTitle = L10n.tr("Localizable", "nighthawk.settingsTab.torNetwork.socksEndpointTitle", fallback: "SOCKS endpoint")
                public static let socksDescriptionEmbedded = L10n.tr("Localizable", "nighthawk.settingsTab.torNetwork.socksDescriptionEmbedded", fallback: "Loopback address where built-in Arti listens (default 127.0.0.1:9050). Embedded DarkIRC uses this proxy for .onion P2P seeds.")
                public static let socksDescriptionExternal = L10n.tr("Localizable", "nighthawk.settingsTab.torNetwork.socksDescriptionExternal", fallback: "Host and port of your external Tor or SOCKS proxy. Required when built-in Arti is off.")
                public static let socksHost = L10n.tr("Localizable", "nighthawk.settingsTab.torNetwork.socksHost", fallback: "SOCKS host")
                public static let socksPort = L10n.tr("Localizable", "nighthawk.settingsTab.torNetwork.socksPort", fallback: "SOCKS port")
                public static let footer = L10n.tr("Localizable", "nighthawk.settingsTab.torNetwork.footer", fallback: "Changing built-in Tor or SOCKS restarts embedded DarkIRC when enabled so P2P/event-graph transport matches. Open Chat to verify green status lights.")
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
            public static let enterAppPin = L10n.tr("Localizable", "nighthawk.splash.enterAppPin", fallback: "Enter App PIN")
            public static let sixDigitPin = L10n.tr("Localizable", "nighthawk.splash.sixDigitPin", fallback: "6-digit PIN")
            public static let unlock = L10n.tr("Localizable", "nighthawk.splash.unlock", fallback: "Unlock")
            public static let pinErrorLength = L10n.tr("Localizable", "nighthawk.splash.pinErrorLength", fallback: "Enter your 6-digit PIN.")
            public static let pinErrorIncorrect = L10n.tr("Localizable", "nighthawk.splash.pinErrorIncorrect", fallback: "Incorrect PIN. Try again.")
            public static func pinErrorLockedOut(_ p1: Any) -> String {
                return L10n.tr("Localizable", "nighthawk.splash.pinErrorLockedOut", String(describing: p1), fallback: "Too many attempts. Try again in %@.")
            }
            public static let nymFailed = L10n.tr("Localizable", "nighthawk.splash.nymFailed", fallback: "Nym mixnet connection failed")
            public static func nymConnecting(_ p1: Any) -> String {
                return L10n.tr("Localizable", "nighthawk.splash.nymConnecting", String(describing: p1), fallback: "Connecting to the Nym mixnet… %@ s")
            }
            public static let nymSlow = L10n.tr("Localizable", "nighthawk.splash.nymSlow", fallback: "Taking longer than usual. Keep waiting, or continue without Nym.")
            public static let continueWithoutNym = L10n.tr("Localizable", "nighthawk.splash.continueWithoutNym", fallback: "Continue without Nym")
            public static let nymSessionHint = L10n.tr("Localizable", "nighthawk.splash.nymSessionHint", fallback: "Wallet and chat use your regular network for this session. You can switch back to Nym in Settings.")
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
            /// Recipient
            public static let recipient = L10n.tr("Localizable", "nighthawk.transactionDetails.recipient", fallback: "Recipient")
            /// Private
            public static let recipientShielded = L10n.tr("Localizable", "nighthawk.transactionDetails.recipientShielded", fallback: "Private")
            /// Private
            public static let recipientTransparent = L10n.tr("Localizable", "nighthawk.transactionDetails.recipientTransparent", fallback: "Private")
            /// Reply-to address copied!
            public static let replyToCopied = L10n.tr("Localizable", "nighthawk.transactionDetails.replyToCopied", fallback: "Reply-to address copied!")
            /// Sync method
            public static let syncMethod = L10n.tr("Localizable", "nighthawk.transactionDetails.syncMethod", fallback: "Sync method")
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
            /// Private funds
            public static let autoshieldedFunds = L10n.tr("Localizable", "nighthawk.transactionHistory.autoshieldedFunds", fallback: "Private funds")
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
            /// Send and receive DarkFi
            public static let sendAndReceiveDarkFi = L10n.tr("Localizable", "nighthawk.transferTab.sendAndReceiveDarkFi", fallback: "Send and receive DarkFi")
            /// Scan someone's QR code to send them money.
            public static let sendMoneyDescription = L10n.tr("Localizable", "nighthawk.transferTab.sendMoneyDescription", fallback: "Scan someone's QR code to send them money.")
            /// Send money
            public static let sendMoneyTitle = L10n.tr("Localizable", "nighthawk.transferTab.sendMoneyTitle", fallback: "Send money")
            /// Securely buy DarkFi through our partners.
            public static let topUpWalletDescription = L10n.tr("Localizable", "nighthawk.transferTab.topUpWalletDescription", fallback: "Securely buy DarkFi through our partners.")
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
                ///
                public static let copyNonPrivateAddressDescription = L10n.tr("Localizable", "nighthawk.transferTab.receive.copyNonPrivateAddressDescription", fallback: "")
                ///
                public static let copyNonPrivateAddressTitle = L10n.tr("Localizable", "nighthawk.transferTab.receive.copyNonPrivateAddressTitle", fallback: "")
                /// Your wallet address will be copied to the clipboard.
                public static let copyAddressDescription = L10n.tr("Localizable", "nighthawk.transferTab.receive.copyAddressDescription", fallback: "Your wallet address will be copied to the clipboard.")
                /// Copy privacy address
                public static let copyAddressTitle = L10n.tr("Localizable", "nighthawk.transferTab.receive.copyAddressTitle", fallback: "Copy privacy address")
                ///
                public static let receiveMoneyPublicly = L10n.tr("Localizable", "nighthawk.transferTab.receive.receiveMoneyPublicly", fallback: "")
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
                /// Sending to TEX addresses is not supported because they offer lower privacy protections
                public static let currentlyUnsupported = L10n.tr("Localizable", "nighthawk.transferTab.recipient.currentlyUnsupported", fallback: "Sending to TEX addresses is not supported because they offer lower privacy protections")
                /// Please enter a valid recipient
                public static let invalid = L10n.tr("Localizable", "nighthawk.transferTab.recipient.invalid", fallback: "Please enter a valid recipient")
                /// Paste from clipboard
                public static let pasteFromClipboard = L10n.tr("Localizable", "nighthawk.transferTab.recipient.pasteFromClipboard", fallback: "Paste from clipboard")
            }
            public enum Review {
                /// Send DarkFi
                public static let send = L10n.tr("Localizable", "nighthawk.transferTab.review.send", fallback: "Send DarkFi")
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
                public static let drkNative = L10n.tr("Localizable", "nighthawk.transferTab.send.drkNative", fallback: "DRK (native)")
                public static let tokenLabel = L10n.tr("Localizable", "nighthawk.transferTab.send.tokenLabel", fallback: "Token:")
                public enum Toast {
                    /// Not enough DRK!
                    public static let notEnoughDrk = L10n.tr("Localizable", "nighthawk.transferTab.send.toast.notEnoughDrk", fallback: "Not enough DRK!")
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
                /// Swap coins without limits.
                public static let stealthExIoDescription = L10n.tr("Localizable", "nighthawk.transferTab.topUpWallet.stealthExIoDescription", fallback: "Swap coins without limits.")
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
        public enum WalletCompanion {
            /// Block %@
            public static func blockHeight(_ p1: Any) -> String {
                return L10n.tr("Localizable", "nighthawk.walletCompanion.blockHeight", String(describing: p1), fallback: "Block %@")
            }
            /// Copy memo
            public static let copyMemo = L10n.tr("Localizable", "nighthawk.walletCompanion.copyMemo", fallback: "Copy memo")
            /// Copy TxID
            public static let copyTxId = L10n.tr("Localizable", "nighthawk.walletCompanion.copyTxId", fallback: "Copy TxID")
            /// Next steps
            public static let nextSteps = L10n.tr("Localizable", "nighthawk.walletCompanion.nextSteps", fallback: "Next steps")
            /// Receive
            public static let receive = L10n.tr("Localizable", "nighthawk.walletCompanion.receive", fallback: "Receive")
            /// Send Again
            public static let sendAgain = L10n.tr("Localizable", "nighthawk.walletCompanion.sendAgain", fallback: "Send Again")
            /// Transfers stay shielded. Trial decryption is the default. Experimental UnifOMR is opt-in in Advanced settings and needs an fhe-omr lightwalletd.
            public static let shieldedNote = L10n.tr("Localizable", "nighthawk.walletCompanion.shieldedNote", fallback: "Transfers stay shielded. Trial decryption is the default. Experimental UnifOMR is opt-in in Advanced settings and needs an fhe-omr lightwalletd.")
            /// Synced with UnifOMR.
            public static let syncedUnifOmr = L10n.tr("Localizable", "nighthawk.walletCompanion.syncedUnifOmr", fallback: "Synced with UnifOMR.")
            /// Trial decryption is active instead of UnifOMR.
            public static let trialActive = L10n.tr("Localizable", "nighthawk.walletCompanion.trialActive", fallback: "Trial decryption is active instead of UnifOMR.")
            /// Trial decrypt
            public static let trialDecrypt = L10n.tr("Localizable", "nighthawk.walletCompanion.trialDecrypt", fallback: "Trial decrypt")
            /// UnifOMR
            public static let unifOmr = L10n.tr("Localizable", "nighthawk.walletCompanion.unifOmr", fallback: "UnifOMR")
            /// Waiting for a block height
            public static let waitingForHeight = L10n.tr("Localizable", "nighthawk.walletCompanion.waitingForHeight", fallback: "Waiting for a block height")
        }
        public enum WalletTab {
            /// DRK
            public static let drk = L10n.tr("Localizable", "nighthawk.walletTab.drk", fallback: "DRK")
            /// Receive
            public static let actionReceive = L10n.tr("Localizable", "nighthawk.walletTab.actionReceive", fallback: "Receive")
            /// Request
            public static let actionRequest = L10n.tr("Localizable", "nighthawk.walletTab.actionRequest", fallback: "Request")
            /// Send
            public static let actionSend = L10n.tr("Localizable", "nighthawk.walletTab.actionSend", fallback: "Send")
            /// Recent activity
            public static let recentActivity = L10n.tr("Localizable", "nighthawk.walletTab.recentActivity", fallback: "Recent activity")
            /// Private balance
            public static let shieldedBalance = L10n.tr("Localizable", "nighthawk.walletTab.shieldedBalance", fallback: "Private balance")
            /// Refresh
            public static let shieldNow = L10n.tr("Localizable", "nighthawk.walletTab.shieldNow", fallback: "Refresh")
            /// Swipe left to show your balance
            public static let swipeToShowBalances = L10n.tr("Localizable", "nighthawk.walletTab.swipeToShowBalances", fallback: "Swipe left to show your balance")
            /// Total balance
            public static let totalBalance = L10n.tr("Localizable", "nighthawk.walletTab.totalBalance", fallback: "Total balance")
            /// Private balance
            public static let transparentBalance = L10n.tr("Localizable", "nighthawk.walletTab.transparentBalance", fallback: "Private balance")
            /// View transaction history
            public static let viewTransactionHistory = L10n.tr("Localizable", "nighthawk.walletTab.viewTransactionHistory", fallback: "View transaction history")
            public static let syncStale = L10n.tr("Localizable", "nighthawk.walletTab.syncStale", fallback: "Lightwalletd stale or unreachable")
            public static func syncedBlock(_ p1: Any) -> String {
                return L10n.tr("Localizable", "nighthawk.walletTab.syncedBlock", String(describing: p1), fallback: "Synced · Block %@")
            }
            public static func syncingBlock(_ p1: Any, _ p2: Any) -> String {
                return L10n.tr("Localizable", "nighthawk.walletTab.syncingBlock", String(describing: p1), String(describing: p2), fallback: "Syncing %@%% · Block %@")
            }
            public static func syncingPercent(_ p1: Any) -> String {
                return L10n.tr("Localizable", "nighthawk.walletTab.syncingPercent", String(describing: p1), fallback: "Syncing %@%%")
            }
            public static let syncError = L10n.tr("Localizable", "nighthawk.walletTab.syncError", fallback: "Sync Error")
            public static let syncStopped = L10n.tr("Localizable", "nighthawk.walletTab.syncStopped", fallback: "Sync Stopped")
            public static let unreachableBanner = L10n.tr("Localizable", "nighthawk.walletTab.unreachableBanner", fallback: "Lightwalletd unreachable — check Change Server or Network privacy.")
            public static let reorgTitle = L10n.tr("Localizable", "nighthawk.walletTab.reorgTitle", fallback: "Chain Reorg Recovery")
            public static let tokens = L10n.tr("Localizable", "nighthawk.walletTab.tokens", fallback: "Tokens")
            public static let tapToSend = L10n.tr("Localizable", "nighthawk.walletTab.tapToSend", fallback: "Tap to send")
            public enum Addresses {
                /// Copied to clipboard!
                public static let copiedToClipboard = L10n.tr("Localizable", "nighthawk.walletTab.addresses.copiedToClipboard", fallback: "Copied to clipboard!")
                /// Copy
                public static let copy = L10n.tr("Localizable", "nighthawk.walletTab.addresses.copy", fallback: "Copy")
                /// Loading…
                public static let loading = L10n.tr("Localizable", "nighthawk.walletTab.addresses.loading", fallback: "Loading…")
                /// Privacy address
                public static let receiveAddress = L10n.tr("Localizable", "nighthawk.walletTab.addresses.receiveAddress", fallback: "Privacy address")
                /// See more
                public static let seeMore = L10n.tr("Localizable", "nighthawk.walletTab.addresses.seeMore", fallback: "See more")
                /// Top up your wallet
                public static let topUpYourWallet = L10n.tr("Localizable", "nighthawk.walletTab.addresses.topUpYourWallet", fallback: "Top up your wallet")
                /// Buy or trade DarkFi through our specially selected partners.
                public static let topUpYourWalletDescription = L10n.tr("Localizable", "nighthawk.walletTab.addresses.topUpYourWalletDescription", fallback: "Buy or trade DarkFi through our specially selected partners.")
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
            /// This app is free software. Use is covered only by its license.
            public static let terms1 = L10n.tr("Localizable", "nighthawk.welcome.terms1", fallback: "This app is free software. Use is covered only by its license.")
            public enum Carousel {
                /// All transactions are fully private. No transparent addresses, no metadata leaks. Your financial life stays yours.
                public static let body1 = L10n.tr("Localizable", "nighthawk.welcome.carousel.body1", fallback: "All transactions are fully private. No transparent addresses, no metadata leaks. Your financial life stays yours.")
                /// Connect directly to the DarkFi network via Tor. No intermediary servers. No endpoints to trust.
                public static let body2 = L10n.tr("Localizable", "nighthawk.welcome.carousel.body2", fallback: "Connect directly to the DarkFi network via Tor. No intermediary servers. No endpoints to trust.")
                /// Send end-to-end encrypted messages via DarkIRC. Private communication built into your wallet.
                public static let body3 = L10n.tr("Localizable", "nighthawk.welcome.carousel.body3", fallback: "Send end-to-end encrypted messages via DarkIRC. Private communication built into your wallet.")
                /// Private by Default
                public static let title1 = L10n.tr("Localizable", "nighthawk.welcome.carousel.title1", fallback: "Private by Default")
                /// Peer-to-Peer Network
                public static let title2 = L10n.tr("Localizable", "nighthawk.welcome.carousel.title2", fallback: "Peer-to-Peer Network")
                /// Encrypted Chat
                public static let title3 = L10n.tr("Localizable", "nighthawk.welcome.carousel.title3", fallback: "Encrypted Chat")
            }
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

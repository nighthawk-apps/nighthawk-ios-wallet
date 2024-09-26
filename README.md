# Nighthawk for iOS and Apple Silicon

Privacy-preserving wallet maintained by [nighthawk apps](https://nighthawkapps.com)

### Download
<a href="https://apps.apple.com/us/app/nighthawk-wallet/id1524708337" style="display: inline-block; overflow: hidden; border-radius: 13px; width: 250px; height: 83px;"><img src="https://tools.applemediaservices.com/api/badges/download-on-the-app-store/black/en-US" alt="Download Nighthawk on the App Store" style="border-radius: 13px; width: 250px; height: 83px;"></a>

# Description

Nighthawk is an open source wallet for privacy preserving money.
As a non-custodial wallet, users have sole responsibility over its funds. Please immediately and securely back up the seed words upon creating a wallet. Nighthawk utilizes ZcashLightClientKit SDK that is maintained by ECC core developers.

## Disclosure Policy
Do not disclose any bug or vulnerability on public forums, message boards, mailing lists, etc. prior to responsibly disclosing to Nighthawk Wallet and giving sufficient time for the issue to be fixed and deployed. Do not execute on or exploit any vulnerability.

### Reporting a Bug or Vulnerability
When reporting a bug or vulnerability, please provide the following to nighthawkwallet@protonmail.com

A short summary of the potential impact of the issue (if known).
Details explaining how to reproduce the issue or how an exploit may be formed.
Your name (optional). If provided, we will provide credit for disclosure. Otherwise, you will be treated anonymously and your privacy will be respected.
Your email or other means of contacting you.
A PGP key/fingerprint for us to provide encrypted responses to your disclosure. If this is not provided, we cannot guarantee that you will receive a response prior to a fix being made and deployed.

## Encrypting the Disclosure
We highly encourage all disclosures to be encrypted to prevent interception and exploitation by third-parties prior to a fix being developed and deployed.  Please encrypt using the PGP public key with fingerprint: `8c07e1261c5d9330287f4ec35aff0fd018b01972`

## Disclaimers
There are some known areas for improvement:

- This app depends upon related libraries that it uses. There may be bugs.
- This wallet currently only supports transacting between shielded addresses, which makes it incompatible with wallets that do not support sending to shielded addresses. 
- Traffic analysis, like in other cryptocurrency wallets, can leak some privacy of the user.
- The wallet requires a trust in the lightwalletd server to display accurate transaction information. 
- This app has been developed and run exclusively on `mainnet` it might not work on `testnet`.  

See the [Wallet App Threat Model](https://zcash.readthedocs.io/en/latest/rtd_pages/wallet_threat_model.html)
for more information about the security and privacy limitations of the wallet.

# Installation of Swiftgen & Swiftlint on Apple Silicon chip

## Swiftgen
Install it using homebrew
```
$ brew install swiftgen
```
and create a symbolic link
```
ln -s /opt/homebrew/bin/swiftgen /usr/local/bin
```
## Swiftlint
The project is setup to work with `0.50.3` version. We recommend to install it directly using [the official 0.50.3 package](https://github.com/realm/SwiftLint/releases/download/0.50.3/SwiftLint.pkg). If you follow this step there is no symbolic link needed.

In case you already have swiftlint 0.50.3 ready on your machine and installed via homebrew, create a symbolic link
```
ln -s /opt/homebrew/bin/swiftlint /usr/local/bin
```

# Contributing

Contributions are very much welcomed! Please read our [Contributing Guidelines](/CONTRIBUTING.md) and [Code of Conduct](/CONDUCT.md). Our backlog has many Issues tagged with the `good first issue` label. Please fork the repo and make a pull request for us to review.

Secant Wallet uses [SwiftLint](https://github.com/realm/SwiftLint) and [SwiftGen](https://github.com/SwiftGen/SwiftGen) to conform to our coding guidelines for source code and generate accessors for assets. Please install these locally when contributing to the project, they are run automatically when you build.
  
# Reporting an issue

If you wish to report a security issue, please follow our [Wallet Issue Disclosure Policy](https://github.com/nighthawk-apps/nighthawk-ios-wallet/edit/main/README.md#disclosure-policy) and [ZcashLightClientKit Responsible Disclosure guidelines](https://github.com/zcash/ZcashLightClientKit/blob/master/responsible_disclosure.md).

 For other kind of inquiries, feel welcome to open an Issue if you encounter a bug or would like to request a feature.

## Donate to Nighthawk Devs

zs1nhawkewaslscuey9qhnv9e4wpx77sp73kfu0l8wh9vhna7puazvfnutyq5ymg830hn5u2dmr0sf

### License

MIT

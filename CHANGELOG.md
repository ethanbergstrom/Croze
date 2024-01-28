# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.2] - 2024-01-28
### Fixed
- Return nothing when no packages match

## [0.1.1] - 2024-01-28
### Added
- `Get-HomebrewPackageInfo` now includes whether a package is a Cask or Formula

## [0.1.0] - 2024-01-28
### Changed
- Package type required on all `HomebrewPackage` noun cmdlets due to `brew` CLI output ambiguity
- Upgrade to Cresendo 1.1 for module compilation (no functional changes expected)
### Fixed
- Package information emitted when installing from an external tap

## [0.0.5] - 2022-09-03
### Added
- Support for forced installation
### Fixed
- Formulae showing up as casks

## [0.0.4] - 2022-07-02
### Added
- Additional tap metadata retrieval

## [0.0.3] - 2022-06-26
### Changed
- Refactored some duplicate logic

## [0.0.2] - 2022-06-26
### Added
- Custom tap management
### Changed
- Installation package name parsing for wider artifact file name support
### Fixed
- Improved automated test accuracy
- Improved output handling
- Removed duplicate package search output

## [0.0.1] - 2022-06-26
- Initial release

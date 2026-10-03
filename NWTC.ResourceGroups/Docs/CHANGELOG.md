# Changelog

All notable changes to the NWTC.ResourceGroups module are documented here.
Newest version first. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow [Semantic Versioning](https://semver.org/).

## [1.1.0] - 2026-10-03

### Added
- **Added Get-ResourceGroupSummary**: a new public function that returns the name, location, and tags for one, many, or all resource groups. Supports pipeline input (by value and by `ResourceGroupName` property), and warns and continues on missing groups.
- **Improved testing**: Pester test suite in `Tests/NWTC.ResourceGroups.Tests.ps1`, with 13 mocked tests covering the manifest, version, exports, private helper scope, help, and Get-ResourceGroupSummary behavior. No Azure resources are touched.
- `Docs/CHANGELOG.md` and `Docs/RELEASENOTES.md`.
- `Releases/` folder containing the packaged module zip.

### Changed
- **Updated documentation**: module README, function README, and repository README updated for 1.1.0.
- Manifest `ModuleVersion` raised from 1.0.0 to 1.1.0, `Get-ResourceGroupSummary` added to `FunctionsToExport`, and `ReleaseNotes` added to PSData.

## [1.0.0] - 2026-09-24

### Added
- **Initial Release**: `New-TestResourceGroup` packaged as the NWTC.ResourceGroups module.
- Module manifest (`.psd1`) with RootModule, and a `.psm1` loader that dot-sources Public and Private functions and exports only Public ones.
- Public/Private/Tests/Logs/Docs folder structure.
- Private `Write-ModuleLog` helper that replaces the old transcript logging.
- `ProjectID` and `ResourceGroupName` accept arrays (`[string[]]`).
- Module README in `Docs/`.
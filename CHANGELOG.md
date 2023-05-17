## [Unreleased]

## [1.2.1] - 2023-05-17

### Fixed

- Fixed handling of path-based, derived spec metadata
  - Thanks to https://github.com/bquorning
- Fixed unnecessary spec runs for files without create calls or changes
- Fixed modification of factory calls that never run (e.g. in skipped examples)

## [1.2.0] - 2023-05-16

### Added

- Added support for magic comments `# sloth:disable`, `# sloth:enable`

## [1.1.0] - 2023-05-16

### Added

- Added summary at end of CLI output

## [1.0.1] - 2023-05-14

### Fixed

- Fixed shelling out on linuxes with simple shells

## [1.0.0] - 2023-05-14

- Initial release

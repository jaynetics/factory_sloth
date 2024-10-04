## [Unreleased]

### Added

## [1.4.0] - 2024-10-04

- ignore underscore-prefixed assignments e.g. `_user = create(:user)`

## [1.3.1] - 2023-05-24

### Fixed

- Stop trying to patch lines with multiple create calls, which was unreliable

## [1.3.0] - 2023-05-22

### Added

- Nicer output
- Verbose mode

## [1.2.2] - 2023-05-18

### Fixed

- No longer changes create to build for records that are persisted later
- Fixed duplicate entries in `.factory_sloth_done` file

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

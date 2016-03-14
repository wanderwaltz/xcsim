# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [1.0.0]
Initial release

## [1.0.1]
### Issues fixed
- Resolve https://github.com/wanderwaltz/xcsim/issues/1 regarding a Ruby 2.2 warning
  `Return nil in #<=> if the comparison is inappropriate or avoid such comparison.`
  by using `compact` instead of `select` for filtering `nil` values.

- Resolved https://github.com/wanderwaltz/xcsim/issues/2:
  -- `XCSim::parseDeviceSet` will now skips simulators without application data directory
  -- both `XCSim::parseInstalledBundles` and `XCSim::findBundleDataPath` now check the existence
     of their wokring deirectories for an early return
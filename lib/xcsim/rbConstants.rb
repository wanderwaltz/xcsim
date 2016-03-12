# -*- coding: utf-8 -*-

# XCSim module contains utility for parsing iOS Simulator metadata plist files
# and providing access to the bundle and data directories of the applications
# installed on iOS Simulator.
module XCSim

  # Absolute path of the directory, which stores all of thr iOS Simulator data
  SIMULATORS_ROOT = File.expand_path("~/Library/Developer/CoreSimulator/Devices")

  # Path for the application bundles directory relative to a concrete iOS Simulator device dir
  DEVICE_APP_BUNDLES_RELATIVE_PATH = "data/Containers/Bundle/Application"

  # Path for the application data directory relative to a concrete iOS Simulator device dir
  DEVICE_APP_DATA_RELATIVE_PATH = "data/Containers/Data/Application"

  # Name of the +device_set.plist+ file
  DEVICE_SET_PLIST = "device_set.plist"

  # Name of the plist file containing a certain application's metadata
  BUNDLE_METADATA_PLIST = ".com.apple.mobile_container_manager.metadata.plist"

  # A key in application metadata plist file, which corresponds to the bundle ID of the application
  METADATA_ID = "MCMMetadataIdentifier"

end

# eof
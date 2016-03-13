# -*- coding: utf-8 -*-

require_relative 'rbConstants'
require_relative 'rbDeviceSet'
require_relative 'rbList'

# call-seq:
#    xcsim(:list, pattern) => Array of DeviceListItem
#    xcsim(:bundle, options) => BundleInfo
#
# Main function to call when using xcsim gem. #xcsim works in two modes: list mode and bundle
# mode. List mode is for getting information about installed iOS Simulators, available OS versions
# and bundle IDs of the applications installed on these smiulators. Bundle mode focuses on
# individual applications and provides means of getting absolute paths for the application's data
# or bundle directories.
#
# == List mode
#
# List mode is invoked by calling
#
#    xcsim(:list, pattern)
#
# Pattern is expected to be a String containing partial match for iOS version / device model pair
# in <tt>'iOS 9.2, iPhone 5s'</tt> format. Both of the patterns are optional and coult be omitted,
# i.e. the following calls are all valid:
#
#    xcsim(:list, "iOS 9.2, iPhone 5s") # exact match for both iOS version and device
#    xcsim(:list, "iOS 9.2")            # match only iOS version
#    xcsim(:list, "iPhone 5s")          # match only device
#    xcsim(:list, "iOS")                # partial match for iOS version (all iOS simulators)
#    xcsim(:list, "9.2")                # partial match for iOS version (including watchOS, tvOS etc.)
#    xcsim(:list, "iPad")               # partial match for device model (all iPads)
#    xcsim(:list, "9, iPhone")          # partial match for both iOS version and device model
#
# In list mode #xcsim function returns an array of DeviceListItem object representing
# iOS Simulators found, which match the pattern provided. Partial matches are processed
# in a case-sensitive manner (basically, it finds all devices, whose OS version has the provided
# OS version pattern as a substring and whose device model contains the provided device model
# pattern as a substring).
#
# Each DeviceListItem will contain info about applications installed on the corresponding
# Simulator, excluding system apps (Safari et al.)
#
# Note that since #xcsim signature is
#
#     def xcsim(*args)
#
# multiple arguments may be provided to the function. In list mode all arguments are concatenated
# into a single +pattern+ string by using single whitespace as a separator.
#
# == Bundle mode
#
# Bundle mode is invoked by calling
#
#    xcsim(:bundle, options)
#
# Options is expected to be a Hash with the following keys:
#
# +:bundleID+::  Specifies the bundle ID of the application in question. #xcsim will then try
#                to locate the bundle with the ID provided and return the corresponding BundleInfo.
#                This is the only required option.
#
#                Bundle ID can be partially matched. Actual bundle IDs of the applications found
#                in the iOS Simulator are checked for having the provided bundle ID suffix, so
#                passing <tt>"application"</tt> as the +:bundleID+ option will match bundle ID
#                <tt>"com.yourcompany.application"</tt> for example. If multiple matches are found,
#                the result is ambiguous and #xcsim will raise an error. See Errors section for more
#                info.
#
# +:os+::        Specifies, which iOS version to use when searching in <tt>"iOS 9.2"</tt> format.
#                If omitted, #xcsim will default the OS version to the latest one found in the
#                parsed +device_set.plist+
#
# +:device+::    Specifies, which device model to use when searching in <tt>"iPad Air 2"</tt>
#                format. If omitted, #xcsim will default the device model to <tt>"iPhone 5s"</tt>
#
# Note that the +:os+ and +:device+ options do not perform partial matching to the contrary of
# what the list mode does.
#
# #xcsim will return a BundleInfo instance for bundle matching the options or raise an error.
#
# == Errors
#
# #xcsim may raise errors of several types when matching its results:
#
# ArgumentError::          An ArgumentError is raised if the parameters provided do not make sense
#                          as described above. That is, if in list mode multiple comma-separated
#                          components are found in the pattern string, or in bundle mode +:bundleID+
#                          parameter is not found, an ArgumentError will be raised.
#
# NonUniqueBundleIDError:: XCSim::NonUniqueBundleIDError is raised when multiple data or bundle
#                          directories are found matching the same bundle ID (should not generally
#                          happen since bundle IDs are unique in iOS Simulator) or when partial
#                          match of bundle ID in bundle mode finds multiple results.
#
# OSNotFoundError::        XCSim::OSNotFoundError is raised in bundle mode when OS version specified
#                          by the +:os+ option cannot be found in installed iOS simulators list.
#
# DeviceNotFoundError::    XCSim::DeviceNotFoundError is raised in bundle mode when device model
#                          specified by the +:device+ option cannot be found in installed iOS
#                          simulators list for the selected OS version.
#
# BundleNotFoundError::    XCSim::BundleNotFoundError is raised in bundle mode when the bundle ID
#                          specified by the +:bundleID+ option does not match any application
#                          installed on the selected iOS Simulator.
#
def xcsim(*args)
  case args.first
  when :list
    return XCSim::GetDeviceList.new(XCSim.deviceSet).withPattern(args[1..-1].join(" "))

  when :bundle
    raise ArgumentError if args.count != 2
    return XCSim::GetBundle.new(XCSim.deviceSet).withOptions(args.last)

  else
    raise ArgumentError
  end
end

# eof
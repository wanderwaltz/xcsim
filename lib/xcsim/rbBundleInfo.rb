# -*- coding: utf-8 -*-

module XCSim
  # An error, which is raised by GetBundle class when iOS Simulator OS version specified by
  # the +:os+ option could not be found.
  class OSNotFoundError < RuntimeError

    # Name of the OS provided in +:os+ option
    attr_reader :name

    # Initializes an OSNotFoundError instance with the given OS name
    def initialize(name)
      @name = name
    end
  end



  # An error, which is raised by GetBundle class when iOS Simulator device model specified by
  # the +:device+ option could not be found.
  class DeviceNotFoundError < RuntimeError

    # An OSDevices object corresponding to the OS version, which was used when searching
    # for the device
    attr_reader :os

    # Device name specified in the +:device+ option
    attr_reader :name

    # Initializes a DeviceNotFoundError instance with a given os and name
    def initialize(os, name)
      @os = os
      @name = name
    end
  end



  # An error, which is raised by GetBundle class when bundle ID specified by +:bundleID+ option
  # has not been found (even with partial match) on the device
  class BundleNotFoundError < RuntimeError

    # An OSDevices object corresponding to the OS version, which was used when searching
    # for the application bundle
    attr_reader :os

    # A DeviceID object corresponding to the device, which was used when searching for the
    # application bundle
    attr_reader :device

    # Bundle ID provided in +:bundleID+ option
    attr_reader :bundleID

    # Initializes a BundleNotFoundError instance with a given os, device and bundleID
    def initialize(os, device, bundleID)
      @os = os
      @device = device
      @bundleID = bundleID
    end
  end



  # Contains information about a certain application bundle
  class BundleInfo

    # Bundle ID of the application
    attr_reader :bundleID

    # Absolute path for the application bundle directory
    attr_reader :bundlePath

    # Absolute path for the application data directory
    attr_reader :dataPath

    # Initializes a BundleInfo instance with a given +bundleID+, +bundlePath+, +dataPath+
    def initialize(bundleID, bundlePath, dataPath)
      @bundleID = bundleID
      @bundlePath = bundlePath
      @dataPath = dataPath
    end

    # Returns +bundleID+
    def inspect
      @bundleID
    end

    # Same as #inspect
    def to_s
      inspect
    end
  end



  # A class encapsulating logic of searching for an applciation bundle in #xcsim function
  # (i.e. implementation of #xcsim bundle mode)
  class GetBundle
    # Initializes a GetBundle instance with a given device set of OSDevices type
    def initialize(deviceSet)
      @deviceSet = deviceSet
    end

    # Performs search for the application bundle matching the provided options.
    # See #xcsim description (Bundle Mode section) for more info.
    #
    # Returns a BundleInfo object
    def withOptions(options)
      bundleID = options[:bundleID]

      if bundleID == nil
        raise ArgumentError
      end

      os = osNamed(options[:os] || XCSim::defaultOSName)
      device = deviceNamed(os, options[:device] || XCSim::defaultDeviceName)
      bundles = XCSim::parseInstalledBundles(device).values

      matchingBundles = bundles.select { |bundle| bundle.bundleID.end_with? bundleID }

      if matchingBundles.count > 1
        raise NonUniqueBundleIDError.new(device, bundleID, matchingBundles.map { |b| b.bundleID })
      elsif matchingBundles.empty?
        raise BundleNotFoundError.new(os, device, bundleID)
      else
        return matchingBundles.first
      end
    end

    private
    def osNamed(name)
      @deviceSet[OSID.fromString(name)] || (raise OSNotFoundError.new(name))
    end

    def deviceNamed(os, name)
      os.devices[name] || (raise DeviceNotFoundError.new(os, name))
    end

  end
end # module XCSim

# eof
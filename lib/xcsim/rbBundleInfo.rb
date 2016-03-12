# -*- coding: utf-8 -*-

module XCSim
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
  end # class BundleInfo



  class GetBundle
    def initialize(deviceSet)
      @deviceSet = deviceSet
    end

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

  end # class GetBundle


  class OSNotFoundError < RuntimeError
    attr_reader :name

    def initialize(name)
      @name = name
    end
  end


  class DeviceNotFoundError < RuntimeError
    attr_reader :os
    attr_reader :name

    def initialize(os, name)
      @os = os
      @name = name
    end
  end


  class BundleNotFoundError < RuntimeError
    attr_reader :os
    attr_reader :device
    attr_reader :bundleID

    def initialize(os, device, bundleID)
      @os = os
      @device = device
      @bundleID = bundleID
    end
  end

end # module XCSim

# eof
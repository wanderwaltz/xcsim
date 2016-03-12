# -*- coding: utf-8 -*-

require_relative 'rbConstants'

module XCSim

  # DeviceID is a pair of device name string and a +GUID+, which identifies
  # the concrete iOS Simulator in the file system. DeviceID provides access
  # to the application bundle and application documents paths.
  class DeviceID

    # Name of the device (e.g. <tt>'iPhone 5s'</tt>)
    attr_reader :name

    # Creates a DeviceID instance from a string prefixed by a standard
    # prefix encountered in +device_set.plist+ (+com.apple.CoreSimulator.SimDeviceType.+)
    #
    # Does not perform any additional validation other than checking the prefix.
    def self.fromPrefixedString(string, guid)
      unless string.start_with? @@PREFIX
        return nil
      end

      name = string.sub(@@PREFIX, "").gsub("-", " ")
        return DeviceID.new(name, guid)
    end

    # Initializes a DeviceID instance with a given name and +GUID+.
    def initialize(name, guid)
      @name = name
      @guid = guid
    end

    # Returns an absolute path for application bundles directory
    # corresponding to the given device.
    def appBundlesPath
      "#{SIMULATORS_ROOT}/#{@guid}/#{DEVICE_APP_BUNDLES_RELATIVE_PATH}"
    end

    # Returns an absolute path for application data directory
    # corresponding to the given device
    def appDataPath
      "#{SIMULATORS_ROOT}/#{@guid}/#{DEVICE_APP_DATA_RELATIVE_PATH}"
    end

    # Returns device name
    def inspect
      @name
    end

    # Same as #inspect
    def to_s
      inspect
    end

    # Returns a string used for indexing device definitions in +device_set.plist+
    # in +com.apple.CoreSimulator.SimDeviceType.iPad-2+ format.
    def key
      "#{@@PREFIX}#{@name.gsub(" ","-")}"
    end

    # Returns +inspect.hash+
    def hash
      inspect.hash
    end

    # Checks equality by <tt>@name</tt>
    def eql?(other)
      @name.eql?(other.name)
    end

    private
    @@PREFIX = "com.apple.CoreSimulator.SimDeviceType."
  end # class DeviceID

end # module XCSim

# eof
# -*- coding: utf-8 -*-

module XCSim

  # A collection of DeviceID objects related to a given iOS Simulator OS version
  class OSDevices

    # An OSID of the iOS Simulator OS version related to the OSDevices collection
    attr_reader :id

    # A hash of <tt>deviceName => DeviceID</tt>
    attr_reader :devices

    # Initializes an OSDevices instance with a given OSID and a collection of devices
    # +id+::      OSID to associate with the OSDevices object
    # +devices+:: A collection of DeviceID objects. Should support #each method for enumeration.
    def initialize(id, devices)
      @id = id

      devicesHash = {}
      devices.each{ |d| devicesHash[d.name] = d }

      @devices = devicesHash
    end

    # Returns a string in <tt>'iOS 9.0 (5 devices)'</tt> format
    def inspect
      "#{@id.inspect} (#{@devices.count} devices)"
    end

    # Same as #inspect
    def to_s
      inspect
    end

    include Comparable

    # Compares by +id+
    def <=>(other)
      @id <=> other.id
    end

  end # class OSDevicess

end # module XCSim

# eof
# -*- coding: utf-8 -*-

require 'cfpropertylist'

require_relative 'rbOSID'
require_relative 'rbDeviceID'
require_relative 'rbOSDevices'

module XCSim

  # call-seq:
  #    parseDeviceSet(absolutePath) => Hash
  #
  # Parses a +device_set.plist+ file located at the given +path+
  #
  # Returns a Hash of <tt>OSID => OSDevices</tt> for iOS Simulator OSes,
  # which have at least one device simulator installed.
  def self.parseDeviceSet(path)
    plist = CFPropertyList::List.new(:file => path)
    plist = CFPropertyList.native_types(plist.value)
    defaultDevices = plist["DefaultDevices"]

    osIDs = defaultDevices
      .keys
      .map{|s| OSID.fromPrefixedString(s) }
      .select{|id| id != nil}

    oses = osIDs.map do |id|
      osDevices = defaultDevices[id.key]
      devices = osDevices
        .keys
        .map{ |s| DeviceID.fromPrefixedString(s, osDevices[s])}
        .select{ |device| device != nil }
        .select{ |device| File.directory? device.appBundlesPath }

        (devices.count > 0) ? OSDevices.new(id, devices) : nil
    end
    .select{ |os| os != nil }

    osHash = {}
    oses.each{ |os| osHash[os.id] = os }

    osHash
  end

  def self.deviceSet
    @@deviceSet
  end

  def self.defaultOSName
    @@deviceSet.keys.max.to_s
  end

  def self.defaultDeviceName
    "iPhone 5s"
  end

  @@deviceSet = parseDeviceSet("#{XCSim::SIMULATORS_ROOT}/#{XCSim::DEVICE_SET_PLIST}")
end # module XCSim

# eof
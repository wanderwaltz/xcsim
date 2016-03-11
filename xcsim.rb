#!/usr/bin/ruby

require 'plist'

SIMULATORS_ROOT = File.expand_path("~/Library/Developer/CoreSimulator/Devices")
DEVICE_SET_PLIST = "device_set.plist"

# OSID is a pair of OS type (iOS, watchOS, tvOS) and version
class OSID
    attr_reader :type, :version
    @@PREFIX = "com.apple.CoreSimulator.SimRuntime."

    def self.fromPrefixedString(string)
        unless string.start_with? @@PREFIX
            return nil
        end

        components = string.sub(@@PREFIX, "").split("-")
        type = components.first
        version = components[1..-1].join(".")

        return OSID.new(type, version)
    end

    def initialize(type, version)
        @type = type
        @version = version
    end

    def inspect
        "#{@type} #{@version}"
    end

    def to_s
        inspect
    end

    def key
        "#{@@PREFIX}#{@type}-#{@version.gsub(".","-")}"
    end
end


class OSDevices
    attr_reader :id, :devices

    def initialize(id, devices)
        @id = id
        @devices = devices
    end

    def inspect
        "#{@id.inspect} (#{@devices.count} devices)"
    end

    def to_s
        inspect
    end
end


class DeviceID
    attr_reader :name, :guid
    @@PREFIX = "com.apple.CoreSimulator.SimDeviceType."

    def self.fromPrefixedString(string, guid)
        unless string.start_with? @@PREFIX
            return nil
        end

        name = string.sub(@@PREFIX, "").gsub("-", " ")
        return DeviceID.new(name, guid)
    end

    def initialize(name, guid)
        @name = name
        @guid = guid
    end

    def inspect
        @name
    end

    def to_s
        inspect
    end

    def key
        "#{@@PREFIX}#{@name.gsub(" ","-")}"
    end
end


def parseDeviceSet(path)
    plist = Plist::parse_xml(path)
    defaultDevices = plist["DefaultDevices"]

    osIDs = defaultDevices.keys.map{|s| OSID.fromPrefixedString(s) }.select{|id| id != nil}

    oses = osIDs.map do |id|
        osDevices = defaultDevices[id.key]
        devices = osDevices.keys.map { |s| DeviceID.fromPrefixedString(s, osDevices[s])}.select{ |id| id != nil }

        OSDevices.new(id, devices)
    end

    osHash = Hash.new

    oses.each do |os|
        osHash[os.id] = os
    end

    osHash
end


devicesByOS = parseDeviceSet("#{SIMULATORS_ROOT}/#{DEVICE_SET_PLIST}")

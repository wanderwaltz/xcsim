# -*- coding: utf-8 -*-

require_relative 'rbAppBundles'

module XCSim
  class DeviceListItem
    attr_reader :os
    attr_reader :device
    attr_reader :bundles

    def initialize(os, device, bundles)
      @os = os
      @device = device
      @bundles = bundles
    end

    def fullName
      "#{device.name} (#{os.id})"
    end

    def shortName
      device.name
    end

    def inspect
      fullName
    end

    def to_s
      inspect
    end
  end



  class GetDeviceList
    def initialize(deviceSet)
      @deviceSet = deviceSet
    end

    def withPattern(pattern)
      if pattern.length == 0
        return allDevices
      else
        pattern = parsePattern(pattern)
        matchingOSes = getMatchingOSList(pattern[:os])

        devicePairs = matchingOSes
          .map{ |os| os.devices.values.map{ |d| {:os => os, :device => d} } }
          .flatten

        # try finding a strict match first (disambiguate "iPad Air" from "iPad Air 2")
        # find partial matches otherwise
        matchingDevices =
          strictDeviceMatches(devicePairs, pattern[:device]) ||
          partialDeviceMatches(devicePairs, pattern[:device]) ||
          []

        return matchingDevices.map do |pair|
          DeviceListItem.new(pair[:os], pair[:device],
            XCSim::parseInstalledBundles(pair[:device]).values)
        end
        .flatten
      end
    end

    def allDevices
      @deviceSet.values.map do |os|
        os.devices.values.map do |device|
          DeviceListItem.new(os, device, XCSim::parseInstalledBundles(device).values)
        end
      end
      .flatten
    end

    private
    def parsePattern(pattern)
      components = pattern.split(",").map{ |s| s.strip }

      case components.count
      when 2
        # assume first pattern is always for OS,
        # second - for device
        osPattern = components.first
        devicePattern = components.last

      when 1
        # we don't know whether the pattern is for OS or device,
        # try OS first
        osPattern = components.first
        devicePattern = nil
        matchingOSes = getMatchingOSList(osPattern)

        # if no OSes match, assume the pattern is for device
        if matchingOSes.empty?
          osPattern = nil
          matchingOSes = nil
          devicePattern = components.first
        end

      else
        raise ArgumentError
      end

      { :os => osPattern, :device => devicePattern }
    end

    def strictDeviceMatches(osDevicePairs, pattern)
      matches = osDevicePairs.select{ |p| p[:device].name == pattern }
      matches.empty? ? nil : matches
    end

    def partialDeviceMatches(osDevicePairs, pattern)
      matches = osDevicePairs.select{ |p| p[:device].name.include? (pattern || "") }
      matches.empty? ? nil : matches
    end

    def getMatchingOSList(pattern)
      return @deviceSet.values.select{ |os| os.id.to_s.include? (pattern || "") }
    end

  end # class GetDeviceList

end # module XCSim

# eof
# -*- coding: utf-8 -*-

module XCSim

  # Prepares a more human-readable report from an array of DeviceListItem objects.
  #
  # Depending on the unique OS versions and device models referenced by the +list+ items,
  # may return one of the following results:
  #
  # List of application bundles:: When +list+ contains a single item
  # List of device names::        When +list+ contains multiple devices from a single OS version
  # List of OS version strings::  When +list+ contains a multiple devices from multiple OS version
  def self.reportFromDeviceList(list)
    uniqueOSes = list.map{ |item| item.os.id }.uniq
    uniqueDevices = list.map { |item| item.device.name }.uniq

    countByOS = {}
    list.each do |item|
      count = countByOS[item.os.id] || 0
      countByOS[item.os.id] = count+1
    end

    if uniqueOSes.empty? || uniqueDevices.empty?
      raise ArgumentError

    elsif uniqueOSes.count == 1 && uniqueDevices.count == 1
      list.first.bundles

    elsif uniqueOSes.count == 1
      list.map{ |item| item.device.name }

    elsif false == (countByOS.values.include? 1)
      countByOS.map { |id, count| "#{id} (#{count} devices)"}

    else
      list
    end
  end

end # module XCSim

#eof
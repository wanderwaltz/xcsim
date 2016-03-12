# -*- coding: utf-8 -*-

require_relative 'rbConstants'
require_relative 'rbDeviceSet'
require_relative 'rbList'

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
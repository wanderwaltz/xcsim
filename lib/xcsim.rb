# -*- coding: utf-8 -*-

begin
  require 'cfpropertylist'
rescue LoadError
  puts "require 'cfpropertylist' failed! Consider running 'gem install CFPropertyList'"
  exit
end

require_relative 'xcsim/rbXCSim'
require_relative 'xcsim/rbReports'

# eof
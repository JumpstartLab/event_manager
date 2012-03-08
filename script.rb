require './event_manager'
require 'perftools'

PerfTools::CpuProfiler.start("/tmp/jsattend_3") do
  jsa = JSAttend.new("event_attendees.csv")
  jsa.print_names
  jsa.print_phone_numbers
end

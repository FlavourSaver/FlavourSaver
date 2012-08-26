require File.expand_path('../../lib/flavour_saver', __FILE__)

Dir.glob('spec/acceptance/steps/**/*.rb') do |stepfile|
  load stepfile
end

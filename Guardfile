guard 'rspec', version: 2 do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})     { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')  { "spec" }
  watch(%r{^spec/(.+)\.(hbs|handlebars)}) { |m| "spec/acceptance/#{m[1]}_spec.rb" }
end


guard 'bundler' do
  watch('Gemfile')
  watch(/^.+\.gemspec/)
end

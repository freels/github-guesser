$: << File.expand_path(File.join(__FILE__, '../lib'))

require 'loader'

task :default do
  Loader.load!('data')
  Loader.generate_results!
end


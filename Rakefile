$: << File.expand_path(File.join(__FILE__, '../lib'))

require 'loader'

task :default do
  Loader.load!('data')
  Loader.generate_results!
end

namespace :stats do
  task :results do
    results = File.read('results.txt')
    lines = results.split("\n")
    line_count = lines.length
    watches = lines.map{|l| l.split(':').last.split(',')}.flatten
    watch_count = watches.length
    puts "Users: #{line_count}, Watches: #{watch_count}"
  end
end


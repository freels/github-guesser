require 'monkey'
require 'watcher'
require 'repo'
require 'watch'
require 'lang'
require 'enigma'

module Loader
  extend self

  def load!(datadir)
    #load_repos(datadir)
    load_watches(datadir)
    #load_langs(datadir)
    load_enigmas(datadir)
  end

  def load_repos(datadir)
    count = 0
    print "Loading repos"; $stdout.flush
    File.foreach(File.join(datadir, 'repos.txt')) do |line|
      count += 1
      if count % 1000 == 0
        print '.'; $stdout.flush 
      end
      Repo.new(line)
    end
    puts "done"
  end

  def load_langs(datadir)
    count = 0    
    print "Loading langs"; $stdout.flush
    File.foreach(File.join(datadir, 'lang.txt')) do |line|
      count += 1
      if count % 1000 == 0
        print '.'; $stdout.flush 
      end
      Lang.parse(line)
    end
    puts "done"
  end

  def load_watches(datadir)
    count = 0    
    print "Loading watches"; $stdout.flush
    File.foreach(File.join(datadir, 'data.txt')) do |line|
      count += 1
      if count % 1000 == 0
        print '.'; $stdout.flush 
      end
      Watch.new(line)
    end
    puts "done"
  end

  def load_enigmas(datadir)
    count = 0    
    print "Loading mysterious ppl"; $stdout.flush
    File.foreach(File.join(datadir, 'test.txt')) do |line|
      count += 1
      if count % 1000 == 0
        print '.'; $stdout.flush 
      end
      Enigma.new(line)
    end
    puts "done"
  end

  def generate_results!
    count = 0    
    print "Reticulating splines"; $stdout.flush
    File.open('results.txt', 'w') do |fd|
      count += 1
      if count % 10 == 0
        print '.'; $stdout.flush 
      end
      Enigma.all.each {|e| fd.puts e.to_s; fd.flush }
    end
    puts "finished! YOU DO THE MATH!"
  end
end
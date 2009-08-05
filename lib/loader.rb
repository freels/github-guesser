require 'monkey'
require 'watcher'
require 'repo'
require 'watch'
require 'lang'
require 'enigma'

module Loader
  extend self

  def load!(datadir)
    load_repos(datadir)
    load_watches(datadir)
    #load_langs(datadir)
    load_enigmas(datadir)
  end

  def do_thing(label)
    start = Time.now
    print "#{label}..."
    STDOUT.flush
    yield
    puts "done. (elapsed #{(Time.now - start).to_i} seconds)"
  end

  def load_repos(datadir)
    do_thing "Loading repos" do
      File.foreach(File.join(datadir, 'repos.txt')) do |line|
        Repo.new(line)
      end
    end
  end

  def load_langs(datadir)
    do_thing "Loading repos" do
      File.foreach(File.join(datadir, 'lang.txt')) do |line|
        Lang.parse(line)
      end
    end
  end

  def load_watches(datadir)
    do_thing "Loading watches" do
      File.foreach(File.join(datadir, 'data.txt')) do |line|
        Watch.new(line)
      end
    end
  end

  def load_enigmas(datadir)
    do_thing "Loading test data" do
      File.foreach(File.join(datadir, 'test.txt')) do |line|
        Enigma.new(line)
      end
    end
  end

  PROCESSES = 6

  def generate_results!
    do_thing "Reticulating splines" do
      Watch.correlations
      if GC.respond_to? :copy_on_write_friendly?
        GC.copy_on_write_friendly = true
      end
      GC.start
      PROCESSES.times do |mod|
        fork {
          puts 'forking...'
          File.open("results_#{mod}.txt", 'w') do |fd|
            Enigma.all.each_with_index do |e,idx|
              if idx % PROCESSES == mod
                fd.puts e.to_s; fd.flush
              end
            end
          end
        }
      end
      Process.waitall
      File.open("results.txt", 'w') do |fd|
        PROCESSES.times {|mod| fd.puts File.read("results_#{mod}.txt") }
      end
    end
  end
end

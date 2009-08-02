require 'monkey'
require 'watcher'
require 'repo'

class Watch
  attr_accessor :watcher_id, :repo_id

  def initialize(data)
    instantiate_with data

    self.class.all << self
    self.class.all_by_watcher[watcher_id] << self
    self.class.all_by_repo[repo_id] << self
  end

  def watcher
     Watcher[watcher_id]
  end

  def repo
    Repo[repo_id]
  end

  class << self
    def all
      @all ||= []
    end

    def all_by_watcher
      @all_by_watcher ||= Hash.new {|h,k| h[k] = [] }
    end

    def all_by_repo
      @all_by_repo ||= Hash.new {|h,k| h[k] = [] }
    end

    def correlations
      unless @correlations
        if File.exist?('correlations.dump')
          @correlations = Marshal.load(File.read('correlations.dump'))
          return @correlations
        end

        count = 0
        @correlations = {}
        all_by_watcher.each do |watcher_id, watches|
          count += 1
          if count % 1000 == 0
            print '`'; $stdout.flush
          end
          watches.each do |watch|
            watches.each do |other|
              if watch != other
                @correlations[watch.repo_id] ||= {}
                @correlations[watch.repo_id][other.repo_id] ||= 0
                @correlations[watch.repo_id][other.repo_id] += 1
              end
            end
          end
        end

        File.open('correlations.dump', 'w') do |fd|
          fd.puts Marshal.dump(@correlations)
        end
        #p @correlations
      end
      @correlations
    end
  end

  private

  def instantiate_with(data)
    m = %r|(\d+):(\d+)|.match(data)
    raise "can't understand! #{data}" unless m

    watcher_id, repo_id = m[1..2]
    self.watcher_id = watcher_id.to_i
    self.repo_id = repo_id.to_i
  end
end


require 'monkey'
require 'watcher'

class Enigma
  attr_accessor :id

  def initialize(id)
    self.id = id.to_i
    self.class.all << self
  end

  def watcher
    @watcher ||= Watcher[id]
  end

  def guessed_watches
    guesses = guess_from_correlations

    # select best guesses (poor man's heap)
    result = []

    guesses.each do |new_id, new_weight|
      index = 0
      loop do
        break if result[index].nil?
        break if new_weight < result[index].last
        index += 1
      end

      result.insert(index, [new_id, new_weight])
      result.shift if result.length > 10
    end

    result.reverse!

    print "id:#{id} existing:#{watcher.watches.length} guesses(#{guesses.length}): "
    puts result[0,10].map{|g| sprintf "%i:%.3f", *g }.join(', ')

    result.map{|g| g.first }
  end

  def guess_from_correlations
    # add parent repos, too.
    repo_ids = watcher.watches.inject([]) do|ids, watch|
      repo = watch.repo
      until repo.nil?
        ids << repo.id
        repo = repo.parent
      end
      ids
    end.uniq

    repo_ids.inject(Hash.new(0)) do |guesses, repo_id|
      total = (Watch.all_by_repo[repo_id].length rescue 0)
      weighted_total = (total ** 1.5).to_f

      (Watch.correlations[repo_id] || {}).each do |id, weight|
        unless repo_ids.include?(id)
          guesses[id] += ((weight || 0) / weighted_total)
        end
      end

      guesses
    end
  end  

  def to_s
    "#{id}:#{guessed_watches.join(',')}"
  end

  class << self
    def all
      @all ||= []
    end
  end
end

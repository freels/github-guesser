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
    @guessed_watches ||= guess_from_correlations[0, 10].sort
  end

  def guess_from_correlations
    repo_ids = watcher.watches.map{|w| w.repo_id }
    guesses = Hash.new(0)
    repo_ids.each do |repo_id|
      total = (Watch.all_by_repo[repo_id].length rescue 0)
      weighted_total = (total ** 1.5).to_f
      (Watch.correlations[repo_id] || {}).each do |id, weight|
        next if repo_ids.include?(id)
        guesses[id] += ((weight || 0) / weighted_total)
      end
    end
    threshold = 0.1 #guesses.length / 100.to_f
    short_guesses = guesses.reject{|k,v| v <= threshold}
    result = (short_guesses.length < 10 ? guesses : short_guesses).to_a.sort{|a,b| b.last <=> a.last}


    print "id:#{id} repos:#{repo_ids.length} guesses(#{guesses.length}): "
    puts result[0,10].map{|g| sprintf "%i:%.3f", *g }.join(', ')

    result.map{|g| g.first }
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

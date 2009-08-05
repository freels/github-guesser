require 'monkey'
require 'watcher'
require 'pqueue'

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
    guess_time = Time.now.to_i
    guesses = merge_guesses!(guess_from_correlations, guess_from_parents)
    guess_time = Time.now.to_i - guess_time

    # select best guesses (poor man's heap)
    top_ten = PQueue.new(10)

    sort_time = Time.now.to_i
    guesses.each {|id, prob| top_ten.add(order, [id, order]) }
    sort_time = Time.now.to_i - guess_time

    top_ten = top_ten.to_a

    print "id:#{id} existing:#{watcher.watches.length} guesses(#{guesses.length}): "
    puts top_ten.map{|g| sprintf "%i:%.3f", *g }.join(', ')
    puts "  seconds elapsed: #{guess_time} (guesses), #{sort_time} (sort)" 

    top_ten.map! {|g| g.first }
    top_ten
  end

  SIGNIFICANCE = 10
  PENALTY = 0.05

  def guess_from_correlations
    (watcher.repo_ids + watcher.repo_ancestor_ids).uniq.inject({}) do |guesses, repo_id|
      total = (Watch.all_by_repo[repo_id].length.to_f rescue nil)

      max_prob = 0.95
      max_prob -= (PENALTY / SIGNIFICANCE) * (SIGNIFICANCE - total.to_i) if total < SIGNIFICANCE

      if total #i.e. the repo has watches.
        (Watch.correlations[repo_id] || {}).each do |id, count|
          unless watcher.repo_ids.include?(id)
            watch_probability = count / total
            watch_probability = max_prob if watch_probability > max_prob

            guesses[id] = prob_or(guesses[id] || 0, watch_probability)
          end
        end
      end

      guesses
    end
  end

  PARENT_PROBABILITY = 0.95

  def guess_from_parents
    repos = watcher.watches.map {|w| w.repo.parent.id}.compact
    repos.inject({}) do |guesses, repo_id|
      if guesses[repo_id]
        guesses[repo_id] = prob_or(guesses[repo_id], PARENT_PROBABILITY)
      else
        guesses[repo_id] = PARENT_PROBABILITY
      end
    end
  end

  def to_s
    "#{id}:#{guessed_watches.join(',')}"
  end

  private

  def prob_or(a,b)
    1.0 - (1.0 - a) * (1.0 - b)
  end

  def merge_guesses!(*guess_hashes)
    guess_hashes.inject do |guesses, addon|
      guesses.merge!(addon) {|k,a,b| prob_or(a,b) }
    end
    guess_hashes
  end

  class << self
    def all
      @all ||= []
    end
  end
end

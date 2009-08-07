require 'monkey'
require 'repo'

class Lang
  attr_accessor :name, :repo_id, :lines

  def initialize(name, repo_id, lines)
    self.name = name
    self.repo_id = repo_id
    self.lines = lines

    self.class.all << self
    self.class.all_by_name[name] << self
    self.class.all_by_repo[repo_id] << self
    self.class.all_by_repo[repo_id].sort! {|a,b| b.lines <=> a.lines }
  end

  def repo
    @repo ||= Repo[repo_id]
  end

  class << self
    def parse(data)
      repo_id, langs = data.split(':')
      langs.split(',').map{|l| l.split(';')}.each do |name,lines|
        new(name, repo_id.to_i, lines.to_i)
      end
    end

    def all
      @all ||= []
    end

    def [](name)
      all_by_name[name]
    end

    def all_by_name
      @all_by_name ||= Hash.new {|h,k| h[k] = [] }
    end

    def all_by_repo
      @all_by_repo ||= Hash.new {|h,k| h[k] = [] }
    end
  end
end

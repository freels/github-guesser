class << Class
  def init_with_options
    eval <<-end_eval
    def initialize(options)
      options.each {|k,v| send("\#{k}=", v) if respond_to?("\#{k}=") }
    end
    end_eval
  end
end

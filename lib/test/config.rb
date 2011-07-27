module Test

  #
  def self.run(name, &block)
    config[name.to_s] = block
  end

  def self.config
    @config ||= {}
  end

end

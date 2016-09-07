require 'squares/version'
require 'squares/base'
require 'json'

module Squares
  class << self
    include Enumerable

    def each &block
      models.each(&block)
    end

    def models
      (@models || []).uniq.sort { |a,b| a.to_s <=> b.to_s }
    end

    def add_model model
      @models ||= []
      @models << model
    end

  end
end

require 'squares/version'
require 'squares/base'

module Squares
  class << self
    include Enumerable

    def each &block
      models.each &block
    end

    def models
      Squares::Base.models
    end

  end
end

module Marvel
  class SuperHero < Squares::Base
    properties :real_name, :special_powers
    property :caped?, default: false
  end
end



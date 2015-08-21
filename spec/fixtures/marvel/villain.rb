module Marvel
  class Villain < Squares::Base
    properties :vehicle, :lair
    property :really_evil?, default: true
  end
end

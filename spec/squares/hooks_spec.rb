require 'spec_helper'
require 'squares/base'

RSpec.describe Squares::Hooks do
  Given(:storage)    { {} }
  Given(:test_class) { Marvel::Sidekick }
  Given              { test_class.store = storage }
  Given do
    class Marvel::Sidekick < Squares::Base
      property :hooked, default: []
    end
  end
  Given { Marvel::Sidekick.instance_variable_set "@_hooks", nil }

  context 'around creation' do
    When(:robin) do
      Marvel::Sidekick.create 'Robin', catch_phrase: 'Holy _, Batman!'
    end

    describe '.before_create' do
      Given do
        class Marvel::Sidekick < Squares::Base
          before_create { hooked << :before_create }
        end
      end

      Then { expect(robin.hooked).to include(:before_create) }
    end

    describe '.after_create' do
      Given do
        class Marvel::Sidekick < Squares::Base
          after_create { hooked << :after_create }
        end
      end

      Then { expect(robin.hooked).to include(:after_create) }
    end
  end

  context 'around initialization' do
    Given do
      class Marvel::Sidekick < Squares::Base
        after_initialize { hooked << :after_initialize }
      end
    end

    When(:robin) do
      Marvel::Sidekick.new 'Robin', catch_phrase: 'Holy _, Batman!'
    end

    describe '.after_initialize' do
      Then { expect(robin.hooked).to include(:after_initialize) }
    end
  end

  context 'around finding' do
    Given do
      class Marvel::Sidekick < Squares::Base
        after_find { hooked << :after_find }
      end
    end
    Given do
      Marvel::Sidekick.create 'Robin', catch_phrase: 'Holy _, Batman!'
    end

    When(:robin) do
      Marvel::Sidekick.find 'Robin'
    end

    describe '.after_find' do
      Then { expect(robin.hooked).to include(:after_find) }
    end
  end

  context 'around saving' do
    When(:robin) do
      Marvel::Sidekick.new 'Robin', catch_phrase: 'Holy _, Batman!'
    end
    When { robin.save }

    context '.before_save' do
      Given do
        class Marvel::Sidekick < Squares::Base
          before_save { hooked << :before_save }
        end
      end

      Then { expect(robin.hooked).to include(:before_save) }
    end

    context '.after_save' do
      Given do
        class Marvel::Sidekick < Squares::Base
          after_save { hooked << :after_save }
        end
      end

      Then { expect(robin.hooked).to include(:after_save) }
    end
  end

  context 'around destruction' do
    Given do
      class Marvel::Sidekick < Squares::Base
        before_destroy { hooked << :before_destroy }
      end
    end

    When(:robin) do
      Marvel::Sidekick.create 'Robin', catch_phrase: 'Holy _, Batman!'
    end
    When { robin.destroy }

    describe '.before_destroy' do
      Then { expect(robin.hooked).to include(:before_destroy) }
    end
  end

  context 'hook callbacks do not fire other hook callbacks' do
    Given do
      class Marvel::Sidekick < Squares::Base
        after_initialize do
          hooked << :after_initialize
          save
        end
        before_save { hooked << :before_save }
      end
    end

    When(:robin) do
      Marvel::Sidekick.new 'Robin', catch_phrase: 'Holy _, Batman!'
    end

    Then { expect(robin.hooked).to include(:after_initialize) }
    Then { expect(robin.hooked).to_not include(:before_save) }
  end
end

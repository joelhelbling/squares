require 'spec_helper'

describe Squares do
  describe 'version number' do
    Then { expect(Squares::VERSION).not_to be nil }
  end

  describe '.models' do
    When(:models) { described_class.models }
    Then { models == [ Marvel::Sidekick, Marvel::SuperHero, Marvel::Villain ] }
  end
end

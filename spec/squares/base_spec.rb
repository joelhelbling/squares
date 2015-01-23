require 'spec_helper'
require 'squares/base'

module Marvel
  class SuperHero < Squares::Base
    properties :real_name, :special_powers
  end
  class Villain < Squares::Base
    properties :vehicle, :lair
    property :really_evil?, default: true
  end
end

module Squares
  describe Base do
    Given(:storage)    { {} }
    Given(:test_class) { Marvel::SuperHero }
    Given              { test_class.store = storage }

    Given(:id)         { 'Captain America' }
    Given(:name)       { 'Steve Rogers' }
    Given(:powers)     { ['super strength', 'strategy', 'leadership'] }
    When(:hero)        { test_class.new id, real_name: name, special_powers: powers }

    describe 'class methods' do

      describe '.underscore_name' do
        Then { test_class.underscore_name == 'marvel/super_hero' }
      end

      describe '.delete' do
        Given { hero.save }
        When  { Marvel::SuperHero.delete id }
        Then  { expect(storage).to_not be_member(id) }
      end

      describe '.properties' do
        Then { test_class.properties == [:real_name, :special_powers] }
      end

      describe '.use_storage' do
        Given(:storage) { {attack: :fwoosh } }
        When            { test_class.store = storage }
        Then            { test_class.store == storage }
      end

      describe '.models lists defined models (inheritors)' do
        When(:result) { described_class.models }
        Then { result == [ Marvel::SuperHero, Marvel::Villain ] }
      end

      describe '.[]' do
        Given                 { storage[id] = Marshal.dump hero }
        When(:recovered_hero) { Marvel::SuperHero['Captain America'] }
        Then                  { recovered_hero.class     == Marvel::SuperHero }
        Then                  { recovered_hero.id        == 'Captain America' }
        Then                  { recovered_hero.real_name == 'Steve Rogers' }
        Then                  { recovered_hero.special_powers.include? 'leadership' }
      end

      describe '.[]= creates & stores a new instance' do
        Given(:id)     { 'Spiderman' }
        Given(:name)   { 'Peter Parker' }
        Given(:powers) { [ 'wall crawling', 'web spinning', 'cracking wise' ] }

        context 'whether created with an instance' do
          Given(:instance) { test_class.new(id, real_name: name, special_powers: powers) }

          When             { test_class[id] = instance }
          When(:spidey)    { Marshal.restore storage.values.first }

          Then             { spidey.class     == Marvel::SuperHero }
          Then             { spidey.id        == 'Spiderman' }
          Then             { spidey.real_name == 'Peter Parker' }
          Then             { spidey.special_powers.include? 'cracking wise' }
        end

        context 'or creating using a hash' do
          When { test_class[id] = { real_name: name, special_powers: powers } }

          When(:spidey) { Marshal.restore storage.values.first }
          Then { spidey.class     == Marvel::SuperHero }
          Then { spidey.id        == 'Spiderman' }
          Then { spidey.real_name == 'Peter Parker' }
          Then { spidey.special_powers.include? 'cracking wise' }
        end

        context 'but creating with an invalid object' do
          Then { expect{ test_class[id] = 12 } .to raise_error(ArgumentError) }
        end

        context '.create alias returns the new object' do
          When(:result) { test_class.create id, real_name: name, special_powers: powers }
          Then { expect(result).to be_kind_of(Marvel::SuperHero) }
        end
      end

      describe '.has_key?' do
        Given { hero.save }
        Then  { expect(test_class).to have_key(id) }
        Then  { expect(test_class).to be_key(id) }
        Then  { expect(test_class).to be_member(id) }
        Then  { expect(test_class).to be_includes(id) }
      end

      describe 'more cool stuff' do
        Given do
          Marvel::SuperHero['Superman'] = { real_name: 'Clark Kent',   special_powers: ['flying'] }
          Marvel::SuperHero['Hulk']     = { real_name: 'Bruce Banner', special_powers: ['smash'] }
          Marvel::SuperHero['Batman']   = { real_name: 'Bruce Wayne',  special_powers: ['stuff'] }
        end

        describe '.where' do
          When(:result) { Marvel::SuperHero.where { |h| h.real_name =~ /^Bruce/ } }
          Then { result.count == 2 }
        end

        describe 'models are enumerable!' do
          When(:result) { Marvel::SuperHero.map(&:special_powers).flatten }
          Then { result == %w[ flying smash stuff ] }
        end
      end

    end

    describe 'instance methods' do
      describe '#{{property}}' do
        Then { hero.id             == id }
        Then { hero.real_name      == name }
        Then { hero.special_powers == powers }
      end

      describe '#{{boolean}}?' do
        When(:villain) { Marvel::Villain.new 'Lizard Man', really_evil?: false }
        describe 'has an accessor (ends with "?")' do
          Then { expect(villain).to respond_to(:really_evil?) }
          Then { expect(villain).to_not be_really_evil }
        end

        describe 'also has a setter (ends with "=")' do
          Then { expect(villain).to respond_to(:really_evil=) }
          When { villain.really_evil = true }
          Then { expect(villain).to be_really_evil }
        end
      end

      describe '#save' do
        When { hero.save }
        When(:frozen_hero) { Marshal.restore storage.values.first }
        Then { storage.keys.first    == 'Captain America' }
        Then { frozen_hero.real_name == 'Steve Rogers' }
        Then { frozen_hero.class     == Marvel::SuperHero }
      end

      describe '#to_h' do
        Given(:hero1) { test_class.new id, real_name: name, special_powers: powers }
        context 'default key name' do
          Given(:expected_hash) { { id: id, real_name: name, special_powers: powers } }
          When(:result) { hero1.to_h }
          Then { expect(result).to eq(expected_hash) }
        end

        context 'custom key name' do
          Given(:expected_hash) { { hero: id, real_name: name, special_powers: powers } }
          When(:result) { hero1.to_h(:hero) }
          Then { expect(result).to eq(expected_hash) }
        end
      end

      describe '#==' do
        Given(:hero1) { test_class.new id, real_name: name, special_powers: powers }
        Given(:hero2) { test_class.new id, real_name: name, special_powers: powers }

        context 'when they are equal' do
          Then { hero1 == hero2 }
        end

        context 'when some property(ies) are not equal' do
          Given { hero2.real_name = 'Steven Rogers' }
          Then  { hero1 != hero2 }
        end
      end

      describe '#[]' do
        context 'valid key' do
          Then { expect(hero[:real_name]).to eq(name) }
        end

        context 'key which is not a property' do
          Then { expect(hero[:insurance_company]).to be_nil }
        end

        context 'boolean properties' do
          When(:villain) { Marvel::Villain.new 'Lizard Man', really_evil?: true }
          Then { expect(villain[:really_evil?]).to eq(true) }
          Then { expect(villain[:really_evil]).to eq(true) }
        end
      end

      describe '#[]=' do
        context 'valid property' do
          When { hero[:real_name] = 'Bruce Banner' }
          Then { expect(hero.real_name).to eq('Bruce Banner') }
        end

        context 'key which is not a property' do
          Then { expect { hero[:ip_address] = '127.0.0.1' }.to raise_error(ArgumentError) }
        end

        context 'boolean properties' do
          When(:villain) { Marvel::Villain.new 'Lizard Man', really_evil?: false }

          describe 'can be set using the symbol ending in "?"' do
            When { villain[:really_evil?] = true }
            Then { expect(villain).to be_really_evil }
          end

          describe 'can also be set using the variant without the "?"' do
            When { villain[:really_evil] = true }
            Then { expect(villain).to be_really_evil }
          end
        end
      end

      describe 'default values' do
        Given do
          class Marvel::SuperHero < Squares::Base
            property :hair_color, default: 'black'
          end
        end
        When(:hero) { test_class.new id, real_name: name }

        Then { hero.special_powers == nil }
        Then { hero.hair_color == 'black' }
        Then { Marvel::SuperHero.defaults == { hair_color: 'black' } }
      end

    end

    describe 'instance properties' do
      When(:villain) { Marvel::Villain.new 'Dr. Octopus', vehicle: 'jets', lair: 'abandonned sewer' }

      describe "are the same as the Model's properties" do
        Then { villain.properties == Marvel::Villain.properties }
      end

      describe "don't bleed into other types" do
        Then { expect(villain).to_not respond_to(:real_name) }
      end
    end

  end
end

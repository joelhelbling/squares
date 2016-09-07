require_relative 'hooks'
require_relative 'collection_api'

module Squares
  class Base
    attr_accessor :id

    extend CollectionAPI
    extend Hooks

    def initialize *args
      build_instance(*args)
      trigger :after_initialize
    end

    def save
      trigger :before_save
      @_changed = false
      store[@id] = serialize
      trigger :after_save
      nil
    end

    def delete
      self.class.delete self.id
    end

    def destroy
      trigger :before_destroy
      delete
    end

    def == other
      @id == other.id && properties_equal(other)
    end

    def [](key)
      get_property key
    end

    def []=(key, value)
      set_property key, value
    end

    def update_properties new_properties
      new_properties.each do |key, value|
        self[key] = value if valid_property?(key)
      end
      save
    end
    alias_method :update_attributes, :update_properties

    def changed?
      @_changed
    end

    def properties
      self.class.properties
    end

    def to_json(key_name = :id)
      to_hash(key_name).to_json
    end

    def to_h(key_name = :id)
      { :type => self.class.name, key_name => id }.tap do |h|
        properties.each do |property|
          h[property] = self[property]
        end
      end
    end
    alias_method :to_hash, :to_h

    def valid_property? property
      self.class.valid_property? property
    end

    def defaults
      self.class.defaults
    end

    private

    def serialize
      serializers.inject(self.dup) do |memo, serializer|
        serializer.dump memo
      end
    end

    def serializers
      self.class.serializers
    end

    def properties_equal other
      ! properties.detect do |property|
        self.send(property) != other.send(property)
      end
    end

    def build_instance *args
      @id, values = *args
      values_hash = values.to_h
      properties_sorted_by_defaults.each do |property|
        value = values_hash.has_key?(property) ? values_hash[property] : default_for(property)
        set_property property, value
      end
    end

    def properties_sorted_by_defaults
      (properties || []).sort do |a,b|
        a_val = defaults[a].respond_to?(:call) ? 1 : 0
        b_val = defaults[b].respond_to?(:call) ? 1 : 0
        a_val <=> b_val
      end
    end

    def default_for property
      defaults[property].respond_to?(:call) ?
        defaults[property].call(self) :
        defaults[property]
    end

    def get_property property
      instance_variable_get "@#{instance_var_string_for property}"
    end

    def set_property property, value
      unless valid_property?(property)
        raise ArgumentError.new("\"#{property}\" is not a valid property of #{self.class}")
      end
      instance_variable_set("@#{instance_var_string_for property}", value).tap do
        @_changed = true
      end
    end

    def instance_var_string_for property
      property = self.class.normalize_property property
      if property.to_s.match(/\?$/)
        "#{property.to_s.gsub(/\?$/,'')}__question__".to_sym
      else
        property
      end
    end

    def store
      self.class.store
    end

  end
end


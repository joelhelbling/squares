module Squares
  class Base
    attr_accessor :id

    def initialize *args
      apply *args
    end

    def save
      store[@id] = Marshal.dump self
      nil
    end

    def == other
      @id == other.id && properties_equal(other)
    end

    def properties
      self.class.properties
    end

    private

    def properties_equal other
      ! properties.detect do |property|
        self.send(property) != other.send(property)
      end
    end

    def apply *args
      @id, value_hash = *args
      self.class.properties.each do |property|
        value = args.last.to_h[property] || self.class.defaults[property]
        # self.class.method_for(property)
        self.send "#{property.to_s.gsub(/\?$/,'')}=".to_sym, value
      end
    end

    def store
      self.class.store
    end

    #############
    class << self
      include Enumerable

      def [] id
        if item = store[id]
          Marshal.restore item
        end
      end
      alias_method :find, :[]

      def []= *args
        id, instance = *args
        if instance.class == self
          instance.id = id
        elsif instance.respond_to?(:to_h)
          instance = self.new(id, instance)
        else
          raise ArgumentError.new(<<-ERR)
          You must provide an instance of #{self.name} or at least
          something which responds to #to_h"
          ERR
        end
        instance.tap { |i| i.save }
      end
      alias_method :create, :[]=

      def has_key? key
        store.has_key? key
      end
      alias_method :key?,      :has_key?
      alias_method :member?,   :has_key?
      alias_method :includes?, :has_key?

      def keys
        store.keys
      end

      def values
        store.values
      end

      def delete id
        store.delete id
      end

      def each &block
        store.values.map{ |i| Marshal.restore i }.each &block
      end
      alias_method :where, :select

      def property prop, opts
        @_properties ||= []
        @_properties << prop
        uniquify_properties
        if prop.to_s.match(/\?$/)
          define_method prop do
            instance_variable_get "@#{self.class.instance_var_for prop}"
          end
          define_method prop.to_s.gsub(/\?$/, '=') do |v|
            instance_variable_set "@#{self.class.instance_var_for prop}", v
          end
        else
          attr_accessor prop
        end
        if default = opts[:default]
          defaults[prop] = default
        end
      end

      def properties *props
        props.each do |prop|
          property prop, {}
        end
        @_properties
      end

      def defaults
        @_defaults ||= {}
      end

      def underscore_name
        self.name.
          gsub(/::/, '/').
          gsub(/([^\/])([A-Z])/, '\1_\2').
          downcase
      end

      def store= storage
        @store = storage
      end

      def store
        @store ||= {}
      end

      def instance_var_for property
        if property.to_s.match(/\?$/)
          "#{property.to_s.gsub(/\?$/,'')}__question__".to_sym
        else
          property
        end
      end

      def models
        @_models.uniq.sort { |a,b| a.to_s <=> b.to_s }
      end

      private

      def uniquify_properties
        @_properties = @_properties.uniq.compact
      end

      def inherited(subclass)
        @_models ||= []
        @_models << subclass
      end

    end
  end
end


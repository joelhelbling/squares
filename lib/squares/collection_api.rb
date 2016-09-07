module Squares
  module CollectionAPI

    def self.extended(base)
      base.extend ClassMethods
    end

    module ClassMethods
      include Enumerable

      alias_method :all, :to_a

      def last
        to_a.last
      end

      def serializers
        # someday this will be extensible
        [Marshal]
      end

      def [] id
        if item = store[id]
          deserialize(item).tap do |it|
            it.instance_eval 'trigger :after_find'
          end
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
        instance.tap do |i|
          i.instance_eval 'trigger :before_create'
          i.save
          i.instance_eval 'trigger :after_create'
        end
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
        store.values.map{ |i| deserialize i }
      end

      def valid_property? property
        !!normalize_property(property)
      end

      def normalize_property property
        unless properties.include?(property)
          property = "#{property}?".to_sym if properties.include?("#{property}?".to_sym)
        end
        properties.include?(property) && property
      end

      def delete id
        store.delete id
      end

      def each &block
        values.each(&block)
      end

      def where(*args, &block)
        result_set = []
        if block
          result_set = values.select(&block)
          return result_set if result_set.empty?
        end

        args.each do |arg|
          if arg.kind_of?(Hash)
            result_set = (!result_set.empty? ? result_set : values).reject do |i|
              failed_matches = 0
              arg.each do |k,v|
                raise ArgumentError.new("\"#{k}\" is not a valid property of #{self}") unless valid_property?(k)
                failed_matches += 1 unless i[k] == v
              end
              failed_matches > 0
            end
          elsif arg.kind_of?(Symbol)
            raise ArgumentError.new("\"#{arg}\" is not a valid property of #{self}") unless valid_property?(arg)
            result_set = (result_set.empty? ? values : result_set).select do |i|
              i[arg]
            end
          end
        end
        result_set
      end

      def property prop, opts={}
        @_properties ||= []
        @_properties << prop
        uniquify_properties
        define_method prop do
          get_property prop
        end
        define_method "#{prop.to_s.gsub(/\?$/, '')}=" do |v|
          set_property prop, v
        end
        if opts.has_key?(:default)
          defaults[prop] = opts[:default]
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
        @_store = storage
      end

      def store
        @_store ||= {}
      end

      private

      def uniquify_properties
        @_properties = @_properties.uniq.compact
      end

      def inherited(subclass)
        Squares.add_model subclass
      end

      def deserialize item
        serializers.reverse.inject(item) do |memo, serializer|
          serializer.restore memo
        end
      end

    end
  end
end

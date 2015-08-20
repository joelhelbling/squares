module Squares
  class Base
    attr_accessor :id

    def initialize *args
      build_instance *args
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

    def to_h(key_name = :id)
      h = { key_name => id }
      properties.each do |property|
        h[property] = self.send(property)
      end
      h
    end

    def valid_property? property
      self.class.valid_property? property
    end

    def defaults
      self.class.defaults
    end

    def serialize
      serializers.inject(self.dup) do |memo, serializer|
        serializer.dump memo
      end
    end

    private

    def serializers
      self.class.serializers
    end

    def trigger hook_name
      return if @hook_callback_in_progress
      hooks = self.class.hooks
      if hooks && hooks[hook_name]
        hooks[hook_name].each do |hook|
          @hook_callback_in_progress = true
          self.instance_eval &hook
          @hook_callback_in_progress = false
        end
      end
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
      instance_variable_set("@#{instance_var_string_for property}", value).tap do |value|
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

    #############
    class << self
      include Enumerable

      def serializers
        [Marshal]
      end

      def [] id
        if item = store[id]
          deserialize(item).tap do |item|
            item.instance_eval 'trigger :after_find'
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
        values.each &block
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
        @store = storage
      end

      def store
        @store ||= {}
      end

      def models
        @_models.uniq.sort { |a,b| a.to_s <=> b.to_s }
      end

      ### hooks
      def hooks
        @_hooks
      end

      def before_create *args, &block
        add_hook :before_create, args, block
      end

      def after_create *args, &block
        add_hook :after_create, args, block
      end

      def after_initialize *args, &block
        add_hook :after_initialize, args, block
      end

      def after_find *args, &block
        add_hook :after_find, args, block
      end

      def before_save *args, &block
        add_hook :before_save, args, block
      end

      def after_save *args, &block
        add_hook :after_save, args, block
      end

      def before_destroy *args, &block
        add_hook :before_destroy, args, block
      end

      ### /hooks

      private

      def add_hook hook_id, args, block
        @_hooks ||= {}
        @_hooks[hook_id] ||= []
        @_hooks[hook_id] << block
      end

      def uniquify_properties
        @_properties = @_properties.uniq.compact
      end

      def inherited(subclass)
        @_models ||= []
        @_models << subclass
      end

      def deserialize item
        serializers.reverse.inject(item) do |memo, serializer|
          serializer.restore item
        end
      end

    end
  end
end


module Squares
  module Hooks

    # include it, extend, it whatever.  I'll admit I did this because
    # I desperately wanted to write `extend Hooks` in my base class.
    # But at the same time, I think `include` is more familiar to 
    # more developers...

    def self.included(base)
      brang_it base
    end

    def self.extended(base)
      brang_it base
    end

    def self.brang_it(base)
      base.include InstanceMethods
      base.extend ClassMethods
    end

    module InstanceMethods
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
    end

    module ClassMethods
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

      private

      def add_hook hook_id, args, block
        @_hooks ||= {}
        @_hooks[hook_id] ||= []
        @_hooks[hook_id] << block
      end
    end # ClassMethods

  end
end

# frozen_string_literal: true

module Cachi
  module LimitedFifo
    DEFAULT_CACHE_SIZE = 1000
    DEFAULT_KEEP_HOT = false

    def self.included(base)
      base.extend ClassMethods

      base.class_eval do
        @fifo_cache_size = DEFAULT_CACHE_SIZE
        @keep_cache_hot = DEFAULT_KEEP_HOT

        def fill(_key)
          raise NotImplementedError, 'You have to define a method :fill(key)'
        end
      end
    end

    def [](key)
      if already_cached?(key)
        reorder_index(key) if keep_cache_hot?
        return cache_data[key]
      end

      value = cache_data[key] = fill(key)
      cache_index.prepend(key)

      cache_data.delete(cache_index.pop) if cache_size_exceeded?

      value
    end

    private

    def already_cached?(key)
      cache_data.keys.include?(key)
    end

    def keep_cache_hot?
      self.class.keep_hot_enabled?
    end

    def cache_size_exceeded?
      cache_index.size > self.class.fifo_cache_size
    end

    def reorder_index(key)
      cache_index.delete(key)
      cache_index.prepend(key)
    end

    def cache_data
      @cache_data ||= {}
    end

    def cache_index
      @cache_index ||= []
    end

    module ClassMethods
      def cache_size(size)
        @fifo_cache_size = size
      end

      def keep_it_hot(flag)
        @keep_cache_hot = flag
      end

      def fifo_cache_size
        @fifo_cache_size
      end

      def keep_hot_enabled?
        @keep_cache_hot
      end
    end
  end
end

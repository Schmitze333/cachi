# frozen_string_literal: true

require 'cachi/limited_fifo'

RSpec.describe Cachi::LimitedFifo do
  subject(:cache) { cache_class.new(fill_spy) }

  let(:fill_spy) { spy('fill_spy') }
  let(:cache_class) do
    Class.new do
      include Cachi::LimitedFifo
      cache_size 2
      keep_it_hot false

      def initialize(fill_spy)
        @fill_spy = fill_spy
      end

      def spy_cache_index
        cache_index
      end

      def spy_cache_data
        cache_data
      end

      def fill(key)
        @fill_spy.fill(key)
        { a: 123, b: 234, c: 345 }.fetch(key, nil)
      end
    end
  end

  it 'raises an error when the cache does not implement :fill method' do
    cache = Class.new { include Cachi::LimitedFifo }.new

    expect { cache[:key] }.to raise_error(
      NotImplementedError,
      'You have to define a method :fill(key)'
    )
  end

  it 'returns the values provided by the fill method' do
    expect(cache[:a]).to eq 123
  end

  it 'does not fetch a value that is in cache' do
    cache[:a]

    expect(cache[:a]).to eq 123
    expect(fill_spy).to have_received(:fill).with(:a).exactly(1).times
  end

  it 'deletes the oldest key/value from the cache when exceeding cache size' do
    cache[:a]
    cache[:b]
    cache[:c]

    expect(cache.spy_cache_index).to match_array(%i[c b])
    expect(cache.spy_cache_data).to eq({ b: 234, c: 345 })
  end

  it 'keeps the cache index in order when keep_it_hot is not enabled' do
    cache[:a]
    cache[:b]
    cache[:a]

    expect(cache.spy_cache_index).to eq(%i[b a])
  end

  context 'when keep_it_hot is enabled' do
    before { cache_class.keep_it_hot(true) }

    it 'reorders the cache index for cached values' do
      cache[:a]
      cache[:b]
      cache[:a]

      expect(cache.spy_cache_index).to eq(%i[a b])
    end
  end

  context 'when not configured explicitly' do
    let(:cache_class) do
      Class.new do
        include Cachi::LimitedFifo

        def initialize(_spy); end

        def fill(_key)
          :value
        end
      end
    end

    it 'has a default cache size of 1000' do
      expect(cache.class.fifo_cache_size).to eq 1000
    end

    it 'has keep_it_hot option turned off by default' do
      expect(cache.class.keep_hot_enabled?).to eq false
    end
  end
end

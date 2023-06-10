# frozen_string_literal: true

# Extension for arrays and other enumerables. It provides convenient and
# reusable functionality to manipulate and analyze enumerable objects in
# a concise and expressive manner.


module Hamachi
  module EnumerableExt
    def index_by
      raise unless block_given?

      index = Hash.new
      self.each { |each| index[yield each] = each }
      index
    end

    def freq
      h = Hash.new(0)
      if block_given?
        each { |each| h[yield each] += 1 }
      else
        each { |each| h[each] += 1 }
      end
      h.sort_by(&:last).to_h
    end

    def where(patterns)
      each.select { |each| patterns.all? { |symbol, pattern| pattern === each.send(symbol) }}
    end

    def wherent(patterns)
      each.reject { |each| patterns.all? { |symbol, pattern| pattern === each.send(symbol) }}
    end
  end
end

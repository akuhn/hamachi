# frozen_string_literal: true


module Hamachi

  class Field
    def initialize(type)
      @type = type
    end

    def initialize_options(options)
    end

    def ===(value)
      @type === value
    end

    def default_value
      nil
    end

    def to_s
      @type.to_s
    end

    def from_snapshot(data, options = nil)
      if @type == Symbol
        data.to_sym if data
      elsif Class === @type && @type.respond_to?(:from_snapshot)
        @type.from_snapshot(data, options)
      else
        data
      end
    end
  end

  class EnumField < Field
    def initialize(*symbols)
      super symbols
    end

    def ===(value)
      @type.any? { |each| each === value }
    end

    def to_s
      "enum(#{@type.map(&:inspect).join(?,)})"
    end

    def from_snapshot(data, options)
      String === data ? data.to_sym : data
    end
  end

  class ListField < Field
    def initialize_options(options)
      @option_empty = options.fetch(:empty, true)
    end

    def ===(value)
      return false unless Array === value
      return false if value.empty? unless @option_empty
      value.all? { |each| @type === each }
    end

    def default_value
      []
    end

    def to_s
      "list(#{@type}#{', empty: false' unless @option_empty})"
    end

    def from_snapshot(data, options)
      data && data.map { |each| super(each, options) }
    end
  end

  class NullableField < Field
    def ===(value)
      @type === value || value.nil?
    end

    def to_s
      "nullable(#{@type})"
    end
  end
end

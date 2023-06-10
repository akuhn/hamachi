# frozen_string_literal: true

require 'json'


module Hamachi
  class Model < Hash

    # ------- schema declaration ---------------------------------------

    def self.fields
      @fields ||= {}
    end

    def self.field(name, options)
      raise ArgumentError, "method ##{name} already defined" if method_defined?(name)
      raise ArgumentError, "method ##{name}= already defined" if method_defined?("#{name}=")

      field = options.fetch(:type)
      field = Field.new(field) unless Field === field
      field.initialize_options(options).freeze
      self.fields[name.to_sym] = field

      class_eval %{
        def #{name}
          self[:#{name}]
        end
      }

      class_eval %{
        def #{name}=(value)
          field = self.class.fields[:#{name}]
          if not field === value
            raise "expected #{name} to be \#{field}, got \#{value.inspect}"
          end
          self[:#{name}] = value
        end
      }

      return self
    end

    def self.schema(&block) # for anonymous inline models
      Class.new Hamachi::Model, &block
    end

    def self.to_s
      name ? name : "schema(#{fields.map { |name, field| "#{name}:#{field}"}.join(',')})"
    end

    def self.register_type(name, field_class)
      singleton_class.send(:define_method, name) do |*args|
        field_class.new(*args)
      end
    end

    register_type :list, ListField
    register_type :nullable, NullableField
    register_type :enum, EnumField

    Boolean = enum(true, false)


    # ------- initialization -------------------------------------------

    def initialize(snapshot, options = {})
      update(snapshot) if options.fetch(:include_unknown_fields, true)

      self.class.fields.each do |name, field|
        value = snapshot.fetch(name, field.default_value)
        self[name] = field.from_snapshot(value, options)
      end

      check_types if options.fetch(:check_types, true)
      freeze if options.fetch(:freeze, false)
    end

    def self.from_snapshot(snapshot, options = {})
      return snapshot unless Hash === snapshot
      self.new snapshot, options
    end

    def self.parse(string, options = {})
      snapshot = JSON.parse(string, symbolize_names: true)
      if Array === snapshot
        snapshot.map { |each| from_snapshot each, options }
      else
        from_snapshot snapshot, options
      end
    end


    # ------- validation -----------------------------------------------

    # TODO: consider implementing an enumeration over the error messages,
    # also consider nested field names, eg address.street

    def check_types
      self.class.fields.each do |name, field|
        if not field === self[name]
          raise "expected #{name} to be #{field}, got #{self[name].inspect}"
        end
      end
    end
  end
end

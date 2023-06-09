require 'json'
require 'hamachi/matcher'

# A model has type-checked fields.
#
# This class can be used to create a flexible and type-safe representation of
# JSON data. It provides a convenient way to create and validate data models
# in Ruby, making it easier to build complex applications.
#
# The Model class extends the built-in Hash class and is designed to enforce
# type constraints on data objects that can be created from JSON snapshots. It
# defines custom syntax for declaring and validating fields, with support for
# common data types suchs enums, lists, and nullable types.
#
# Example usage
#
#   class Person < Model
#     field %{name}, type: String
#     field %{gender}, type: (enum :male, :female)
#     field %{age}, type: 1..100
#   end
#
#   anna = Person.new(
#     name: 'Anna',
#     gender: :female,
#     age: 29,
#   )
#
# Type checking in the Model framework is based on a combination of built-in
# Ruby functionality and custom matchers that are optimized for working with
# complex data structures.
#
# - The framework relies on the === operator, which is a built-in method in
#   Ruby that checks whether a given value is a member of a class or matches
#   a pattern, such as a regular-expression or a range of numbers
# - In addition the framework provides a set of custom matchers that are
#   optimized for working with more complex data structures. These matchers
#   include support for lists, nullable types, enumerations, and more.
#
# Another way to extend the type checking capabilities is by subclassing the
# Matcher class. This allows developers to create custom matchers that can
# validate complex data structures or enforce domain-specific rules on the
# values of fields in a model. This provides a powerful extension point that
# allows developers to meet the needs of their specific use cases, and can
# help ensure data quality and consistency in their applications.
#
# Customizing serialization is an important aspect of working with data models,
# and the Model framework provides a flexible way to achieve this through the
# to_json and from_snapshot methods. These methods allow developers to control
# how data is represented in JSON format, which can be important ensure that
# the serialized data is compatible with external systems or APIs.
#
# In summary, the Model framework provides a powerful and flexible way to
# define and enforce the structure of data models in a Ruby application, and
# offers a variety of extension points for customizing the behavior of the
# framework to meet the needs of specific use cases.
#
# Hackety hacking, frens!
#
#

module Hamachi
  class Model < Hash

    # ------- declaration ----------------------------------------------

    def self.fields
      @fields ||= {}
    end

    def self.field(name, options)
      raise ArgumentError, "method #{name} already defined" if method_defined?(name)
      raise ArgumentError, "method #{name}= already defined" if method_defined?("#{name}=")

      field = options.fetch(:type)
      field = Matcher.new(field) unless Matcher === field
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

    def self.to_s
      name ? name : "model(#{fields.map { |name, field| "#{name}:#{field}"}.join(',')})"
    end

    def self.schema(&block) # for anonymous inline models
      Class.new Hamachi::Model, &block
    end

    def self.register_matcher(name, matcher_class)
      singleton_class.define_method name do |arg, *args|
        matcher_class.new(arg, *args)
      end
    end

    register_matcher :list, ListMatcher
    register_matcher :nullable, NullableMatcher
    register_matcher :enum, EnumMatcher

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

    # TODO: consider implementing parse function that reads from file or
    # string, also consider options to read array or object or both?


    # ------- validation -----------------------------------------------

    def check_types
      self.class.fields.each do |name, field|
        if not field === self[name]
          raise "expected #{name} to be #{field}, got #{self[name].inspect}"
        end
      end
    end

    # TODO: consider implementing an enumeration over the error messages,
    # also consider nested field names, eg address.street


    # ------- helper methods -------------------------------------------

    def prune_default_values
      self.class.fields.each do |name, field|
        case value = self[name]
        when field.default_value
          self.delete(name)
        when Model
          value.prune_default_values
        when Array
          value.each { |each| each.prune_default_values if Model === each }
        end
      end

      return self
    end
  end
end

# Hamachi

Hamachi is a Ruby library designed to simplify the creation and manipulation of domain-specific data models, supporting type checking, data validation, and JSON deserialization. This library takes advantage of Ruby's dynamic nature, providing a fluent and intuitive interface to define domain models.

## Features

- Dynamic model creation with a flexible field declaration syntax.
- Type checking and enforcement to ensure model validity.
- Simple JSON to Model deserialization.
- Easy access to model data using accessor methods.
- Nullability, enumerations, lists, and other constraints.
- Custom model matching classes for extending the library's capabilities.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'hamachi'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install hamachi

## Usage

Here is a basic usage example:

```ruby
require 'hamachi'

class User < Hamachi::Model
  field :name, type: String
  field :age, type: 1..100
end

user = User.from_json('{"name": "Alice", "age": 30}')
user = User.new(name: "Alice", age: 30)

user.name = 'Bob'
user.age = 120 # => raises RuntimeError: expected age to be 1..100, got 120
```

You can define the following types of fields:

- Basic types (e.g. `String`, `Integer`, `Float`, `Symbol`, `Boolean`)
- Enumerations (e.g. `enum(:admin, :user, :guest)`)
- Lists of certain type (e.g. `list(String)`, `list(User)`)
- Nullable fields (e.g. `nullable(String)`, `nullable(User)`)
- Positive value fields (e.g. `positive(Integer)`, `positive(Float)`)
- Regular expressions (e.g. `/\A\d\d\d\d-\d\d-\d\d\z/` for matching dates)
- Ranges (e.g. `1..100` for matching integers between 1 and 100)

More complex nested models can be created:

```ruby
class Post < Hamachi::Model
  field :title, type: String
  field :content, type: String
  field :created_at, type: Timestamp
  field :tags, type: list(String)
end

class User < Hamachi::Model
  field :name, type: String
  field :friends, type: list(User)
  field :posts, type: list(Post)
end
```

## Notes

A model has type-checked fields.

This class can be used to create a flexible and type-safe representation of
JSON data. It provides a convenient way to create and validate data models
in Ruby, making it easier to build complex applications.

The Model class extends the built-in Hash class and is designed to enforce
type constraints on data objects that can be created from JSON snapshots. It
defines custom syntax for declaring and validating fields, with support for
common data types suchs enums, lists, and nullable types.

Example usage

    class Person < Model
      field %{name}, type: String
      field %{gender}, type: (enum :male, :female)
      field %{age}, type: 1..100
    end

    anna = Person.new(
      name: 'Anna',
      gender: :female,
      age: 29,
    )

Type checking in the Model framework is based on a combination of built-in
Ruby functionality and custom matchers that are optimized for working with
complex data structures.

- The framework relies on the === operator, which is a built-in method in
  Ruby that checks whether a given value is a member of a class or matches
  a pattern, such as a regular-expression or a range of numbers
- In addition the framework provides a set of custom matchers that are
  optimized for working with more complex data structures. These matchers
  include support for lists, nullable types, enumerations, and more.

Another way to extend the type checking capabilities is by subclassing the
Matcher class. This allows developers to create custom matchers that can
validate complex data structures or enforce domain-specific rules on the
values of fields in a model. This provides a powerful extension point that
allows developers to meet the needs of their specific use cases, and can
help ensure data quality and consistency in their applications.

Customizing serialization is an important aspect of working with data models,
and the Model framework provides a flexible way to achieve this through the
to_json and from_snapshot methods. These methods allow developers to control
how data is represented in JSON format, which can be important ensure that
the serialized data is compatible with external systems or APIs.

In summary, the Model framework provides a powerful and flexible way to
define and enforce the structure of data models in a Ruby application, and
offers a variety of extension points for customizing the behavior of the
framework to meet the needs of specific use cases.

Hackety hacking, frens!

## Contributing

Bug reports and pull requests are welcome on GitHub at [link to GitHub repo](https://github.com/akuhn/hamachi).  This project encourages collaboration and appreciates contributions. Feel free to contribute to the project by reporting bugs or submitting pull requests.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

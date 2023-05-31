# Hamachi

The Hamachi gem provides a flexible and type-safe representation of JSON data in Ruby. It allows you to define and validate data models with type-checked fields, making it easier to build complex applications.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'model'
```

And then execute:

```shell
$ bundle install
```

Or install it yourself as:

```shell
$ gem install model
```

## Usage

To use the Hamachi gem, you can define your own models by subclassing the `Model` class. Here's an example:

```ruby
require 'hamachi'

class Person < Hamachi::Model
  field :name, type: String
  field :gender, type: (enum :male, :female)
  field :age, type: 1..100

  def greeting
    "Hello, my name is #{name}!"
  end
end

person = Person.new(
  name: 'Anna',
  gender: :female,
  age: 29
)

person.name # => "Anna"
person.gender # => :female
person.age # => 29
person.age = 200 # => raises RuntimeError: expected age to be 1..100, got 200

snapshot = person.to_json
anna = Person.from_snapshot(snapshot)
```

In this example, we define a `Person` model with three fields: `name`, `gender`, and `age`. Each field has a specified type. You can create instances of the `Person` model by passing the field values as a hash to the `Person.new` method. The values are type-checked against the specified types.

You can also serialize and deserialize model instances to and from JSON using the `to_json` and `from_snapshot` methods.

## Type Checking

The Hamachi gem performs type checking based on the specified types of the fields. It uses the `===` operator and custom matchers to validate the values. If a value doesn't match the specified type, an error is raised.

The gem provides several built-in matchers for common types, such as enums, lists, and nullable types. You can also create custom matchers by subclassing the `Matcher` class.

## Customization

You can customize the behavior of the Hamachi gem by overriding methods or subclassing the `Matcher` class. This allows you to enforce domain-specific rules, validate complex data structures, or control the serialization process.

The gem provides extension points for defining custom matchers, such as `enum`, `list`, `nullable`, `model`, `positive`, and `positive_or_zero`. These matchers can be used to define more specific types or constraints for your fields.

## Contributing

Bug reports and pull requests are welcome on GitHub at [link to GitHub repo](https://github.com/yourusername/your-repo).  This project encourages collaboration and appreciates contributions. Feel free to contribute to the project by reporting bugs or submitting pull requests.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

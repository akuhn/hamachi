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

## Contributing

Bug reports and pull requests are welcome on GitHub at [link to GitHub repo](https://github.com/yourusername/your-repo).  This project encourages collaboration and appreciates contributions. Feel free to contribute to the project by reporting bugs or submitting pull requests.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

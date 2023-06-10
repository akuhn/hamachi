require 'json'


describe Hamachi::Model do

  let(:model) {
    Hamachi::Model.schema do
      field %{name}, type: String
      field %{gender}, type: enum(:male, :female)
      field %{age}, type: 1..100
    end
  }

  let(:anna) {
    model.new(
      name: 'Anna',
      gender: :female,
      age: 29,
    )
  }

  describe '.fields' do

    it 'returns all the fields defined in the model' do
      expect(model.fields.keys).to eq [:name, :gender, :age]
    end
  end

  describe '.field' do

    it 'generates read accessors' do
      expect(anna).to respond_to(:name)
      expect(anna).to respond_to(:gender)
      expect(anna).to respond_to(:age)
    end

    it 'generates write accessors' do
      expect(anna).to respond_to(:name=)
      expect(anna).to respond_to(:gender=)
      expect(anna).to respond_to(:age=)
    end

    it 'raises an error when reader method already defined' do
      expect {
        Hamachi::Model.schema do
          attr_reader :foo
          field :foo, type: Object
        end
      }.to raise_error 'method #foo already defined'
    end

    it 'raises an error when writer method already defined' do
      expect {
        Hamachi::Model.schema do
          attr_writer :foo
          field :foo, type: Object
        end
      }.to raise_error 'method #foo= already defined'
    end
  end

  describe 'field accessors' do

    it 'allows getting the value of a field' do
      expect(anna.name).to eq 'Anna'
      expect(anna.gender).to eq :female
      expect(anna.age).to eq 29
    end

    it 'allows setting the value of a field' do
      anna.name = 'Sophie'
      expect(anna.name).to eq 'Sophie'
    end

    it 'raises error when setting an invalid field value' do
      expect { anna.gender = :other }.to raise_error %r{expected gender .* got :other}
      expect(anna.gender).to eq :female
    end
  end

  describe '#initialize' do

    it 'creates a new model instance from hash with field values' do
      hash = { name: 'Anna', gender: :female, age: 29 }
      m = model.new(hash)
      expect(m).to eq hash
    end

    it 'raises error when hash includes an invalid field value' do
      expect {
        model.new(name: 'Anna', gender: :female, age: 9000)
      }.to raise_error %r{expected age .* got 9000}
    end

    it 'raises error when hash is missing a field' do
      expect {
        model.new(name: 'Anna', age: 29)
      }.to raise_error %r{expected gender .* got nil}
    end

    it 'defaults to including unknown fields' do
      hash = { name: 'Anna', gender: :female, age: 29, hobby: 'painting' }
      anna = model.new(hash)
      expect(anna[:hobby]).to eq 'painting'
    end

    it 'ignores unknown fields when option is disabled' do
      hash = { name: 'Anna', gender: :female, age: 29, hobby: 'painting' }
      anna = model.new(hash, include_unknown_fields: false)
      expect(anna[:hobby]).to be_nil
    end

    it 'does not validate fields when option is disabled' do
      hash = { name: 'Anna', gender: :female, age: 9000 }
      expect {
        model.new(hash, validate_fields: false)
      }.not_to raise_error
    end

    it 'creates a new model instance that is immutable when option is enabled' do
      hash = { name: 'Anna', gender: :female, age: 29 }
      anna = model.new(hash, freeze: true)
      expect { anna.name = 'Sophie' }.to raise_error %r{can't modify frozen}
    end
  end

  describe '#valid?' do

    it 'returns true when fields match their type' do
      expect(anna.valid?).to be true
    end

    it 'returns false when fields are missing' do
      anna.delete(:gender)
      expect(anna.valid?).to be_falsy
    end

    it 'returns false when fields do not match their type' do
      anna[:age] = 9000
      expect(anna.valid?).to be_falsy
    end
  end

  describe '#validate_fields!' do

    it 'does not raise error when fields match their type' do
      expect { anna.validate_fields! }.to_not raise_error
    end

    it 'raises error when fields are missing' do
      expect {
        anna.delete(:gender)
        anna.validate_fields!
      }.to raise_error 'expected gender to be enum(:male,:female), got nil'
    end

    it 'raises error when fields do not match their type' do
      expect {
        anna[:age] = 9000
        anna.validate_fields!
      }.to raise_error 'expected age to be 1..100, got 9000'
    end
  end

  describe '#error_messages' do

    it 'is empty when fields match their type' do
      expect(anna.error_messages).to be_empty
    end

    it 'includes all validation errors when fields are invalid' do
      anna.delete(:gender)
      anna[:age] = 9000
      expect(anna.error_messages).to match_array [%r{expected gender}, %r{expected age}]
    end
  end

  describe '.parse' do

    it 'reads model instance from a JSON object' do
      json = '{"name":"Anna","gender":"female","age":29}'
      expect(model.parse json).to eq anna
    end

    it 'reads array of model instances from JSON array' do
      people = model.parse %{[
        {"name":"Anna","gender":"female","age":29},
        {"name":"Sophie","gender":"female","age":32},
        {"name":"Bob","gender":"male","age":45}
      ]}
      expect(people).to be_kind_of Array
      expect(people.first).to be_kind_of model
      expect(people.map(&:name)).to eq %w{Anna Sophie Bob}
    end

    it 'accepts JSON string as value for symbol field' do
      model = Hamachi::Model.schema do
        field :example, type: Symbol
      end

      m = model.parse('{"example":"foo"}')
      expect(m.example).to eq :foo
    end

    it 'accepts JSON string as value for enum field' do
      model = Hamachi::Model.schema do
        field :example, type: enum(:foo, :bar)
      end

      m = model.parse('{"example":"foo"}')
      expect(m.example).to eq :foo
    end

    it 'raises an error when snapshot includes invalid field' do
      json = '{"name":"Anna","gender":"female","age":9000}'
      expect { model.parse json }.to raise_error %r{expected age .* got 9000}
    end

    it 'raises an error when snapshot includes missing field' do
      json = '{"name":"Anna","age":9000}'
      expect { model.parse json }.to raise_error %r{expected gender .* got nil}
    end
  end

  describe '.from_snapshot' do

    it 'raises error when JSON was parsed without symbolize_names=true' do
      expect {
        snapshot = JSON.parse '{"name":"Anna","gender":"female","age":29}'
        model.from_snapshot snapshot
      }.to raise_error 'expected name to be String, got nil'
    end
  end

  describe 'JSON.dump' do

    it 'generates snapshot of the model' do
      expect(JSON.dump anna).to eq '{"name":"Anna","gender":"female","age":29}'
    end
  end

  describe 'when field is a list' do

    let(:model) {
      Hamachi::Model.schema do
        field %{sequence}, type: (list Integer)
      end
    }

    it 'initializes list of values' do
      m = model.new(sequence: [4,7,3])
      expect(m.sequence).to eq [4,7,3]
    end

    it 'should initialize to default value' do
      m = model.new({})
      expect(m.sequence).to eq []
    end

    it 'should use default value when missing from snapshot' do
      m = model.from_snapshot(JSON.parse '{}')
      expect(m.sequence).to eq []
    end

    it 'should raise error unless all elements match' do
      m = model.new({})
      expect {
        m.sequence = [1, Object.new, 3, 4, 5]
      }.to raise_error(/expected .* list/)
    end

    it 'should raise error when empty list is passed to non-empty field' do
      model = Hamachi::Model.schema do
        field %{sequence}, type: (list Integer), empty: false
      end
      expect {
        model.new(sequence: [])
      }.to raise_error(/expected .* to be .* empty: false/)
    end
  end

  describe 'with custom type matcher' do

    let(:matcher) {
      Class.new Hamachi::Field do
        def ===(value)
          @type === value && value.odd?
        end

        def default_value
          1
        end

        def to_s
          "odd number"
        end
      end
    }

    let(:model) {
      odd_number = matcher.new(Integer)
      Hamachi::Model.schema { field %{num}, type: odd_number }
    }

    it 'initializes value' do
      m = model.new(num: 17)
      expect(m.num).to eq 17
    end

    it 'should use default value when field missing upon initialize' do
      m = model.new({})
      expect(m.num).to eq 1
    end

    it 'should use default value when field missing from snapshot' do
      m = model.parse '{}'
      expect(m.num).to eq 1
    end

    it 'should check type upon initialize' do
      m = model.new(num: 23)
      expect(m.num).to eq 23
      expect { model.new(num: 42) }.to raise_error(/expected .* odd number/)
    end

    it 'should check type upon reading from snapshot' do
      m = model.parse '{"num":23}'
      expect(m.num).to eq 23
      expect { model.parse '{"num":42}' }.to raise_error(/expected .* odd number/)
    end

    it 'should check type upon setting attribute' do
      m = model.new({})
      m.num = 23
      expect(m.num).to eq 23
      expect { m.num = 42 }.to raise_error(/expected .* odd number/)
    end

    it 'fails when setting attribute to nil value' do
      m = model.new({})
      expect { m.num = nil }.to raise_error(/expected .* odd number/)
    end

    it 'fails when initializing to nil value' do
      expect { model.new({num: nil}) }.to raise_error(/expected .* odd number/)
    end

    it 'fails when reading nil value from snapshot' do
      expect { model.parse '{"num":null}' }.to raise_error(/expected .* odd number/)
    end

    it 'supports nested matchers' do
      odd_number = matcher.new(Numeric)
      model = Hamachi::Model.schema { field %{seq}, type: (list odd_number) }
      expect { model.new(seq: [3,5,7]) }.to_not raise_error
      expect { model.new(seq: [1,2,3]) }.to raise_error(/expected .* list\(odd number\)/)
    end
  end

  describe 'when fields are models (complex data structure)' do

    let(:model) {
      Hamachi::Model.schema do
        field %{name}, type: String
        field %{address}, type: (schema {
          field %{street}, type: String
          field %{city}, type: String
        })
        field %{items}, type: (list schema {
          field %{name}, type: String
          field %{price}, type: Float
        })
      end
    }

    let(:annas_order) {
      %{{
        "name": "Anna",
        "address": {
          "street": "834 Oak Street",
          "city": "Roseville"
        },
        "items": [
          { "name": "Handmade Linen Apron", "price": 45.00 },
          { "name": "Mason Jar Measuring Cups", "price": 24.99 },
          { "name": "Wildflower Seeds", "price": 12.99 }
        ]
      }}
    }

    it 'should read valid instance from snapshot' do
      m = model.parse annas_order
      expect { model.new m }.to_not raise_error
    end

    it 'should read has-one model field from snapshot' do
      m = model.parse annas_order
      expect(m.address).to be_a Hamachi::Model
      expect(m.address.street).to eq '834 Oak Street'
      expect(m.address.city).to eq 'Roseville'
    end

    it 'should read has-many model field from snapshot' do
      m = model.parse annas_order
      expect(m.items).to all be_a Hamachi::Model
      expect(m.items.length).to eq 3
      expect(m.items.sum(&:price)).to eq 82.98 if RUBY_VERSION > '2.0.0'
    end

    it 'should serialize-and-back using JSON format' do
      m = model.parse annas_order
      json_string = (JSON.dump m)
      expect(model.parse json_string).to eq m
    end

    it 'anonymous model prints human-readable representation' do
      type = model.fields[:address]
      expect(type.to_s).to eq 'schema(street:String,city:String)'
    end

    it 'constructor should accept nested hashes' do
      annas_order_as_hash = JSON.parse annas_order, symbolize_names: true
      m = model.new annas_order_as_hash
      expect(m.address).to be_a Hamachi::Model
      expect(m.address.street).to eq '834 Oak Street'
      expect(m.address.city).to eq 'Roseville'
    end
  end

  describe 'with nullable field' do

    let(:model) {
      Hamachi::Model.schema do
        field :nickname, type: (nullable String)
      end
    }

    it 'accepts string value' do
      m = model.new(nickname: 'Nina')
      expect(m.nickname).to eq 'Nina'
    end

    it 'accepts nil value' do
      m = model.new(nickname: nil)
      expect(m.nickname).to be_nil
    end

    it 'accepts missing value' do
      m = model.new({})
      expect(m.nickname).to be_nil
    end

    it 'should raise error for non-string value' do
      expect {
        model.new(nickname: 23)
      }.to raise_error 'expected nickname to be nullable(String), got 23'
    end
  end
end


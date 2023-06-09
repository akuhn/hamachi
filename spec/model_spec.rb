require 'hamachi/model'
require 'json'


describe Hamachi::Model do

  describe 'with simple model' do

    let(:model) {
      Class.new(Hamachi::Model) do
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

    it 'has attribute acessors' do
      expect(anna).to respond_to(:name)
      expect(anna).to respond_to(:name=)
      expect(anna).to respond_to(:gender)
      expect(anna).to respond_to(:gender=)
      expect(anna).to respond_to(:age)
      expect(anna).to respond_to(:age=)
    end

    it 'should read fields' do
      expect(anna.name).to eq 'Anna'
      expect(anna.gender).to eq :female
      expect(anna.age).to eq 29
    end

    it 'should write fields' do
      anna.name = 'Sophie'
      expect(anna.name).to eq 'Sophie'
    end

    it 'raises error when setting an invalid field value' do
      expect { anna.gender = :other }.to raise_error(/expected gender to be .../)
      expect(anna.gender).to eq :female
    end

    it 'raises error when initializing to an invalid field value' do
      expect {
        model.new(name: 'Anna', gender: :female, age: 9000)
      }.to raise_error(/expected age to be .../)
    end

    it 'should not check types when the option is disabled' do
      expect {
        model.new(
        { name: 'Anna', gender: :female, age: 9000 },
          check_types: false,
        )
      }.not_to raise_error
    end

    it 'generates JSON snapshot of the model' do
      expect(JSON.dump anna).to eq '{"name":"Anna","gender":"female","age":29}'
    end

    it 'creates model instance from JSON snapshot' do
      json = '{"name":"Anna","gender":"female","age":29}'
      expect(model.parse json).to eq anna
    end

    it 'raises error when JSON snapshot was parsed without symbolize_names=true' do
      json = '{"name":"Anna","gender":"female","age":29}'
      snapshot = JSON.parse json # defaults to { symbolize_names: false } option
      expect { model.from_snapshot snapshot }.to raise_error 'expected name to be String, got nil'
    end

    it 'raises error when JSON snapshot includes invalid field' do
      json = '{"name":"Anna","gender":"female","age":9000}'
      expect { model.parse json }.to raise_error(/expected age to be .../)
    end

    it 'should allow undeclared fields by default' do
      anna = model.new(name: 'Anna', gender: :female, age: 29, hobby: 'painting')
      expect(anna[:hobby]).to eq 'painting'
    end

    it 'should not allow undeclared fields when the option is disabled' do
      anna = model.new(
        { name: 'Anna', gender: :female, age: 29, hobby: 'painting' },
        include_unknown_fields: false,
      )
      expect(anna[:hobby]).to be_nil
    end

    it 'should freeze the model when the option is enabled' do
      anna = model.new(
        { name: 'Anna', gender: :female, age: 29 },
        freeze: true,
      )
      expect { anna.name = 'Sophie' }.to raise_error(/can't modify frozen model/)
    end
  end

  describe 'when field is a list' do

    let(:model) {
      Hamachi::Model.schema do
        field %{sequence}, type: (list Integer)
      end
    }

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
      expect {
        model = Hamachi::Model.schema { field %{sequence}, type: (list Integer), empty: false }
        model.new({sequence: []})
      }.to raise_error(/expected .* to be .* empty: false/)
    end
  end

  describe 'with custom type matcher' do

    let(:matcher) {
      Class.new Hamachi::Matcher do
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
      odd_number = matcher.new(Numeric)
      Hamachi::Model.schema { field %{num}, type: odd_number }
    }

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
      expect(m.items.sum(&:price)).to eq 82.98
    end

    it 'should serialize-and-back using JSON format' do
      m = model.parse annas_order
      json = (JSON.dump m)
      expect(model.parse json).to eq m
    end

    it 'anonymous model prints human-readable representation' do
      type = model.fields[:address]
      expect(type.to_s).to eq 'model(street:String,city:String)'
    end

    it 'constructor should accept nested hashes' do
      annas_order_as_hash = JSON.parse annas_order, symbolize_names: true
      m = model.new annas_order_as_hash
      expect(m.address).to be_a Hamachi::Model
      expect(m.address.street).to eq '834 Oak Street'
      expect(m.address.city).to eq 'Roseville'
    end
  end
end


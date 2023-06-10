


describe Hamachi::Field do

  describe 'with String field' do

    let(:field) { Hamachi::Field.new String }

    it { expect(field === 'example').to be true }
    it { expect(field === :example).to be_falsy }
    it { expect(field === 40000).to be_falsy }
    it { expect(field === nil).to be_falsy }

    it { expect(field.to_s).to eq 'String' }
    it { expect(field.from_snapshot 'example').to eq 'example' }
    it { expect(field.default_value).to be_nil }
  end

  describe 'with Symbol field' do

    let(:field) { Hamachi::Field.new Symbol }

    it { expect(field === 'example').to be_falsy }
    it { expect(field === :example).to be true }
    it { expect(field === 40000).to be_falsy }
    it { expect(field === nil).to be_falsy }

    it { expect(field.to_s).to eq 'Symbol' }
    it { expect(field.from_snapshot 'example').to eq :example }
    it { expect(field.default_value).to be_nil }
  end
end

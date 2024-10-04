describe FactorySloth::CreateCallFinder, '::call' do
  it 'works for create calls on the main object' do
    expect(described_class.call(code: 'create')).to eq [
      FactorySloth::CreateCall.new(name: 'create', line: 1, column: 0),
    ]
  end

  it 'works for create_list' do
    expect(described_class.call(code: 'create_list')).to eq [
      FactorySloth::CreateCall.new(name: 'create_list', line: 1, column: 0),
    ]
  end

  it 'works for create_pair' do
    expect(described_class.call(code: 'create_pair')).to eq [
      FactorySloth::CreateCall.new(name: 'create_pair', line: 1, column: 0),
    ]
  end

  it 'works for calls on FactoryBot' do
    result = described_class.call(code: <<~RUBY)
      FactoryBot.create
      FactoryBot.create_list
    RUBY
    expect(result).to eq [
      FactorySloth::CreateCall.new(name: 'create',      line: 1, column: 11),
      FactorySloth::CreateCall.new(name: 'create_list', line: 2, column: 11),
    ]
  end

  it 'finds nested create calls' do
    result = described_class.call(code: 'create(foo: create(:bar))')
    expect(result.sort_by(&:column)).to eq [
      FactorySloth::CreateCall.new(name: 'create', line: 1, column: 0),
      FactorySloth::CreateCall.new(name: 'create', line: 1, column: 12),
    ]
  end

  it 'works at arbitrary code nesting depths' do
    result = described_class.call(code: <<~RUBY)
      describe('foo') do
        RSpec.context('bar') do
          it 'baz' do
            def my_helper
              my_proc = -> { FactoryBot.create(:user) }
            end
          end
        end
      end
    RUBY
    expect(result).to eq [
      FactorySloth::CreateCall.new(name: 'create', line: 5, column: 34),
    ]
  end

  it 'ignores unrelated create calls' do
    result = described_class.call(code: <<~RUBY)
      User.create
      self.create
      create!
      FactoryBot.create_factory
    RUBY
    expect(result).to eq []
  end

  it 'ignores create calls with a sloth:disable comment in the same line' do
    result = described_class.call(code: <<~RUBY)
      create(:foo)
      create(:foo) # sloth:disable
      create(:foo)
    RUBY
    expect(result).to eq [
      FactorySloth::CreateCall.new(name: 'create', line: 1, column: 0),
      FactorySloth::CreateCall.new(name: 'create', line: 3, column: 0),
    ]
  end

  it 'ignores create calls after a line-leading sloth:disable comment' do
    result = described_class.call(code: <<~RUBY)
      create(:foo)
      # sloth:disable
      create(:foo)
      create(:foo)
      # sloth:enable
      create(:foo)
    RUBY
    expect(result).to eq [
      FactorySloth::CreateCall.new(name: 'create', line: 1, column: 0),
      FactorySloth::CreateCall.new(name: 'create', line: 6, column: 0),
    ]
  end

  it 'ignores create calls where the result is assigned to an underscore-prefixed variable' do
    result = described_class.call(code: <<~RUBY)
      create(:foo)
      _thing = create(:foo)
      create(:foo)
    RUBY
    expect(result).to eq [
      FactorySloth::CreateCall.new(name: 'create', line: 1, column: 0),
      FactorySloth::CreateCall.new(name: 'create', line: 3, column: 0),
    ]
  end
end

describe FactorySloth::SpecPicker, '::call' do
  it 'takes a directory as argument, returning all spec files in it' do
    expect(FactorySloth::SpecPicker.call(paths: ['spec']))
      .to include 'spec/factory_sloth/cli_spec.rb'
  end

  it 'takes an empty argument, defaulting to the current dir' do
    expect(FactorySloth::SpecPicker.call(paths: []))
      .to include './spec/factory_sloth/cli_spec.rb'
  end

  it 'takes files as argument' do
    expect(FactorySloth::SpecPicker.call(paths: %w[Gemfile Rakefile]))
      .to eq %w[Gemfile Rakefile]
  end

  it 'raises for paths that do not exist' do
    expect do
      FactorySloth::SpecPicker.call(paths: %w[imaginary])
    end.to raise_error(ArgumentError)
  end
end

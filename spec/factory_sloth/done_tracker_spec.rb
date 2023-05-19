describe FactorySloth::DoneTracker do
  it 'works' do
    expect(described_class.done?('foo')).to eq false

    described_class.mark_as_done('foo')
    expect(described_class.done?('foo')).to eq true

    described_class.reset
    expect(described_class.done?('foo')).to eq false
  end

  it 'does not write the same path to the list repeatedly' do
    3.times { described_class.mark_as_done('foo') }
    expect(File.read(described_class.file).scan(/foo/).count).to eq 1
  end
end

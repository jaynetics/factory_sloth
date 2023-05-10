describe FactorySloth::DoneTracker do
  it 'works' do
    expect(described_class.done?('foo')).to eq false

    described_class.mark_as_done('foo')
    expect(described_class.done?('foo')).to eq true

    described_class.reset
    expect(described_class.done?('foo')).to eq false
  end
end

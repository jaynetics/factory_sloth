describe FactorySloth do
  it 'can change individual create calls (1)' do
    expect(create(:optional_create)).not_to be_nil
  end

  it 'can change individual create calls (2)' do
    create(:required_create)
    expect(File.read(__FILE__)).to match /create\(:required_create\)/
  end
end

describe FactorySloth do
  it 'uses build where sufficient' do
    expect(create(:optional_create)).not_to be_nil
  end
end

describe FactorySloth do
  it 'does not change create calls for records that are persisted later' do
    record = create(:optional_create)
    record.save!
    expect(record).not_to be_nil
  end
end

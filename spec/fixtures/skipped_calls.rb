describe FactorySloth do
  it 'does not change create calls that are never executed' do
    next
    expect(create(:who_knows_what)).to be_whatever
    expect(create_list(:who_knows_what, 3)).to all be_whatever
    expect(FactoryBot.create(:who_knows_what)).to be_whatever
    expect(FactoryBot.create_pair(:who_knows_what)).to all be_whatever
  end
end

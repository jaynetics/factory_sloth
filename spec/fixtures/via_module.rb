describe FactorySloth do
  it 'works for FactoryBot.* calls' do
    FactoryBot.create(:foo)
    FactoryBot.create_list(:bar, 3)
    expect(true).to eq true
  end
end

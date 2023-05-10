describe FactorySloth do
  it 'can change create_list' do
    expect(create_list(:foo, 3).count).to eq 3
  end
end

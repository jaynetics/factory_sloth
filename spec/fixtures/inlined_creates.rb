describe FactorySloth do
  it 'skips lines with multiple create calls' do
    arr = [create(:pointless), create(:pointless), create(:pointless)]
  end
end

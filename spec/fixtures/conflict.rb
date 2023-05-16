describe FactorySloth do
  # The examples in this spec keep working if only the create in one is changed,
  # but bizarrely fail if the OTHER example stops using create.

  it 'does nothing in case of conflict (1)' do
    create(:foo)
    fail unless File.read(__FILE__) =~ /create\(:bar/
  end

  it 'does nothing in case of conflict (2)' do
    create(:bar)
    fail unless File.read(__FILE__) =~ /create\(:foo/
  end
end

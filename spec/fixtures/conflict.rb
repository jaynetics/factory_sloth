describe FactorySloth do
  it 'does nothing in case of conflict (1)' do
    create(:foo)
  end

  it 'does nothing in case of conflict (2)' do
    create(:bar)
    # keep working if only the create in this example is changed,
    # but bizarrely fail if the OTHER example also stops using create
    fail unless File.read(__FILE__) =~ /create\(/
  end
end

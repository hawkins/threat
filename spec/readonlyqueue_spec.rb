RSpec.describe ReadOnlyQueue do
  it "has every Queue method but mutations" do
    differences = Queue.instance_methods - ReadOnlyQueue.instance_methods
    # TODO: Implement :marshal_dump for ReadOnlyQueue?
    expect(differences).to eq([:shift, :marshal_dump, :<<, :clear, :close, :push, :pop, :enq, :deq])
  end
end

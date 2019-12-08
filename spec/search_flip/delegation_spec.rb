require File.expand_path("../spec_helper", __dir__)

RSpec.describe SearchFlip::Delegation do
  describe ".delegate_methods" do
    let(:klass) do
      Class.new do
        include SearchFlip::Delegation

        delegate_methods :method1, :method2, to: :target

        attr_reader :target

        def initialize(target)
          @target = target
        end
      end
    end

    let(:target) { Object.new }

    it "delegates method1 to the target" do
      allow(target).to receive(:method1)

      klass.new(target).method1

      expect(target).to have_received(:method1)
    end

    it "delegates method2 to the target" do
      allow(target).to receive(:method2)

      klass.new(target).method2

      expect(target).to have_received(:method2)
    end

    it "passes the arguments" do
      allow(target).to receive(:method1)

      klass.new(target).method1("arg1", "arg2")

      expect(target).to have_received(:method1).with("arg1", "arg2")
    end

    it "passes the block" do
      allow(target).to receive(:method1).and_yield

      res = klass.new(target).method1 { "ok" }

      expect(res).to eq("ok")
    end
  end
end

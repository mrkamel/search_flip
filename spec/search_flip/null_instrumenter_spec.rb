require File.expand_path("../spec_helper", __dir__)

RSpec.describe SearchFlip::NullInstrumenter do
  subject { described_class.new }

  describe "#instrument" do
    it "calls start" do
      allow(subject).to receive(:start)

      subject.instrument("name", { key: "value" }) {}

      expect(subject).to have_received(:start)
    end

    it "calls finish" do
      allow(subject).to receive(:finish)

      subject.instrument("name", { key: "value" }) {}

      expect(subject).to have_received(:finish)
    end

    it "yields and passes the payload" do
      yielded_payload = nil

      subject.instrument("name", { key: "value" }) { |payload| yielded_payload = payload }

      expect(yielded_payload).to eq(key: "value")
    end
  end

  describe "#start" do
    it "returns true" do
      expect(subject.start("name", { key: "value" })).to eq(true)
    end
  end

  describe "#finish" do
    it "returns true" do
      expect(subject.finish("name", { key: "value" })).to eq(true)
    end
  end
end

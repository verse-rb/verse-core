# frozen_string_literal: true

RSpec.describe Verse::Util::Future do
  describe "#wait" do
    it "can wait for future" do
      wait_time = 0.001

      future = Verse::Util::Future.new do
        sleep wait_time
        1
      end

      time = Time.now.to_f
      expect(future.wait).to eq(1)
      time = Time.now.to_f - time
      expect(time).to be >= wait_time
    end
  end

  describe "#cancel" do
    it "can cancel future" do
      future = Verse::Util::Future.new do
        sleep 0.1
        1
      end

      expect(future.done?).to be false
      future.cancel

      # Ensure cancel is dispatched.
      begin
        future.wait
      rescue StandardError
        nil
      end

      expect(future.done?).to be true
      expect(future.error?).to be true
      expect(future.error).to be_a(Timeout::Error)
    end
  end

  describe "#error" do
    it "can raise error" do
      future = Verse::Util::Future.new do
        puts "we raise?"
        raise "test"
      end

      expect do
        future.wait
      end.to raise_error(RuntimeError, "test")
    end

    it "can check if there is error" do
      future = Verse::Util::Future.new do
        raise "test"
      end
      sleep 0.001

      expect(future.success?).to be false
      expect(future.error?).to be true
      expect(future.done?).to be true
      expect(future.error).to be_a(RuntimeError)
    end
  end
end

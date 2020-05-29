module SearchFlip
  class NullInstrumenter
    def instrument(name, payload = {})
      start(name, payload)

      begin
        yield(payload) if block_given?
      ensure
        finish(name, payload)
      end
    end

    def start(_name, _payload)
      true
    end

    def finish(_name, _payload)
      true
    end
  end
end

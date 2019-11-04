RSpec::Matchers.define :delegate do |method|
  match do |delegator|
    @method = method
    @delegator = delegator

    return false unless @delegator.respond_to?(@to)
    return false unless @delegator.respond_to?(@method)

    target = double

    allow(@delegator).to receive(@to).and_return(target)
    allow(target).to receive(@method).and_return(:called)

    @delegator.send(@method) == :called
  end

  description do
    "delegate :#{@method} to :#{@to}"
  end

  failure_message do
    "expected #{@delegator} to delegate :#{@method} to :#{@to}"
  end

  failure_message_when_negated do
    "expected #{@delegator} not to delegate :#{@method} to :#{@to}"
  end

  chain(:to) { |to| @to = to }
end

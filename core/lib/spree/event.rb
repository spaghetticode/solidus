module Spree
  module Event
    extend self

    def publish(event_name, opts={}, &block)
      ActiveSupport::Notifications.instrument "spree.#{event_name}", opts, &block
    end

    def subscribe(event_name)
      ActiveSupport::Notifications.subscribe "spree.#{event_name}" do |*args|
        yield *args
      end
    end
  end
end

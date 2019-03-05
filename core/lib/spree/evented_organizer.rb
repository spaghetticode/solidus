# frozen_string_literal: true

module Spree
  module EventedOrganizer
    def self.included(base)
      base.send :include, Interactor::Organizer
      base.send :prepend, InteractorWrapper
    end

    private

    # Override for nicer interface.
    # @return [String] the root name of the events triggered by the Interactor
    def event_name
      self.class.name.underscore
    end

    # Events will receive by default `context` as event subject. Override in order
    # to write nicer event subscriptions.
    #
    # @return [String] the root name of the events triggered by the Interactor
    def event_subject
      context
    end

    # These are the options passed to the event. `subject` will reflect what is
    # stored in `#event_subject` (by default `context`). When `#event_subject` is
    # customized then it makes sense to pass the extra parameter with `context`
    # in order to still be able to reference it in the event subscription.
    #
    # @return [Hash] the payload that will be passed to subscribed events
    def event_payload
      if event_subject == context
        { subject: event_subject }
      else
        { subject: event_subject, context: context }
      end
    end

    # The event instrumented when the interactor succeeds
    # Subscriptions to `event_name` will be triggered
    def on_success
      Spree::Event.instrument event_name_success, event_payload
    end

    # The event instrumented when the interactor fails
    # Subscriptions to `event_name_failure` will be triggered
    def on_failure
      Spree::Event.instrument event_name_failure, event_payload
    end

    # The event instrumented when an error is raised in the interactor
    # Subscriptions to `event_name_error` will be triggered
    def on_error
      Spree::Event.instrument event_name_error, event_payload
    end

    %w[success failure error].each do |result|
      define_method "event_name_#{result}" do
        [event_name, result].join('_')
      end
    end

    module InteractorWrapper
      # For internal use only. This method wraps the original Interactor#run!
      # in order to add on_failure, on_error and on_success event callbacks.
      def call
        begin
          super
        rescue Interactor::Failure
          on_failure
          raise
        rescue
          on_error
          raise
        end
        on_success
      end
    end
  end
end

# frozen_string_literal: true

module Spree
  # This module adds the ability to write evented interactors, which are interactors
  # with automated events
  #
  # * if the interactor succeeds, the `on_success` event will be instrumented
  # * if the interactor fails, the `on_failure` event will be instrumented
  # * if the interactor errors, the `on_error` event will be instrumented
  #
  # @see Spree::Event#subscribe
  #
  # A few customizations can be achieved by overriding some private default methods
  # that are documented below.
  #
  # @example Basic interactor, with no customization
  #  class Spree::OrderFinalizer
  #    include EventedInteractor
  #
  #    def call
  #      context.order.update finalized: true
  #    end
  #  end
  #
  #  Spree::Event.subscribe 'spree/order_finalizer' do |event|
  #    order = event.payload[:subject].order
  #    Spree::Mailer.confirm_email(order).deliver_later
  #  end
  #
  #  Spree::Event.subscribe 'spree/order_finalizer_failure' do |event|
  #    order = event.payload[:subject].order
  #    AdminNotifier.order_not_finalized(order).deliver_later
  #  end
  #
  #  Spree::Event.subscribe 'spree/order_finalizer_error' do |event|
  #    order = event.payload[:subject].order
  #    AdminNotifier.order_interactor_error(order).deliver_later
  #  end
  #
  # @example Interactor with event customizations
  #  class Spree::OrderFinalizer
  #    include EventedInteractor
  #
  #    def call
  #      order.update finalized: true
  #    end
  #
  #    private
  #
  #    def order
  #      context.order
  #    end
  #
  #    def event_name
  #      'order_finalize'
  #    end
  #
  #    def event_subject
  #      order
  #    end
  #  end
  #
  #  Spree::Event.subscribe 'order_finalize' do |event|
  #    order = event.payload[:subject]
  #    Spree::Mailer.confirm_email(order).deliver_later
  #  end
  module EventedInteractor
    def self.included(base)
      base.send :include, Interactor
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
      Spree::Event.instrument event_name, event_payload
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
      def run!
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

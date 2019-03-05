module Spree
  class Order
    module Interactors
      class Finalizer
        include EventedInteractor

        delegate :all_adjustments, :updater, :shipments, :save!, :touch,
          :deliver_order_confirmation_email, :confirmation_delivered?, to: :order

        def call
          # lock all adjustments (coupon promotions, etc.)
          all_adjustments.each(&:finalize!)

          # update payment and shipment(s) states, and save
          updater.update_payment_state
          shipments.each do |shipment|
            shipment.update_state
            shipment.finalize!
          end

          updater.update_shipment_state
          save!
          updater.run_hooks

          touch :completed_at
        end

        private

        def order
          context.order
        end

        def event_name_success
          'order_finalize'
        end

        def event_subject
          order
        end
      end
    end
  end
end

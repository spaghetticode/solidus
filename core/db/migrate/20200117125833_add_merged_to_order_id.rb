# frozen_string_literal: true

class AddMergedToOrderId < ActiveRecord::Migration[6.0]
  def change
    add_reference :spree_orders, :merged_to_order, foreign_key: { to_table: :spree_orders }
  end
end

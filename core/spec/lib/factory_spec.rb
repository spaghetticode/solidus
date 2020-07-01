# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Factories" do
  it "should pass linting" do
    FactoryBot.lint(FactoryBot.factories.reject{ |f| %i[customer_return_without_return_items global_zone].include?(f.name) })
  end
end

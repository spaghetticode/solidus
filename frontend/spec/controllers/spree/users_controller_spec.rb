# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Spree::UsersController, type: :controller do
  let(:user) { Spree.user_class.new }

  describe '#show' do
    context 'when not authenticated' do
      it 'redirects to unauthorized path' do
        allow(controller).to receive(:spree_current_user) { nil }
        get :show
        expect(response).to redirect_to '/unauthorized'
      end
    end

    context 'when authenticated' do
      before { allow(controller).to receive(:spree_current_user) { user } }

      it 'redirects to signup path if user is not found' do
        allow(controller).to receive(:spree_current_user) { user }
        get :show
        expect(response).to be_success
      end
    end
  end
end

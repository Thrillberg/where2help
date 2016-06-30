require 'rails_helper'

RSpec.describe Ngos::RegistrationsController, type: :controller do
  before { @request.env['devise.mapping'] = Devise.mappings[:ngo] }

  describe 'GET new' do
    it 'return 200 ok status' do
      get :new
      expect(response).to have_http_status 200
    end
  end

  describe 'POST create' do
    context 'with valid attributes' do
      let(:params) {
        {
          ngo: attributes_for(:ngo, email: 'ngo@ngo.we').merge({
            password: 'supersecret',
            password_confirmation: 'supersecret',
            terms_and_conditions: 1,
            contact_attributes: attributes_for(:contact)})
        }
      }

      it 'returns a 302 found response' do
        post :create, params: params
        expect(response).to have_http_status 302
      end

      it 'creates new ngo record' do
        expect{
          post :create, params: params
        }.to change{Ngo.count}.by 1
      end

      it 'creates new contact record' do
        expect{
          post :create, params: params
        }.to change{Contact.count}.by 1
      end

      it 'sends email to ngo' do
        Devise::Mailer.deliveries.clear
        post :create, params: params
        expect(Devise::Mailer.deliveries.count).to eq 1
        expect(Devise::Mailer.deliveries.first.to).to contain_exactly 'ngo@ngo.we'
        Devise::Mailer.deliveries.clear
      end

      it 'sends async email to admins' do
        create :user, admin: true
        message_delivery = instance_double(ActionMailer::MessageDelivery)
        expect(AdminMailer).to receive(:new_ngo).and_return(message_delivery)
        expect(message_delivery).to receive(:deliver_later)
        post :create, params: params
      end
    end
    context 'with missing attributes' do
      let(:params) {
        {
          ngo: attributes_for(:ngo, email: 'ngo@ngo.at').merge({
            password: 'supersecret',
            password_confirmation: 'supersecret'})
        }
      }

      it 'returns a 200 ok status' do
        post :create, params: params
        expect(response).to have_http_status 200
      end

      it 'does not create new ngo record' do
        expect{
          post :create, params: params
        }.not_to change{Ngo.count}
      end
    end
  end

  describe 'DELETE destroy' do
    let!(:ngo) { create(:ngo,
      email: 'ngo@ngo.we',
      confirmed_at: Faker::Time.backward(5),
      aasm_state: 'admin_confirmed',
      confirmation_token: Faker::Bitcoin.address) }

    let(:destroy_ngo) { -> { delete :destroy; ngo.reload } }

    before { sign_in ngo }

    it 'returns a 302 found status' do
      delete :destroy
      expect(response).to have_http_status 302
    end

    it 'does not destroy ngo record' do
      expect(destroy_ngo).not_to change{Ngo.count}
    end

    it 'resets confirmed_at' do
      expect(destroy_ngo).to change{ngo.confirmed_at}.to nil
    end

    it 'resets confirmation_token' do
      expect(destroy_ngo).to change{ngo.confirmation_token}.to nil
    end

    it 'sets aasm_state to :deactivated' do
      expect(destroy_ngo).to change{ngo.deactivated?}.to true
    end
  end
end

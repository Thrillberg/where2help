require 'rails_helper'

RSpec.describe Ngo, type: :model do

  it 'has a valid factory' do
    expect(create :ngo).to be_valid
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of :name }
    it { is_expected.to validate_presence_of :contact }
    it { is_expected.to validate_acceptance_of :terms_and_conditions }
    it { is_expected.to have_many(:events).dependent(:restrict_with_error) }
  end

  it { is_expected.to define_enum_for(:locale).with([:de, :en]) }

  describe 'associations' do
    it { is_expected.to have_one(:contact).dependent :destroy }
  end

  describe 'callbacks' do
    describe 'after_commit' do
      before { create :user, admin: true }

      it 'sends email to admins' do
        message_delivery = instance_double(ActionMailer::MessageDelivery)
        expect(AdminMailer).to receive(:new_ngo).and_return(message_delivery)
        expect(message_delivery).to receive(:deliver_later)
        create :ngo
      end
    end
    describe 'contact' do
      let(:ngo) { create :ngo }

      it 'destroys contact record on destroy' do
        create(:contact, ngo: ngo)
        expect{
          ngo.destroy
        }.to change{Contact.count}.by -1
      end
    end
  end

  describe '#aasm' do
    before { ActiveJob::Base.queue_adapter = :test }

    describe ':pending' do
      let!(:ngo) { create :ngo, confirmed_at: Time.now, confirmation_token: '123' }

      it 'is initial state' do
        expect(ngo).to have_state :pending
      end
      it 'can transition to :admin_confirmed and :deactivated' do
        expect(ngo).to transition_from(:pending).to(:admin_confirmed).on_event(:admin_confirm)
        expect(ngo).to transition_from(:pending).to(:deactivated).on_event(:deactivate)
      end
      it 'send confirmation email on admin_confirm' do
        expect{
          ngo.admin_confirm!
        }.to have_enqueued_job(ActionMailer::DeliveryJob)
      end
      it 'resets confirmed_at on deactivate' do
        expect{
          ngo.deactivate!
        }.to change{ngo.confirmed_at}.to nil
      end
      it 'resets confirmation_token on deactivate' do
        expect{
          ngo.deactivate!
        }.to change{ngo.confirmation_token}.to nil
      end
    end
    describe ':admin_confirmed' do
      let!(:ngo) { create :ngo, aasm_state: 'admin_confirmed' }

      it 'is confirmed' do
        expect(ngo).to have_state :admin_confirmed
      end
      it 'can transition to :deactivated' do
        expect(ngo).to transition_from(:admin_confirmed).to(:deactivated).on_event(:deactivate)
      end
      it 'cannot transition to :pending' do
        expect(ngo).to_not allow_transition_to :pending
      end
      it 'cannot be confirmed again' do
        expect(ngo).to_not allow_event :admin_confirm
      end
    end
  end

  describe '#new_event' do
    let(:ngo) { create :ngo, :confirmed }
    subject{ ngo.new_event }

    it 'retuns an event with one shift' do
      expect(subject).to be_a_new Event
    end
    it 'has a shift at next quarter hour with 1 volunteer needed' do
      shift = subject.shifts.first
      expect(shift.volunteers_needed).to eq 1
      expect([0, 15, 30, 45]).to include shift.starts_at.min
      expect([0, 15, 30, 45]).to include shift.ends_at.min
    end
  end
end

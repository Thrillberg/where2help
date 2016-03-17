require 'rails_helper'

RSpec.describe Shift, type: :model do
  it { is_expected.to have_many(:users)}
  it { is_expected.to belong_to(:event)}

  it { is_expected.to validate_presence_of(:volunteers_needed)}
  it { is_expected.to validate_presence_of(:starts_at)}
  it { is_expected.to validate_presence_of(:ends_at)}
end
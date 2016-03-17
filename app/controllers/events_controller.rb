class EventsController < ApplicationController
  before_filter :authenticate_ngo!, only: :new

  def new
    @event = Event.new
    @event.shifts.build(volunteers_needed: 1, starts_at: Time.now, ends_at: 2.hours.from_now)
  end

  def show
  end

  def create
    @event = Event.new(event_params)
    respond_to do |format|
      if @event.save
        format.html { redirect_to @event, notice: 'Event was successfully created.' }
      else
        format.html { render action: :new }
      end
    end
  end

  private

  def event_params
    params.require(:event).permit(
      :description, :address, :shift_length,
      shifts_attributes: [:id, :volunteers_needed, :starts_at, :ends_at]
    )
  end
end
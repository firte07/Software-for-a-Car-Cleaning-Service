class Car
  attr_reader :number_plate
  attr_accessor :cleaning_status, :taken, :date_time_reservation

  def initialize(number_plate)
    @number_plate = number_plate
    @cleaning_status = 'Dirty'
    @taken = false
    @date_time_reservation = nil
  end
end


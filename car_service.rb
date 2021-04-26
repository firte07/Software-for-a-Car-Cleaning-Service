require_relative 'car'
require_relative 'car_service'
require_relative 'scheduler'

class CarService
  attr_accessor :scheduler, :current_time, :parking, :cars_processing

  def initialize(scheduler)
    @scheduler = scheduler
    @parking = []
    @cars_processing = []
    @current_time = DateTime.now
  end

  def forward_time
    puts "Number of hours to forward: \n"
    hours = gets.chomp
    puts "Old time: #{@current_time}"
    @current_time += (hours.to_i / 24.0)
    puts "New time #{@current_time}"
  end

  def verify_processing_cars
    if @cars_processing.size == 1
      business_track(@cars_processing[0])
    elsif @cars_processing.size == 2
      business_track(@cars_processing[1])
    end
  end

  def check_status_cars
    case @cars_processing.size
    when 1
      business_track(@cars_processing[0])
    when 2
      business_track(@cars_processing[0])
      verify_processing_cars
    end

    planning_cars
  end

  def pick_up_car(number_plate)
    if @parking.include?(number_plate)
      puts "The car with the number plate #{number_plate} was picked-up. Another client happy :D"
      @parking.delete(number_plate)

      "The car with the number plate #{number_plate} was picked-up. Another client happy :D"
    else
      puts 'Sorry, the car is not here! Check the number plate!'

      'Sorry, the car is not here! Check the number plate!'
    end
  end

  private

  def planning_cars
    return 'Nothing to clean' if @scheduler.agenda.empty?

    @scheduler.agenda.each_with_index do |(_, _), index|
      if index == @scheduler.agenda.size - 1 && @scheduler.agenda.values[index] == @current_time
        planning_last_car
      else
        planning_multiple_cars(index)
      end
    end
  end

  def planning_last_car
    @scheduler.agenda.delete(@scheduler.cars[0].number_plate)
    @cars_processing << @scheduler.cars[0]

    business_track(@scheduler.cars.shift)
  end

  def planning_two_cars
    @scheduler.agenda.delete(@scheduler.cars[0].number_plate)
    @scheduler.agenda.delete(@scheduler.cars[1].number_plate)

    @cars_processing << @scheduler.cars[0]
    @cars_processing << @scheduler.cars[1]

    business_track(@scheduler.cars.shift)
    business_track(@scheduler.cars.shift)
  end

  def planning_one_car
    @scheduler.agenda.delete(@scheduler.cars[0].number_plate)
    @cars_processing << @scheduler.cars[0]

    business_track(@scheduler.cars.shift)
  end

  def planning_multiple_cars(index)
    date_time = @scheduler.agenda.values[index]
    date_time_plus = @scheduler.agenda.values[index + 1]

    if date_time == date_time_plus && date_time == @current_time
      planning_two_cars
    elsif date_time != date_time_plus && date_time == @current_time
      planning_one_car
    end
  end

  def business_track(car)
    if car.date_time_reservation.hour + 2 <= @current_time.hour
      car.cleaning_status = 'Clean'
      @parking << car.number_plate
      puts "Car with the number plate #{car.number_plate} is clean"

      @cars_processing.shift

      "Car with the number plate #{car.number_plate} is clean"
    else
      puts "Washing the #{car.number_plate}"

      "Washing the #{car.number_plate}"
    end
  end

end

require 'date'
require_relative 'car'
require_relative 'car_service'
require_relative 'scheduler'

def case_better_option(scheduler, car)
  better_time_string = scheduler.find_better_time
  better_time = DateTime.new(better_time_string[0].to_i, better_time_string[1].to_i,
                             better_time_string[2].to_i, better_time_string[3].to_i)

  number_of_reservations = scheduler.agenda.size
  scheduler.insert_client_reservation(better_time, car.number_plate)

  if number_of_reservations < scheduler.agenda.size
    car.date_time_reservation = scheduler.agenda[car.number_plate]
    scheduler.cars << car
  end

  scheduler.better_option = false
end

scheduler = Scheduler.new
car_service = CarService.new(scheduler)
car_service.current_time = DateTime.new(DateTime.now.year, DateTime.now.month, DateTime.now.day, DateTime.now.hour)

puts "Welcome! \n"
puts "Make a reservation or pick-up a car? Please type reservation or pick-up. \n"


command = gets.chomp

until command == 'exit'
  case command.downcase
  when 'reservation'
    puts "Please enter the number plate: \n"
    car = Car.new(gets.chomp)
    scheduler.make_fastest_reservation(car.number_plate)
    if scheduler.better_option
      case_better_option(scheduler, car)
    else
      car.date_time_reservation = scheduler.agenda[car.number_plate]
      scheduler.cars << car
    end
  when 'pick-up'
    puts "Please enter the number plate: \n"
    number_plate = gets.chomp
    car_service.pick_up_car(number_plate)
  when 'fwd'
    car_service.forward_time
  else
    puts 'Please be more careful at spelling'
  end
  car_service.check_status_cars
  puts "\nCurrent agenda: \n"
  scheduler.agenda.each { |keys, value| puts "#{keys}  #{value}" }
  puts "\nWhat do you want now? \n"
  command = gets.chomp
end

require 'date'

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

  def check_status_cars
    case @cars_processing.size
    when 1
      first_car_wash_track(@cars_processing[0])
    when 2
      first_car_wash_track(@cars_processing[0])
      second_car_wash_track(@cars_processing[0])
    end
    planning_cars
  end

  def pick_up_car(number_plate)
    if @parking.include?(number_plate)
      puts "The car with the number plate #{number_plate} was picked-up. Another client happy :D"
      @parking.delete(number_plate)
    else
      puts 'Sorry, the car is not here! Check the number plate!'
    end
  end

  private

  def planning_cars
    puts 'Nothing to clean' if @scheduler.agenda.empty?
    @scheduler.agenda.each_with_index do |(_, _), index|
      if index == @scheduler.agenda.size - 1 && @scheduler.agenda.values[index] == @current_time
        planning_last_car
      else
        planning_multiple_cars(index)
      end
    end
  end

  def guide_cars(first_car, second_car)
    first_car_wash_track(first_car)
    second_car_wash_track(second_car)
  end

  def guide_car(car)
    first_car_wash_track(car)
  end

  def planning_last_car
    @scheduler.agenda.delete(@scheduler.cars[0].number_plate)
    @cars_processing << @scheduler.cars[0]
    guide_car(@scheduler.cars.shift)
  end

  def planning_multiple_cars(index)
    if @scheduler.agenda.values[index] == @scheduler.agenda.values[index + 1] && @scheduler.agenda.values[index] == @current_time
      @scheduler.agenda.delete(@scheduler.cars[0].number_plate)
      @scheduler.agenda.delete(@scheduler.cars[1].number_plate)
      @cars_processing << @scheduler.cars[0]
      @cars_processing << @scheduler.cars[1]
      guide_cars(@scheduler.cars.shift, @scheduler.cars.shift)
    elsif @scheduler.agenda.values[index] != @scheduler.agenda.values[index + 1] && @scheduler.agenda.values[index] == @current_time
      @scheduler.agenda.delete(@scheduler.cars[0].number_plate)
      @cars_processing << @scheduler.cars[0]
      guide_car(@scheduler.cars.shift)
    end
  end

  def first_car_wash_track(car)
    if car.date_time_reservation.hour + 2 <= @current_time.hour
      car.cleaning_status = 'Clean'
      @parking << car.number_plate
      puts "Car with the number plate #{car.number_plate} is clean"
      @cars_processing.shift
    else
      puts "Washing the #{car.number_plate}"
    end
  end

  def second_car_wash_track(car)
    if car.date_time_reservation.hour + 2 <= @current_time.hour
      car.cleaning_status = 'Clean'
      @parking << car.number_plate
      puts "Car with the number plate #{car.number_plate} is clean"
      @cars_processing.shift
    else
      puts "Washing the #{car.number_plate}"
    end
  end
end

class Scheduler
  OPENING_HOUR = 8
  WEEKDAY_CLOSING_HOUR = 18
  SATURDAY_CLOSING_HOUR = 14
  attr_accessor :agenda, :better_option, :cars

  def initialize
    @agenda = {}
    @cars = []
    @better_option = false
  end

  def make_fastest_reservation(number_plate)
    index = if DateTime.now.saturday?
              check_reservation(DateTime.now.day, SATURDAY_CLOSING_HOUR)
            else
              check_reservation(DateTime.now.day, WEEKDAY_CLOSING_HOUR)
            end

    if DateTime.now.saturday?
      add_reservation_saturday(index, number_plate)
    else
      add_reservation_weekday(index, number_plate)
    end
  end

  def insert_client_reservation(date_time, number_plate)
    if client_request(date_time)
      insert_index = if check_index_to_add(date_time).nil?
                       @agenda.size - 1
                     else
                       check_index_to_add(date_time)
                     end
      if insert_index == {}
        insert_reservation(0, { number_plate => date_time }, :before)
      else
        insert_reservation(insert_index, { number_plate => date_time }, :after)
      end
    end
  end

  def find_better_time
    better_time_string = []
    puts 'Year:'
    better_time_string[0] = gets.chomp
    puts 'Month:'
    better_time_string[1] = gets.chomp
    puts 'Day:'
    better_time_string[2] = gets.chomp
    puts 'Hour:'
    better_time_string[3] = gets.chomp
    better_time_string
  end

  private

  def reservation_ok?(index, date_time, number_plate, proximity = :after)
    if date_time.day != DateTime.now.day
      puts "Sorry. Today we are full. \n"
      puts 'Please tell me a better option for you:'
      @better_option = true
    else
      puts "The fastest reservation we can made is: #{date_time}. Is it ok for you? \n"
      answer = gets.chomp
      if answer.downcase == 'yes'
        insert_reservation(index, { number_plate => date_time }, proximity)
      else
        puts 'Please tell me a better option for you:'
        @better_option = true
      end
    end
  end

  def insert_reservation(index, pair, proximity = :after)
    @agenda = @agenda.to_a.insert(index + (proximity == :after ? 1 : 0), pair.first).to_h
    if proximity == :after
      puts "\nYou can pick-up the car from: #{@agenda.values[index + 1].year}/#{@agenda.values[index + 1].month}" \
      "#{+ "/"}#{@agenda.values[index + 1].day} at #{@agenda.values[index + 1].hour + 2} \n"
    else
      puts "\nYou can pick-up the car from: #{@agenda.values[index].year}/#{@agenda.values[index].month}" \
      "#{+ "/"}#{@agenda.values[index].day} at #{@agenda.values[index].hour + 2} \n"
    end
  end

  def check_reservation(day, closing_time)
    if @agenda.empty? || @agenda.values[0].day > day
      0
    else
      check_fastest_time_day(day, closing_time)
    end
  end

  def check_fastest_time_day(day, closing_time)
    @agenda.each_with_index do |(_, _), index|
      break if index == @agenda.size - 1

      next unless @agenda.values[index].day == day

      return index if @agenda.values[index].hour <= @agenda.values[index + 1].hour - 4 && \
                      @agenda.values[index].hour <= closing_time - 4

      return index if (@agenda.values[index].day + 1 == @agenda.values[index + 1].day || \
                      (index + 1 == @agenda.size - 1 && !check_double_time(index + 1))) && \
                      @agenda.values[index].hour <= closing_time - 4

      return index if (@agenda.values[index].day + 1 == @agenda.values[index + 1].day || \
                      (index + 1 == @agenda.size - 1 && !check_double_time(index + 1))) && \
                      @agenda.values[index].hour <= closing_time - 2 && !check_double_time(index)

      return index if @agenda.values[index].hour <= @agenda.values[index + 1].hour - 2 && \
                      @agenda.values[index].hour <= closing_time - 4 && !check_double_time(index)
    end
    @agenda.size - 1
  end

  def check_double_time(index_to_add)
    index_to_add = 0 if index_to_add.negative?
    return false if index_to_add.zero?
    return true if @agenda.values[index_to_add - 1].hour == @agenda.values[index_to_add].hour

    false
  end

  def insert_first_index(index, number_plate)
    date = case DateTime.now.hour % 2
           when 0
             DateTime.new(DateTime.now.year, DateTime.now.month, DateTime.now.day, DateTime.now.hour + 2, 0, 0)
           else
             DateTime.new(DateTime.now.year, DateTime.now.month, DateTime.now.day, DateTime.now.hour + 1, 0, 0)
           end
    if date.saturday? && date.hour >= SATURDAY_CLOSING_HOUR || !date.saturday? && date.hour >= WEEKDAY_CLOSING_HOUR \
      || date.sunday? || date.hour < OPENING_HOUR
      puts "Sorry. The car wash is closed. Please make a phone call tomorrow. \n"
    else
      reservation_ok?(index, date, number_plate, :before)
    end
  end

  def create_date_and_insert(index, number_plate)
    index = 0 if index.negative?
    if index.zero?
      insert_first_index(index, number_plate)
    elsif check_double_time(index)
      date = DateTime.new(2021, @agenda.values[index].month, @agenda.values[index].day, @agenda.values[index].hour + 2, 0, 0)
      reservation_ok?(index, date, number_plate, :after)
    else
      date = DateTime.new(2021, @agenda.values[index].month, @agenda.values[index].day, @agenda.values[index].hour, 0, 0)
      reservation_ok?(index, date, number_plate, :after)
    end
  end

  def add_reservation_saturday(index, number_plate)
    if index == @agenda.size - 1 && @agenda.values[index].hour == SATURDAY_CLOSING_HOUR - 2
      date = DateTime.new(@agenda.values[index].next_day.next_day.year, @agenda.values[index].next_day.next_day.month, \
                          @agenda.values[index].next_day.next_day.day, OPENING_HOUR, 0, 0)
      reservation_ok?(index, date, number_plate, :after)
    else
      create_date_and_insert(index, number_plate)
    end
  end

  def add_reservation_weekday(index, number_plate)
    if index == @agenda.size - 1 && @agenda.values[index].hour == WEEKDAY_CLOSING_HOUR - 2
      date = DateTime.new(@agenda.values[index].next_day.year, @agenda.values[index].next_day.month, \
                          @agenda.values[index].next_day.day, OPENING_HOUR, 0, 0)
      reservation_ok?(index, date, number_plate, :after)
    else
      create_date_and_insert(index, number_plate)
    end
  end

  def client_request(date_time)
    flag = true
    if validate_date_time(date_time)
      @agenda.each_with_index do |(_, _), index|
        break if index == @agenda.size - 1

        flag = false if @agenda.values[index] == @agenda.values[index + 1] && \
                        @agenda.values[index] == date_time
      end
      puts "Already exists a reservation on that time. \n" unless flag
    else
      puts "Time is invalid. Sorry. \n"
      flag = false
    end
    flag
  end

  def validate_date_time(date_time)
    return false if date_time.saturday? && date_time.hour > SATURDAY_CLOSING_HOUR - 2
    return false if !date_time.saturday? && date_time.hour > WEEKDAY_CLOSING_HOUR - 2
    return false if date_time.hour.odd?
    return false if date_time.sunday?

    true
  end

  def check_index_to_add(date_time)
    @agenda.each_with_index do |(_, _), index|
      break if index == @agenda.size - 1
      return index if @agenda.values[index] <= date_time && date_time < @agenda.values[index + 1]
    end
  end
end

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

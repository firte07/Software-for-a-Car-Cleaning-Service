require 'date'

class Car
  ID_FORMAT = /^([A-Z]){2}([0-9]){2,3}([A-Z]){3}$/
  attr_reader :number_plate, :date_time_reservation
  attr_accessor :cleaning_status, :taken

  def initialize(number_plate)
    @number_plate = number_plate
    @cleaning_status = 'Dirty'
    @taken = false
    @date_time_reservation = nil
  end
end

class CarService
  attr_accessor :scheduler

  def initialize(scheduler)
    @scheduler = scheduler
  end

  def first_car_wash_track(car, finish_time)
    puts "Washing the #{car.model}"
  end

  def second_car_wash_track(car, finish_time)
    puts "Washing the #{car.model} at track 2"
  end
end

class Scheduler
  OPENING_HOUR = 8
  WEEKDAY_CLOSING_HOUR = 18
  SATURDAY_CLOSING_HOUR = 14
  attr_accessor :agenda, :better_option, :current_processing_cars

  def initialize
    @agenda = {}
    @current_processing_cars = []
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
    else
      puts 'Nu se poate'
    end
  end

  def find_better_time
    better_time_string = []
    puts "Year:"
    better_time_string[0] = gets.chomp
    puts "Month:"
    better_time_string[1] = gets.chomp
    puts "Day:"
    better_time_string[2] = gets.chomp
    puts "Hour:"
    better_time_string[3] = gets.chomp
    better_time_string
  end

  private

  def reservation_ok?(index, date_time, number_plate, proximity = :after)
    puts "The fastest reservation we can made is: #{date_time}. Is it ok for you? \n"
    answer = gets.chomp
    if answer.downcase == 'yes'
      insert_reservation(index, { number_plate => date_time }, proximity)
    else
      puts 'Please tell me a better option for you:'
      @better_option = true
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
    opening_at_eight = false
    @agenda.each_with_index do |(_, _), index|
      break if index == @agenda.size - 1

      next unless @agenda.values[index].day == day
      return index - 1 if @agenda.values[index].hour != OPENING_HOUR && !opening_at_eight

      opening_at_eight = true
      return index if @agenda.values[index].hour <= @agenda.values[index + 1].hour - 4 && \
                      @agenda.values[index].hour <= closing_time - 4

      # the last reservation from that day
      return index if @agenda.values[index].day + 1 == @agenda.values[index + 1].day && \
                      @agenda.values[index].hour <= closing_time - 4

      # daca e are un loc, exact la final de zi
      return index if @agenda.values[index].day + 1 == @agenda.values[index + 1].day && \
                      @agenda.values[index].hour <= closing_time - 2 && !check_double_time(index)

      # fara gap, dar cu loc liber la o statie
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
    # if date.saturday? && date.hour >= SATURDAY_CLOSING_HOUR || !date.saturday? && date.hour >= WEEKDAY_CLOSING_HOUR
    #   puts "Sorry. The car wash is closing. Please make a phone call tomorrow. \n"
    #else
    reservation_ok?(index, date, number_plate, :before)
    #end
  end

  def create_date_and_insert(index, number_plate)
    index = 0 if index.negative?
    if index.zero?      # daca e chiar primul adaugat
      insert_first_index(index, number_plate)
    elsif check_double_time(index)  # daca a gasit o pozitie oke, si avem dublura
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

date = DateTime.new(2021, 4, 21, 8, 0, 0)
date1 = DateTime.new(2021, 4, 21, 8, 0, 0)
date2 = DateTime.new(2021, 4, 21, 10, 0, 0)
date3 = DateTime.new(2021, 4, 21, 10, 0, 0)
date4 = DateTime.new(2021, 4, 21, 12, 0, 0)
date5 = DateTime.new(2021, 4, 21, 12, 0, 0)
date6 = DateTime.new(2021, 4, 21, 14, 0, 0)
date7 = DateTime.new(2021, 4, 21, 14, 0, 0)
date8 = DateTime.new(2021, 4, 21, 16, 0, 0)
date9 = DateTime.new(2021, 4, 21, 16, 0, 0)
date10 = DateTime.new(2021, 4, 22, 12, 0, 0)

scheduler = Scheduler.new
car_service = CarService.new(scheduler)

#scheduler.agenda['passat'] = date2
#scheduler.agenda['mercedes'] = date3
#scheduler.agenda['BMW'] = date4
#scheduler.agenda['honda2'] = date5
#scheduler.agenda['skoda2'] = date6
#scheduler.agenda['passat2'] = date7
#scheduler.agenda['mercedes2'] = date8
#scheduler.agenda['BMW2'] = date9
#scheduler.agenda['BMW3'] = date10

puts "Welcome! \n"
puts "Make a reservation or pick-up a car? Please type reservation or pick-up. \n"

command = gets.chomp

until command == 'exit'
  case command
  when 'reservation'
    puts "Please enter the number plate: \n"
    car = Car.new(gets.chomp)
    scheduler.make_fastest_reservation(car.number_plate)
    if scheduler.better_option
      better_time_string = scheduler.find_better_time
      better_time = DateTime.new(better_time_string[0].to_i, better_time_string[1].to_i,
                                 better_time_string[2].to_i, better_time_string[3].to_i)
      scheduler.insert_client_reservation(better_time, car.number_plate)
      scheduler.better_option = false
    end
  when 'pick-up'
    puts 'To be implemented'
  else
    puts 'Please be more careful at spelling'
  end

  puts "\nCurrent agenda: \n"
  scheduler.agenda.each { |keys, value| puts "#{keys.to_s}  #{value.to_s}" }
  puts "\nWhat do you want now? \n"
  command = gets.chomp

end

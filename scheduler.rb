require_relative 'car'
require_relative 'car_service'
require_relative 'scheduler'

class Scheduler
  OPENING_HOUR = 8
  WEEKDAY_CLOSING_HOUR = 18
  SATURDAY_CLOSING_HOUR = 14
  attr_accessor :agenda, :better_option, :cars, :answer

  def initialize
    @agenda = {}
    @cars = []
    @better_option = false
  end

  def make_fastest_reservation(number_plate)
    if DateTime.now.saturday?
      add_reservation_saturday(check_reservation(DateTime.now.day, SATURDAY_CLOSING_HOUR), number_plate)
    else
      add_reservation_weekday(check_reservation(DateTime.now.day, WEEKDAY_CLOSING_HOUR), number_plate)
    end
  end

  def verify_index(insert_index, number_plate, date_time)
    if insert_index == {}
      insert_reservation(0, { number_plate => date_time }, :before)
    else
      insert_reservation(insert_index, { number_plate => date_time }, :after)
    end
  end

  def insert_client_reservation(date_time, number_plate)
    if client_request(date_time)
      insert_index = if check_index_to_add(date_time).nil?
                       @agenda.size - 1
                     else
                       check_index_to_add(date_time)
                     end

      verify_index(insert_index, number_plate, date_time)
    else
      'We are closed or time is invalid (bad time or full)'
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

  def receive_confirmation
    gets.chomp
  end

  private

  def fastest_free_time(index, number_plate, date_time, proximity)
    puts "The fastest reservation we can made is: #{date_time}. Is it ok for you? \n"
    answer = receive_confirmation
    if answer.downcase == 'yes'
      insert_reservation(index, { number_plate => date_time }, proximity)
    else
      puts 'Please tell me a better option for you:'
      @better_option = true
    end
  end

  def today_full
    puts "Sorry. Today we are full. \n"
    puts 'Please tell me a better option for you:'
    @better_option = true
  end

  def check_client_opinion(index, date_time, number_plate, proximity = :after)
    if date_time.day != DateTime.now.day
      today_full
    else
      fastest_free_time(index, number_plate, date_time, proximity)
    end
  end

  def check_proximity(proximity, date_time_index_plus, date_time)
    if proximity == :after
      puts "\nYou can pick-up the car from: #{date_time_index_plus.year}/#{date_time_index_plus.month}" \
      "#{+ "/"}#{date_time_index_plus.day} at #{date_time_index_plus.hour + 2} \n"
    else
      puts "\nYou can pick-up the car from: #{date_time.year}/#{date_time.month}" \
      "#{+ "/"}#{date_time.day} at #{date_time.hour + 2} \n"
    end
  end

  def insert_reservation(index, pair, proximity = :after)
    @agenda = @agenda.to_a.insert(index + (proximity == :after ? 1 : 0), pair.first).to_h

    check_proximity(proximity, @agenda.values[index + 1], @agenda.values[index])
  end

  def check_reservation(day, closing_time)
    return 0 if @agenda.empty? || @agenda.values[0].day > day

    check_fastest_time_day(day, closing_time)
  end

  def check_fastest_time_day(day, closing_time)
    @agenda.each_with_index do |(_, _), index|
      break if index == @agenda.size - 1

      date_time = @agenda.values[index]
      date_time_plus = @agenda.values[index + 1]

      next unless @agenda.values[index].day == day

      return index if date_time.hour <= date_time_plus.hour - 4 && \
                      date_time.hour <= closing_time - 4

      return index if (date_time.day + 1 == date_time_plus.day || \
                      (index + 1 == @agenda.size - 1 && !check_double_time(index + 1))) && \
                      date_time.hour <= closing_time - 4

      return index if (date_time.day + 1 == date_time_plus.day || \
                      (index + 1 == @agenda.size - 1 && !check_double_time(index + 1))) && \
                      date_time.hour <= closing_time - 2 && !check_double_time(index)

      return index if date_time.hour <= date_time_plus.hour - 2 && \
                      date_time.hour <= closing_time - 4 && !check_double_time(index)
    end

    @agenda.size - 1
  end

  def check_double_time(index_to_add)
    index_to_add = 0 if index_to_add.negative?

    return false if index_to_add.zero?

    return true if @agenda.values[index_to_add - 1].hour == @agenda.values[index_to_add].hour

    false
  end

  def closed?(date)
    (date.saturday? && date.hour >= SATURDAY_CLOSING_HOUR) \
    || (!date.saturday? && date.hour >= WEEKDAY_CLOSING_HOUR) \
    || date.sunday? \
    || date.hour < OPENING_HOUR
  end

  def validate_closed(date, index, number_plate)
    if closed?(date)
      puts "Sorry. The car wash is closed. Please make a phone call tomorrow. \n"
    else
      check_client_opinion(index, date, number_plate, :before)
    end
  end

  def insert_first_index(index, number_plate)
    date = case DateTime.now.hour % 2
           when 0
             DateTime.new(DateTime.now.year, DateTime.now.month, DateTime.now.day, DateTime.now.hour + 2, 0, 0)
           else
             DateTime.new(DateTime.now.year, DateTime.now.month, DateTime.now.day, DateTime.now.hour + 1, 0, 0)
           end

    validate_closed(date, index, number_plate)
  end

  def compute_date(index, number_plate, value_to_add)
    date = DateTime.new(2021, @agenda.values[index].month, @agenda.values[index].day,
                        @agenda.values[index].hour + value_to_add, 0, 0)

    check_client_opinion(index, date, number_plate, :after)
  end

  def create_date_and_insert(index, number_plate)
    index = 0 if index.negative?

    if index.zero?
      insert_first_index(index, number_plate)
    elsif check_double_time(index)
      compute_date(index, number_plate, 2)
    else
      compute_date(index, number_plate, 0)
    end
  end

  def add_reservation_saturday(index, number_plate)
    date_time = @agenda.values[index]

    if index == @agenda.size - 1 && date_time.hour == SATURDAY_CLOSING_HOUR - 2
      date = DateTime.new(date_time.next_day.next_day.year, date_time.next_day.next_day.month, \
                          date_time.next_day.next_day.day, OPENING_HOUR, 0, 0)

      check_client_opinion(index, date, number_plate, :after)
    else
      create_date_and_insert(index, number_plate)
    end
  end

  def add_reservation_weekday(index, number_plate)
    date_time = @agenda.values[index]

    if index == @agenda.size - 1 && date_time.hour == WEEKDAY_CLOSING_HOUR - 2
      date = DateTime.new(date_time.next_day.year, date_time.next_day.month, \
                          date_time.next_day.day, OPENING_HOUR, 0, 0)

      check_client_opinion(index, date, number_plate, :after)
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

  def time_invalid(date_time)
    if date_time.saturday? && date_time.hour > SATURDAY_CLOSING_HOUR - 2 || \
       !date_time.saturday? && date_time.hour > WEEKDAY_CLOSING_HOUR - 2 || \
       date_time.hour.odd? || date_time.sunday?

      true
    end
  end

  def validate_date_time(date_time)
    return false if time_invalid(date_time)

    true
  end

  def check_index_to_add(date_time)
    @agenda.each_with_index do |(_, _), index|
      break if index == @agenda.size - 1

      return index if @agenda.values[index] <= date_time && date_time < @agenda.values[index + 1]
    end
  end
end

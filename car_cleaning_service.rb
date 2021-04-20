require 'date'

class Car
  ID_FORMAT = /^([A-Z]){2}([0-9]){2,3}([A-Z]){3}$/
  attr_reader :model, :number_plate, :time_arrival
  attr_accessor :cleaning_status, :taken

  def initialize(number_plate, model, time_arrival)
    @number_plate = number_plate
    @model = model
    @cleaning_status = 'Dirty'
    @taken = false
    @time_arrival = time_arrival
  end
end

class CarService

  def first_car_wash_track(car, finish_time)
    puts "Washing the #{car.model}"
    if car.time_arrival == finish_time
      puts 'The car is clean!'
      car.cleaning_status = 'Clean'
    end
  end

  def second_car_wash_track(car, finish_time)
    puts "Washing the #{car.model} at track 2"
    if car.time_arrival == finish_time
      puts 'The car is clean!'
      car.cleaning_status = 'Clean'
    end
  end
end

class Scheduler
  OPENING_HOUR = 8
  WEEKDAY_CLOSING_HOUR = 18
  SATURDAY_CLOSING_HOUR = 14
  attr_accessor :agenda, :current_processing_cars

  def initialize
    @agenda = {}
    @current_processing_cars = []
  end

  private

  def insert_reservation(index, pair, proximity = :after)
    @agenda = @agenda.to_a.insert(index + (proximity == :after ? 1 : 0), pair.first).to_h
  end

  public

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

  public

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
    insert_reservation(index, { number_plate => date }, :before)
  end

  public

  def create_date_and_insert(index, number_plate)
    index = 0 if index.negative?
    if index.zero?      # daca e chiar primul adaugat
      insert_first_index(index, number_plate)
    elsif check_double_time(index)  # daca a gasit o pozitie oke, si avem dublura
      date = DateTime.new(2021, @agenda.values[index].month, @agenda.values[index].day, @agenda.values[index].hour + 2, 0, 0)
      insert_reservation(index, { number_plate => date }, :after)
    else
      date = DateTime.new(2021, @agenda.values[index].month, @agenda.values[index].day, @agenda.values[index].hour, 0, 0)
      insert_reservation(index, { number_plate => date }, :after)
    end
  end

  public

  def add_reservation_saturday(index, number_plate)
    if index == @agenda.size - 1 && @agenda.values[index].hour == SATURDAY_CLOSING_HOUR - 2
      date = DateTime.new(@agenda.values[index].next_day.next_day.year, @agenda.values[index].next_day.next_day.month, \
                          @agenda.values[index].next_day.next_day.day, 8, 0, 0)
      insert_reservation(index, { number_plate => date }, :after)
    else
      create_date_and_insert(index, number_plate)
    end
  end

  public

  def add_reservation_weekday(index, number_plate)
    if index == @agenda.size - 1 && @agenda.values[index].hour == WEEKDAY_CLOSING_HOUR - 2
      date = DateTime.new(@agenda.values[index].next_day.year, @agenda.values[index].next_day.month, \
                          @agenda.values[index].next_day.day, 8, 0, 0)
      insert_reservation(index, { number_plate => date }, :after)
    else
      create_date_and_insert(index, number_plate)
    end
  end

  public

  def make_reservation(number_plate)
    # cea mai rapida programare, astazi
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

    #in caz ca e chiar la inceput (index 0)

    # aici vom vedea daca nu e oke maine, candva, altfel introduce el
    #  insert_reservation(check_fastest_time_day(DateTime.now.day, WEEKDAY_CLOSING_HOUR), { 'BMW' => date }, :after)
  end
end

date = DateTime.new(2021, 4, 20, 8, 0, 0)
date1 = DateTime.new(2021, 4, 20, 8, 0, 0)
date2 = DateTime.new(2021, 4, 20, 10, 0, 0)
date3 = DateTime.new(2021, 4, 20, 10, 0, 0)
date4 = DateTime.new(2021, 4, 20, 12, 0, 0)
date5 = DateTime.new(2021, 4, 20, 12, 0, 0)
date6 = DateTime.new(2021, 4, 20, 14, 0, 0)
date7 = DateTime.new(2021, 4, 20, 14, 0, 0)
date8 = DateTime.new(2021, 4, 20, 16, 0, 0)
date9 = DateTime.new(2021, 4, 20, 16, 0, 0)
date10 = DateTime.new(2021, 4, 21, 12, 0, 0)


scheduler = Scheduler.new

scheduler.agenda['honda'] = date
scheduler.agenda['skoda'] = date1
scheduler.agenda['passat'] = date2
scheduler.agenda['mercedes'] = date3
scheduler.agenda['BMW'] = date4
scheduler.agenda['honda2'] = date5
scheduler.agenda['skoda2'] = date6
scheduler.agenda['passat2'] = date7
scheduler.agenda['mercedes2'] = date8
scheduler.agenda['BMW2'] = date9
scheduler.agenda['BMW3'] = date10


scheduler.make_reservation('MM 37 FRT')
scheduler.agenda.each { |key, value| puts key.to_s + " " + value.to_s}
# scheduler.insert_reservation(1, { 'am' => date1 }, :after)
# puts scheduler.agenda

# puts scheduler.agenda
# scheduler.make_reservation(date4)
# scheduler.make_reservation
# puts scheduler.agenda
# puts scheduler.agenda.values[0].hour
# scheduler.check_fastest_time

require_relative '../E/scheduler'
require_relative '../E/car'
require_relative '../E/car_service'
require 'timecop'

describe 'CarService' do
  subject { CarService.new(Scheduler.new) }
  before { Timecop.freeze(DateTime.new(2021, 4, 22, 10, 0, 0)) }


  describe '.pick_up_car' do

    context 'empty park' do
      it 'picks-up car' do
        result = subject.pick_up_car('MM90KOL')

        expect(result).to eq 'Sorry, the car is not here! Check the number plate!'
      end
    end

    context 'car parked' do
      before { subject.parking << 'MM10FFL' }
      before { subject.parking << 'MM90KOL' }

      it 'picks-up car' do
        result = subject.pick_up_car('MM90KOL')

        expect(result).to eq 'The car with the number plate MM90KOL was picked-up. Another client happy :D'
      end
    end

  end

  describe '.check_status_cars' do

    context 'empty' do
      it 'checks' do
        result = subject.check_status_cars

        expect(result).to eq 'Nothing to clean'
      end
    end
  end
end

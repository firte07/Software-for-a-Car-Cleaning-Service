require 'timecop'
require_relative '../E/scheduler'
require_relative '../E/car'
require_relative '../E/car_service'

describe 'Scheduler' do
  before { Timecop.freeze(DateTime.new(2021, 4, 22, 10, 0, 0)) }
  subject { Scheduler.new }

  describe '.make_fastest_reservation' do

    it 'finds fastest free space' do
      allow(subject).to receive(:receive_confirmation) { 'yes' }

      agenda_size = subject.agenda.size
      subject.make_fastest_reservation('MM37FRT')

      expect(subject.agenda.size).to eq agenda_size + 1
    end
  end

  describe '.insert_client_reservation' do
    let(:number_plate) { 'MM37FRT' }

    context 'weekday open' do
      let(:date_time) { DateTime.new(2021, 4, 22, 12, 0, 0) }

      it 'inserts reservation' do
        subject.insert_client_reservation(date_time, number_plate)
        result = subject.agenda

        expect(result['MM37FRT'].strftime('%Y-%m-%dT%H:%M:%S')).to eq '2021-04-22T12:00:00'
        expect(result.keys[0]).to eq 'MM37FRT'
      end
    end

    context 'weekday closed' do
      let(:date_time) { DateTime.new(2021, 4, 22, 22, 0, 0) }

      it 'inserts reservation' do
        result = subject.insert_client_reservation(date_time, number_plate)

        expect(result).to eq 'We are closed or time is invalid (bad time or full)'
      end
    end

    context 'saturday open' do
      let(:date_time) { DateTime.new(2021, 4, 24, 10, 0, 0) }

      it 'inserts reservation' do
        subject.insert_client_reservation(date_time, number_plate)
        result = subject.agenda

        expect(result['MM37FRT'].strftime('%Y-%m-%dT%H:%M:%S')).to eq '2021-04-24T10:00:00'
        expect(result.keys[0]).to eq 'MM37FRT'
      end
    end

    context 'saturday closed' do
      let(:date_time) { DateTime.new(2021, 4, 24, 22, 0, 0) }

      it 'inserts reservation' do
        result = subject.insert_client_reservation(date_time, number_plate)

        expect(result).to eq 'We are closed or time is invalid (bad time or full)'
      end
    end

    context 'full service' do
      let(:date_time) { DateTime.new(2021, 4, 23, 10, 0, 0) }
      before { subject.agenda = { 'MM90KYT' => DateTime.new(2021, 4, 23, 10, 0, 0), 'CJ60KEQ' => DateTime.new(2021, 4, 23, 10, 0, 0) } }

      it 'inserts reservation' do
        result = subject.insert_client_reservation(date_time, number_plate)

        expect(result).to eq 'We are closed or time is invalid (bad time or full)'
      end
    end

  end
end

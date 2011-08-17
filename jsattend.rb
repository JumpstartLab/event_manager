# Dependencies
require 'csv'
require 'date'
require 'sunlight'
require './string_cleaner'

String.send(:include, StringCleaner)

# Class Definition
class JSAttend
  INVALID_PHONE_NUMBER = "0"*10
  INVALID_ZIPCODE = "00000"
  DEFAULT_INPUT_FILE = "event_attendees.csv"
  Sunlight::Base.api_key = "e179a6973728c4dd3fb1204283aaccb5"
  OUTPUT_DIR = "output"

  def initialize(input_filename = DEFAULT_INPUT_FILE)
    puts "JSAttend Initialized"
    create_output_folder
    @file = CSV.open(input_filename, :headers => true, :header_converters => :symbol)
  end

  def attendee_each    
    @file.each do |attendee|
      yield(attendee) if block_given?
    end    
    @file.rewind
  end

  def print_names
    attendee_each do |data|
      puts "#{data[:first_name]} #{data[:last_name]}"
    end
  end

  def print_phone_numbers
    attendee_each do |line|
      puts clean_phone_number(line[:homephone])
    end
  end

  def clean_phone_number(phone_number)
    number = phone_number.digits

    if number.length == 10
      number
    elsif (number.length == 11) && (number[0] == "1")
      number[1..-1]
    else
      INVALID_PHONE_NUMBER
    end
  end

  def print_zipcodes
    attendee_each do |line|
      puts clean_zipcode(line[:zipcode])
    end
  end

  def clean_zipcode(zipcode)
    zipcode.nil? ? INVALID_ZIPCODE : zipcode.rjust(5, "0")
  end

  def output_clean_data(output_filename)
    output = CSV.open(output_filename, "w")

    open_input_csv_file(@file_name).each_with_index do |line, i|
      output << @file.headers if i == 0
      line[:homephone] = clean_phone_number(line[:homephone])
      line[:zipcode] = clean_zipcode(line[:zipcode])
      output << line
    end

    output.close
  end

  def rep_lookup(zipcode)
    Sunlight::Legislator.all_in_zipcode(zipcode).collect do |legislator|
      "#{legislator.title}. #{legislator.firstname[0]}. #{legislator.lastname} (#{legislator.party})"
    end
  end

  def print_representatives
    attendee_each do |line|
      puts [ line[:last_name], line[:first_name],
             line[:zipcode], rep_lookup(line[:zipcode])].join(", ")
    end
  end

  def create_output_folder
    Dir.mkdir(OUTPUT_DIR) unless Dir.exists?(OUTPUT_DIR)
  end

  def print_letters
    template = File.read("form_letter.html")

    @file.each do |line|
      custom = template.clone
      line.headers.each do |field|
        custom.gsub!("#" + field.to_s, line[field].to_s)
      end
      output_file_for(line) << custom
    end
  end

  def output_file_for(line)
    filename = "#{line[:last_name]}_#{line[:first_name]}.html".downcase
    target = OUTPUT_DIR + "/" + filename
    File.open(target, "w")
  end

  def time_stats
    counters = Array.new(24){0}

    attendee_each do |line|
      # 1: splits: .split[1].split(":")[0]
      # hour = line[:regdate].split[1].split(":")[0].to_i

      # 2: regular expression
      hour = line[:regdate].match(/\s(\d+):/).captures.first.to_i

      # 3: parsing into datetime
      #hour = DateTime.strptime(line[:regdate], "%m/%d/%y %H:%M").hour

      counters[hour] += 1
    end

    puts "Hour\tRegistrations"
    counters.each_with_index do |count, hour|
      puts "#{hour}\t#{count}"
    end
  end

  def state_stats
    counters = {}

    attendee_each do |line|
      if counters.has_key?(line[:state])
        counters[line[:state]] += 1
      else
        counters[line[:state]] = 1
      end
    end

    puts "State\tRegistrations"

    # Sorting:
    # 1: By the number of registrations descending
    counters = counters.sort_by{|state, registrations| registrations}.reverse
    counters.each do |state, registrations|
      puts "#{state}\t#{registrations}"
    end

    # 2: By the state alphabetically (DONE)
    #counters.delete(nil)
    #counters.sort.each do |state, registrations|
    #  puts "#{state}\t#{registrations}"
    #end

    # 3: Alpha by state with ranking
    # AL (32)
    # AR (43)
    # ... hard!
  end
end
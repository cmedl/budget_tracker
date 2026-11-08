#!/usr/bin/ruby

require 'ostruct'
require 'optparse'
require 'csv'
require 'sqlite3'
require 'set'
require 'date'

def CsvSched(income, expenses, yearmonth)
  totals = {}
  p yearmonth
  CSV.foreach(income) do |row|
    #puts("#{row[4]}:#{row[3]}")
    next unless row[2].to_s.start_with?(yearmonth)
    #unless row[2].to_s.start_with?(yearmonth)
    #  next
    #end
    if totals[row[4]]
      totals[row[4]] += row[3].to_i
    else
      totals[row[4]] = row[3].to_i
    end
  end
  CSV.foreach(expenses) do |row|
    next unless row[2].to_s.start_with?(yearmonth)
    if totals[row[5]]
      totals[row[5]] -= row[4].to_i
    else
      totals[row[5]] = 0 - row[4].to_i
    end
  end
  total_value = 0
  totals.each do |key, value|
    puts("#{key}:#{value}")
    total_value += value
  end
  puts("Total Savings this month: #{total_value}")
  puts(" ")
  puts(totals)
  return totals
end

class Budget
  @@BUDGET_DB = "Budget.db"
  def initialize()
    unless File.exists?(@@BUDGET_DB)
      SQLite3::Database.new(@@BUDGET_DB) do |db|
        db.execute("CREATE TABLE budget (
          yearmonth INTEGER,
          type VARCHAR,
          month TEXT,
          total REAL
        );")
      end
    end
  end
end

def parse(args)
  options = OpenStruct.new
  options.bank = ""
  options.mc = ""
  options.year = Date.today.year.to_s
  options.dir = "./inputs"

  opt_parser = OptionParser.new do |opts|
    opts.banner = "Usage: Budget.rb [options]"

    #opts.on("-bBANK", "--bank=BANK", "Bank CSV file") do |b|
    opts.on("-i", "--income [INCOME]", "Bank Account CSV file") do |b|
      options.bank= b
    end
    #opts.on("-mMC", "--mc=MC", "MC CSV file") do |m|
    opts.on("-e", "--expense [EXPENSES]", "Credit Card CSV file") do |m|
      options.mc = m
    end
    opts.on("-y", "--year YEAR", "Year to report on (default: current year)") do |y|
      options.year = y
    end
    opts.on("-d", "--dir DIR", "Directory of input CSV files (default: ./inputs)") do |d|
      options.dir = d
    end

    opts.on("-h", "--help", "Prints this help") do
      puts opts
      exit
    end
  end

  opt_parser.parse!(args)
  options 
end

def selection_types
  File.readlines("selections.txt", chomp: true).map(&:strip)
end

def create_types(hash)
  selection_types.each do |type|
    hash[type] = 0
  end
end

def write_csv(amounts)
  months = amounts.flat_map do |year, year_value|
    year_value.map { |month, month_value| ["#{year}.#{month}", month_value] }
  end.sort_by(&:first)

  CSV.open(Date.today.strftime("%Y.%m.%d.csv"), "w") do |csv|
    csv << ["Category", *months.map(&:first)]
    selection_types.each do |type|
      csv << [type, *months.map { |_, month_value| type == "Income" ? month_value.fetch(type, 0) : month_value.fetch(type, 0).abs }]
    end
  end
end
def print_specific(amount, type, year, month)
  return if type == "BALANCE" or type == "EXPENSES" or type == "HOUSING" or type == "AUTOMOBILE" or type == "CHILDREN" or type == "FOOD++" or type == "VACATION" or type == "MISC"
  return if (type == "Income") 
  return if type == "HouseOther" || type == "House" || type == "HouseMtc" || type == "Insurance" || type == "Utilities" || type == "HouseTax"
  return if type == "Auto" || type == "Lease"
  return if type == "Natalia" || type == "Kid" || type == "RESP/RDSP"
  return if type == "Food" || type == "Pharm" 
  return if type == "Vacation" 
  return if amount == 0
  return if type == "Restaurant"
  return if type == "Gift"
  return if type == "Katie"
  return if type == "Clothes"
  return if type == "Charity"
  return if type == "Stuff"
  return if type == "Other"
  return if type == "LCBO/Beer"
  return if type == "Medical"
  return if type == "Cash"
  #return if type == "Activities"
  puts amount.to_s << " TYPE: " << type << " YEAR: " << year << " MONTH: " << month
end
def print_misc(amount, type, year, month)
  return if type == "BALANCE" or type == "EXPENSES" or type == "HOUSING" or type == "AUTOMOBILE" or type == "CHILDREN" or type == "FOOD++" or type == "VACATION" or type == "MISC"
  return if (type == "Income") 
  return if type == "HouseOther" || type == "House" || type == "HouseMtc" || type == "Insurance" || type == "Utilities" || type == "HouseTax"
  return if type == "Auto" || type == "Lease"
  return if type == "Natalia" || type == "Kid" || type == "RESP/RDSP"
  return if type == "Food" || type == "Pharm" 
  return if type == "Vacation" 
  return if amount == 0
  puts amount.to_s << " TYPE: " << type << " YEAR: " << year << " MONTH: " << month
end
def amounts_get(dir, target_year)
  amounts = {}
  allFiles = Dir.children(dir).sort
  allFiles.each do |file|
    puts file
    sheetType = ""
    CSV.foreach(File.join(dir, file), encoding:'iso-8859-1:utf-8') do |row|
      sheetType = row[0] if sheetType == "" 
      break if sheetType != "IncomeSheet" and sheetType != "ExpenseSheet" and sheetType != "Combined"
      #next unless row[2].to_s.start_with?("2014") or row[2].to_s.start_with?("2015") or row[2].to_s.start_with?("2017") 
      #
      
      if sheetType == "Combined"
        date = row[0]
      else
        date = row[2]
      end
      next if date == nil
      # Handle a few different date formats
      if date[2,1] == "/" and date[5,1] == "/"
        year = date[6,4]
        month = date[0,2]
      elsif date[4,1] == "-" and date[7,1] == "-"
        year = date[0,4]
        month = date[5,2]
      else
        year = date[0,4]
        month = date[4,2]
      end

      #puts year
      next unless year == target_year

      # MEDL
      # next if (month.to_i < 10 || month.to_i < 7) || year.to_i <2016
      # next if (month.to_i < 8 || month.to_i < 7) || year.to_i <2022
      #next if (month.to_i > 3 ) || year.to_i <2016
      if sheetType == "IncomeSheet" 
        type = row[4]
        amount = row[3].to_i
      elsif sheetType == "ExpenseSheet"
        type = row[5]
        amount = -row[4].to_i
      else # Combined
        type = row[4]
        amount = 0
        if row[3] != nil
          amount += row[3].to_i
        end
        if row[2] != nil
          amount -= row[2].to_i
        end
      end
      next if type == nil
      if "Gift" == type
          puts "TYPE: " << type << " YEAR: " << year << " MONTH: " << month
          puts amount.to_i
          print_specific(amount, type, year, month)
      end
      # MEDL 
      #puts "TYPE: " << type << " YEAR: " << year << " MONTH: " << month
      #puts amount.to_i
      #print_specific(amount, type, year, month)
      amounts[year] = {} unless amounts[year] 
      amounts[year][month] = {} unless amounts[year][month]
      create_types(amounts[year][month]) unless amounts[year][month][type]
      #puts "TYPE: " << type << " YEAR: " << year << " MONTH: " << month
      amounts[year][month][type] += amount
    end
  end
  return amounts 
end

def totals_calculate(amounts)
  amounts.each do |year, year_value|
    year_value.each do |month, month_value|
      amounts[year][month]["HOUSING"] = 0 
      amounts[year][month]["HOUSE_M+O"] = 0 
      amounts[year][month]["AUTOMOBILE"] = 0 
      amounts[year][month]["CHILDREN"] = 0 
      amounts[year][month]["FOOD++"] = 0 
      amounts[year][month]["VACATION"] = 0 
      amounts[year][month]["MISC"] = 0 
      amounts[year][month]["EXPENSES"] = 0 
      amounts[year][month]["BALANCE"] = 0 
      month_value.each do |type, amount| 
        next if type == "BALANCE" or type == "EXPENSES" or type == "HOUSING" or type == "HOUSE_M+O" or type == "AUTOMOBILE" or type == "CHILDREN" or type == "FOOD++" or type == "VACATION" or type == "MISC"
        amounts[year][month]["BALANCE"] += amount
        next if (type == "Income") # Calculate all EXPENSES
        if type == "House" || type == "Insurance" || type == "Utilities" || type == "HouseTax" || type == "Katie"
            amounts[year][month]["HOUSING"] += amount
        elsif type == "HouseOther" || type == "HouseMtc"
            amounts[year][month]["HOUSE_M+O"] += amount
        elsif type == "Auto" || type == "Lease"
            amounts[year][month]["AUTOMOBILE"] += amount
        elsif type == "Natalia" || type == "Kid" || type == "RESP/RDSP"
            amounts[year][month]["CHILDREN"] += amount
        elsif type == "Food" || type == "Pharm" 
            amounts[year][month]["FOOD++"] += amount
        elsif type == "Vacation" 
            amounts[year][month]["VACATION"] += amount
        else
            amounts[year][month]["MISC"] += amount
        end
        amounts[year][month]["EXPENSES"] += amount
      end
    end
  end
end
def print_misc_summaries(amounts)
  amounts.each do |year, year_value|
    year_value.each do |month, month_value|
      month_value.each do |type, amount| 
        next if type == "BALANCE" or type == "EXPENSES" or type == "HOUSING" or type = "HOUSING+M+O" or type == "AUTOMOBILE" or type == "CHILDREN" or type == "FOOD++" or type == "VACATION" or type == "MISC"
        next if (type == "Income") 
        next if type == "HouseOther" || type == "House" || type == "HouseMtc" || type == "Insurance" || type == "Utilities" || type == "HouseTax"
        next if type == "Auto" || type == "Lease"
        next if type == "Natalia" || type == "Kid" || type == "RESP/RDSP"
        next if type == "Food" || type == "Pharm" 
        next if type == "Vacation" 
        next if amount == 0
        puts amount.to_s << " TYPE: " << type << " YEAR: " << year << " MONTH: " << month
      end
    end
  end
end
def FAKEtotals_calculate(amounts)
  amounts.each do |year, year_value|
    year_value.each do |month, month_value|
      month_value.each do |who, who_value|
        amounts[year][month][who]["EXPENSES"] = 0 
        amounts[year][month][who]["BALANCE"] = 0 
        who_value.each do |type, amount| 
          next if type == "BALANCE" or type == "EXPENSES"
          amounts[year][month][who]["BALANCE"] += amount
          #next if (type == "Income" or type == "House")
          next if (type == "Income")
          #puts "WHO: " << who << " type: " << type << " amount: " << amount.to_s
          amounts[year][month][who]["EXPENSES"] += amount
          if year == "2015" and month == "01"
            puts "" << type << ":" << amount.to_s
          end
        end
      end
    end
  end
end

def FAKEtotals_dump(totals, person)
  puts "------------------------------------------------------------------------------------------------"
  puts "------------------------- DATA for: " << person
  a_year = Set.new
  a_type = Set.new
  totals.each do |year, year_value|
    a_year.add(year)
    year_value.each do |month, month_value|
      #month_value.each do |type, amount|
      month_value.each do |who, who_value|
        next if who != person
        who_value.each do |type, amount|
          a_type.add(type)
          #puts "" << year << ":" << month << ":" << type << ":" << who << ":" << amount.to_s
        end
      end
    end
  end
  count = 0
  a_type.each do |type|
    printf "\n%10s|" % ""
    totals.each do |year, year_value|
      year_value.each do |month, month_value|
        printf "%4d%2d|" % [year, month.to_i]
        count += 1
      end
    end
    printf ("\n-----------")
    while count > 0
      printf("-------")
      count -= 1
    end
    break
  end
  type_data = {}
  a_type.each do |type|
    printf "\n%10s|" % type.strip 
    totals.each do |year, year_value|
      year_value.each do |month, month_value|
        type_data[type] = {} unless type_data[type]
        type_data[type][year] = 0 unless type_data[type][year]

        if month_value[person][type] 
          type_data[type][year] += month_value[person][type] 
        end
        #print "%6d|" % who_value[type] ? who_value[type] : 0
        if month_value[person][type]
          print "%6d|" % month_value[person][type] 
        else
          print "%6d|" % 0
        end
      end
    end
  end
  printf "\n"
  count = 0
  a_type.each do |type|
    printf "\n%10s|" % ""
    totals.each do |year, year_value|
      printf "%6d|" % year
      count += 1
    end
    printf ("\n-----------")
    while count > 0
      printf("-------")
      count -= 1
    end
    break
  end
  type_data.each do |type, type_value|
    printf "\n%10s|" % type.strip 
    type_value.each do |year, year_value|
      printf "%6d|" % type_data[type][year]  
    end
  end
  printf("\n\n")
end

def totals_dump(totals)
  puts "------------------------------------------------------------------------------------------------"
  a_year = Set.new
  a_type = Set.new
  totals.each do |year, year_value|
    a_year.add(year)
    year_value.each do |month, month_value|
      #month_value.each do |type, amount|
      month_value.each do |type, amount|
        a_type.add(type)
      end
    end
  end
  count = 0
  a_type.each do |type|
    printf "\n%10s|" % ""
    totals.each do |year, year_value|
      year_value.each do |month, month_value|
        printf "%4d%2d|" % [year, month.to_i]
        count += 1
      end
    end
    printf ("\n-----------")
    while count > 0
      printf("-------")
      count -= 1
    end
    break
  end
  type_data = {}
  a_type.each do |type|
    printf "\n%10s|" % type.strip 
    totals.each do |year, year_value|
      year_value.each do |month, month_value|
        type_data[type] = {} unless type_data[type]
        type_data[type][year] = 0 unless type_data[type][year]

        if month_value[type] 
          type_data[type][year] += month_value[type] 
        end
        #print "%6d|" % who_value[type] ? who_value[type] : 0
        if month_value[type]
          print "%6d|" % month_value[type] 
        else
          print "%6d|" % 0
        end
      end
    end
  end
  printf "\n"
  # YEAR PRINTING STARTS BELOW
  count = 0
  a_type.each do |type|
    printf "\n%10s|" % ""
    totals.each do |year, year_value|
      printf "%6d|" % year
      count += 1
    end
    printf ("\n-----------")
    while count > 0
      printf("-------")
      count -= 1
    end
    break
  end
  type_data.each do |type, type_value|
    # Add fancy stuff prior to HOUSING and EXPENSES
    if type == "HOUSING" or type == "EXPENSES"
        printf("\n-------------------------------")
    end
    printf "\n%10s|" % type.strip 
    type_value.each do |year, year_value|
      printf "%6d|" % type_data[type][year]  
    end
  end
  printf("\n\n")
end

def test(ym)
  year = ym[0,4]
  month = ym[4,2]
  puts ym
  puts year
  puts month
  totals = Hash.new(Hash.new(Hash.new()))
  totals[year][month]["blah"] = "1234" 
  puts totals
  puts totals[year]
  puts totals[year][month]
  puts totals[year][month]["blah"]
end

def old_way()
  options = parse(ARGV)
  dude = CsvSched(options.bank, options.mc, options.ym)
  x = test("20150115")
  amounts_get

  #budg = Budget.new
end

#options = OptParser.parse %w[--help]
#old_way
 

options = parse(ARGV)
amounts = amounts_get(options.dir, options.year)
totals_calculate(amounts)
write_csv(amounts)
#print_misc_summaries(amounts)
totals_dump(amounts)

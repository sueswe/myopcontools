#!/usr/bin/env ruby
# frozen_string_literal: true

# apt install ruby-dev, unixodbc, unixodbc-dev
# gem install dbi dbd-odbc ruby-odbc

require 'dbi'
require 'colorize'
require 'optparse'
require_relative 'readconfig'

myname = File.basename(__FILE__)

options = {}
optparse = OptionParser.new do |opts|
  opts.banner = "Usage: #{myname} [options]"

  options[:fieldsep] = ' | '
  opts.on('-s ', '--fieldseparator F', 'optional; Fieldseparator, default is |') do |x|
    options[:fieldsep] = x
  end

  options[:databaseName] = nil
  opts.on('-d', '--databasename DB', 'mandatory; database name (prefix = \'opconxps_\')') do |dbname|
    options[:databaseName] = dbname
  end

  options[:fromdate] = nil
  opts.on('-f', '--from date', 'mandatory; date (YYYY-MM-DD) of Timestamps (>=)') do |date|
    options[:fromdate] = date
  end

  options[:todate] = nil
  opts.on('-t', '--to date', 'optional; date (YYYY-MM-DD) of Timestamps (<=)') do |date|
    options[:todate] = date
  end

  opts.on('-h', '--help', '(Display this screen)') do
    puts 'Description: Search the AUDIT-table.'
    puts opts
    # puts String.colors
    # puts "Sonstiges: ".yellow
    # puts " - Wildcard fuer das Datum ist '%' , bspw. 2021-03-%"
    # puts String.modes
    # puts String.color_samples
    exit
  end
end
optparse.parse!

if options[:databaseName].nil?
  # puts "Missing DB name postifx. Use -h for help.".cyan
  puts optparse
  exit 2
end
if options[:databaseName]
  DB = (options[:databaseName]).to_s
  puts "Name of Database: #{DB}"
end

if options[:fromdate].nil?
  puts 'Missing FROM_DATE (yyyy-mm-dd). Use -h for help.'.cyan
  puts optparse
  exit 2
else
  from_date = (options[:fromdate]).to_s
  puts "fromdate: #{from_date}"
end

if options[:todate].nil?
  to_date = from_date
# puts "Missing TO_DATE (yyyy-mm-dd). Use -h for help.".cyan
# exit 2
else
  to_date = (options[:todate]).to_s
  puts "to-date: #{to_date}"
end

separator = (options[:fieldsep]).to_s
puts "FIELDseparator: #{separator}"

################################################################################
#
# SQL
#
sql = "
SELECT convert(smalldatetime,UPDTIMESTAMP)
    ,LTRIM(RTRIM(OPCONUSERNAME))
    ,HOSTNAME
    ,TBLNAME
    ,BEFOREVALUE
    ,AFTERVALUE
    ,KEY1,key2,key3,key4,key5,key6
FROM AUDITRECSVIEW
WHERE UPDTIMESTAMP >= '#{from_date} 00:00:00.000'
AND UPDTIMESTAMP <= '#{to_date} 23:59:59.999'
ORDER BY UPDTIMESTAMP asc
;
"
################################################################################

def dbConnect
  include Read_config
  $usr = Read_config.get_dbuser
  $pwd = Read_config.get_dbpwd
  DBI.connect("DBI:ODBC:opconxps_#{DB}", $usr.to_s, $pwd.to_s)
end

################################################################################

dbh = dbConnect

sth = dbh.execute(sql)

colCount = sth.column_names.size
# puts "ColCount: " + colCount.to_s.cyan

colNames = ''
sth.column_names.each do |name|
  colNames.concat("#{name} | ")
end
puts colNames

while (row = sth.fetch)
  rowValues = ''
  (0..colCount - 1).each do |n|
    val = row[n].to_s
    rowValues.concat(val + separator)
  end
  puts rowValues
end
sth.finish

dbh&.disconnect

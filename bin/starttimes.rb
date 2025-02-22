#!/usr/bin/env ruby

# apt install ruby-dev, unixodbc, unixodbc-dev
# gem install dbi dbd-odbc ruby-odbc
require 'dbi'
require 'colorize'
require 'optionparser'
require_relative 'readconfig'


myname = File.basename(__FILE__)

options = {}
optparse = OptionParser.new do |opts|
  opts.banner = "Usage: #{myname} [options]"

  options[:fieldsep] = ' | '
  opts.on('-f', '--fieldseparator F', 'optional; Fieldseparator, default is |') do |x|
    options[:fieldsep] = x
  end

  options[:databaseName] = nil
  opts.on('-d', '--databasename DB', 'Name of the database (prefix is \'opconxps_\ \')') do |dbname|
    options[:databaseName] = dbname
  end

  options[:schedname] = nil
  opts.on('-s', '--schedulename SN', 'Name of the schedule (wildcard = %)') do |schedule|
    options[:schedulename] = schedule
  end

  opts.on('-h', '--help', 'Display this screen') do
    puts 'Description: selects jobs with starttimes (only when start-offset not 0).'
    puts opts
    # puts String.colors
    # puts String.modes
    # puts String.color_samples
    exit
  end
end
optparse.parse!
separator = "#{options[:fieldsep]}"
if options[:databaseName].nil?
  puts 'Missing name of database. Use -h for help.'.cyan
  puts optparse
  exit 2
end
if options[:schedulename].nil?
  puts 'Missing schedulename. Use -h for help.'.cyan
  puts optparse
  exit 2
end

if options[:databaseName]
  DB = "#{options[:databaseName]}"
  puts 'Name of database: '.rjust(20) + DB.red
end
if options[:schedulename]
  sched = "#{options[:schedulename]}"
  puts 'Schedulename: '.rjust(20) + sched.red
end

################################################################################
#
# SQL
#
sql = "
SELECT DISTINCT SKDNAME,JOBNAME,CONVERT(datetime,STOFFSET) AS STARTZEIT, FREQNAME
FROM JSKD
JOIN SNAME ON (JSKD.SKDID=SNAME.SKDID)
WHERE STOFFSET != '0'
AND SKDNAME LIKE '#{sched}'
order by STARTZEIT
;
"
################################################################################


################################################################################
#
# Methoden
#
################################################################################
def dbConnect
  include Read_config
  $usr = Read_config.get_dbuser
  $pwd = Read_config.get_dbpwd
  dbh = DBI.connect("DBI:ODBC:opconxps_#{DB}", "#{$usr}", "#{$pwd}")
end

################################################################################

dbh = dbConnect
sth = dbh.execute(sql)
colCount = sth.column_names.size
# puts "ColCount: ".rjust(20) + colCount.to_s.red

colNames = ''
sth.column_names.each do |name|
  colNames.concat(name + separator)
end
puts colNames.blue

while row = sth.fetch
  rowValues = ''

  (0..colCount - 1).each do |n|
    val = row[n].to_s.yellow.rjust(30)
    val.sub!('1900-01-01T', ' ')
    rowValues.concat(val + separator)
  end
  puts rowValues
end
sth.finish

dbh.disconnect if dbh

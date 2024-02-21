#!/usr/bin/env ruby

# apt install ruby-dev, unixodbc, unixodbc-dev
# gem install dbi dbd-odbc ruby-odbc

require 'dbi'
require 'colorize'
require 'optionparser'

class Read_config
  require 'yaml'
  targetDir = ENV['HOME'] + '/bin/'
  $config = targetDir + 'opcon.yaml'

  def get_dbuser
    config = YAML.load_file($config)
    config['opconuser']
  end

  def get_dbpwd
    config = YAML.load_file($config)
    config['opconpassword']
  end
end

myname = File.basename(__FILE__)

options = {}
optparse = OptionParser.new do |opts|
  opts.banner = "Usage: #{myname} [options]"

  options[:fieldsep] = ' | '
  opts.on('-f ', '--fieldseparator F', 'optional; Fieldseparator, default is |') do |x|
    options[:fieldsep] = x
  end

  options[:databaseName] = nil
  opts.on('-d', '--databasename DB', 'mandatory; database name (prefix = \'opconxps_\')') do |dbname|
    options[:databaseName] = dbname
  end

  options[:sched] = nil
  opts.on('-s', '--calname cal', 'Name of the calendar (use % for widcard)') do |landstell|
    options[:sched] = landstell
  end

  options[:master] = nil
  opts.on('-m', '--masterholidaycal', 'List MASTER HOLIDAY CALENDAR') do |_x|
    options[:master] = true
  end

  opts.on('-h', '--help', 'Display this screen') do
    puts 'Description: selects data from calenders.'
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
  puts 'Missing DB name. Use -h for help.'.cyan
  puts optparse
  exit 2
end
if options[:sched].nil?
  puts 'Missing schedule. Use -h for help.'.cyan
  # puts optparse
  # exit 2
end

if options[:databaseName]
  DB = "#{options[:databaseName]}"
  # puts "Name of database: " + DB.red
end
if options[:sched]
  ls = "#{options[:sched]}"
  # puts "Schedulename: " + ls.red
end

################################################################################
#
# SQL
#

sql = if options[:master]
        "(
  select CALNAME, FORMAT(convert(smalldatetime,CALDATE-2),'yyyyMMdd') as DATUM
  from CALDATA
  join CALDESC on CALDATA.CALID = CALDESC.CALID
  where CALNAME like 'Master%'
  --ORDER BY DATUM ASC
  )"
      else
        "
  select CALNAME, SKDNAME, format(convert(smalldatetime,CALDATE-2),'yyyyMMdd') as DATUM
  from CALDATA
  join CALDESC on CALDATA.CALID = CALDESC.CALID
  JOIN SNAME ON (caldesc.SKDID=SNAME.SKDID)
  where CALNAME like '%#{ls}'
  order by DATUM ASC
  "
      end
################################################################################


################################################################################
#
# Methoden
#
################################################################################
def dbConnect
  $usr = Read_config.new.get_dbuser
  $pwd = Read_config.new.get_dbpwd
  dbh = DBI.connect("DBI:ODBC:opconxps_#{DB}", "#{$usr}", "#{$pwd}")
end
################################################################################

dbh = dbConnect

sth = dbh.execute(sql)

colCount = sth.column_names.size

colNames = ''
sth.column_names.each do |name|
  colNames.concat(name + separator)
end
puts colNames

while row = sth.fetch
  rowValues = ''

  (0..colCount - 1).each do |n|
    val = row[n].to_s
    val.sub!('T00:00:00+00:00', '')
    rowValues.concat(val + separator)
  end
  puts rowValues
end
sth.finish

dbh.disconnect if dbh

#!/usr/bin/env ruby

# apt install ruby-dev, unixodbc, unixodbc-dev
# gem install dbi dbd-odbc ruby-odbc

require 'dbi'
require 'colorize'
require 'optparse'

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

  options[:countdistinct] = nil
  opts.on('-c', '--count-distinct', 'retrieve the count of distinct (different) frequencies') do |_x|
    options[:countdistinct] = true
  end

  opts.on('-h', '--help', 'Display this screen') do
    puts 'Description: selects all Frequencies, including Frequency-Code and After/On/Before/NotSchedule-configuration.'
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
  # puts "Missing DB name. Use -h for help.".cyan
  puts optparse
  exit 2
end


DB = "#{options[:databaseName]}" if options[:databaseName]

sql_distinct = "
  select distinct FREQCODE, count(distinct FREQNAME) as ct from JSKD
  group by FREQCODE
  having count(distinct FREQNAME) > 1
  ;
"

sqlOLD = "
SELECT DISTINCT FREQNAME, FREQCODE, AOBN, CALID
--SELECT DISTINCT FREQNAME, FREQCODE, AOBN, SKDNAME, JOBNAME
FROM jskd
JOIN sname ON jskd.SKDID = sname.skdid
order by FREQNAME
;
"


sql = "
  SELECT DISTINCT FREQNAME, FREQCODE, AOBN, CALNAME
  FROM jskd
  JOIN sname ON jskd.SKDID = sname.skdid
  join CALDESC on jskd.CALID = CALDESC.CALID
  order by CALNAME desc
  ;
"

def dbConnect
  $usr = Read_config.new.get_dbuser
  $pwd = Read_config.new.get_dbpwd
  dbh = DBI.connect("DBI:ODBC:opconxps_#{DB}", "#{$usr}", "#{$pwd}")
end

dbh = dbConnect

sth = if options[:countdistinct] == true
        dbh.execute(sql_distinct)
      else
        dbh.execute(sql)
      end

colCount = sth.column_names.size
colNames = ''
sth.column_names.each do |name|
  colNames.concat(name + separator)
end
while row = sth.fetch
  rowValues = ''
  (0..colCount - 1).each do |_n|
    frequname = row[0].to_s
    frequcode = row[1].to_s
    aobn = row[2].to_i
    calname = row[3].to_s

    calname = '(no cal)' if calname == '0'
    case aobn
    when 1
      aobn = 'After Date (1)'
    when 2
      aobn = 'On Date (2)'
    when 4
      aobn = 'Before Date (4)'
    when 8
      aobn = 'Do Not Schedule (8)'
    end
    # rowValues.concat(val + ' | ')
    rowValues = "#{frequname} #{separator} #{frequcode} #{separator} #{aobn} #{separator} #{calname}" + "\n"
  end
  puts rowValues
end

sth.finish
puts "(AOBN-Value wird nicht in den FREQU-Code miteinberechnet.)"
dbh.disconnect if dbh

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
  opts.on('-f', '--fieldseparator F', 'optional; Fieldseparator, default is |') do |x|
    options[:fieldsep] = x
  end

  options[:databaseName] = nil
  opts.on('-d', '--databasename DB', 'mandatory; database name (prefix = \'opconxps_\')') do |dbname|
    options[:databaseName] = dbname
  end


  options[:scheduledate] = nil
  opts.on('-w', '--when-schedule-date SD', 'when: Schedule-Date (YYYY-MM-DD)') do |schdate|
    options[:scheduledate] = schdate
  end

  options[:schedulename] = nil
  opts.on('-s', '--schedule-name SN', 'Schedule-Name') do |schname|
    options[:schedulename] = schname
  end

  options[:jobname] = nil
  opts.on('-j', '--jobname JN', 'Job-Name') do |jbn|
    options[:jobname] = jbn
  end

  options[:value] = nil
  opts.on('-i', '--startimage S', 'Startimage-field') do |val|
    options[:value] = val
  end

  opts.on('-h', '--help', 'Display this screen') do
    puts 'Description: selects DAILY-Jobs - configurations.'
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
else
  DB = "#{options[:databaseName]}"
  # puts "Name of Database: ".rjust(20) + DB.red
end

SCHEDULENAME =
if options[:schedulename].nil?
  '%'
else
  options[:schedulename]
end
# puts "Schedulename: ".rjust(20) + SCHEDULENAME.red

JOBNAME =
if options[:jobname].nil?
  '%'
else
  options[:jobname]
end
# puts "Job: ".rjust(20) + JOBNAME.red

STARTIMAGE =
if options[:value].nil?
  '%'
else
  options[:value]
end
# puts "ja-value: ".rjust(20) + JAVALUE.red

SKDDATE =
if options[:scheduledate].nil?
    puts optparse
    exit 2
else
    options[:scheduledate]
end

################################################################################
#
# SQL
#

sql = "
SELECT skddate,skdname,jobname,start_image,parameter
FROM
(
select format(convert(DATETIME,sm.skddate)-2,'yyyy-MM-dd') AS skddate,skdname,sm.jobname,sma.savalue AS start_image,
(
    SELECT savalue
    FROM SMASTER_AUX sma2
    WHERE sma2.JOBNAME = sm.jobname
    AND sma2.skdid = sm.skdid
    AND sma2.sAFC = 6002
    AND sma2.skddate = sm.skddate
) as parameter
from SMASTER sm
join sname on sm.skdid = sname.skdid
join SMASTER_AUX sma on sm.skdid = sma.skdid and sm.jobname = sma.jobname AND sm.skddate = sma.skddate
where sma.safc = 6001
) AS wrapper
WHERE skddate LIKE '#{SKDDATE}'
AND skdname LIKE '#{SCHEDULENAME}'
AND jobname LIKE '#{JOBNAME}'
AND start_image LIKE '#{STARTIMAGE}'
"

################################################################################
def dbConnect
    $usr = Read_config.new.get_dbuser
    $pwd = Read_config.new.get_dbpwd
    dbh = DBI.connect("DBI:ODBC:opconxps_#{DB}", "#{$usr}", "#{$pwd}")
  end
  ################################################################################
  
  dbh = dbConnect
  
  if options[:nulljob].nil?
      sth = dbh.execute(sql)
  else
      sth = dbh.execute(sql_null_job)
  end
  
  colCount = sth.column_names.size
  # puts "(ColCount: " + colCount.to_s.cyan + ")"
  
  colNames = ''
  sth.column_names.each do |name|
    colNames.concat(name + separator)
  end
  # puts colNames
  
  while row = sth.fetch
    rowValues = ''
    (0..colCount - 1).each do |n|
      # val = row[n].to_s.yellow
      val = row[n].to_s
      rowValues.concat(val + separator)
    end
    puts rowValues
  end
  sth.finish
  
  dbh.disconnect if dbh
  
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

  opts.on('-n','--nulljobs','select only NULL Jobs') do
    options[:nulljob] = true
  end

  options[:fieldsep] = ' | '
  opts.on('-f', '--fieldseparator F', 'optional; Fieldseparator, default is |') do |x|
    options[:fieldsep] = x
  end

  options[:databaseName] = nil
  opts.on('-d', '--databasename DB', 'mandatory; database name (prefix = \'opconxps_\')') do |dbname|
    options[:databaseName] = dbname
  end

  options[:schedulename] = nil
  opts.on('-s', '--schedule-name SN', 'optional; Schedule-Name') do |schname|
    options[:schedulename] = schname
  end

  options[:jobname] = nil
  opts.on('-j', '--jobname JN', 'optional; Job-Name') do |jbn|
    options[:jobname] = jbn
  end

  options[:value] = nil
  opts.on('-v', '--value V', 'optional; JA-Value') do |val|
    options[:value] = val
  end

  opts.on('-h', '--help', 'Display this screen') do
    puts 'Description: selects MASTER-Jobs - configurations.'
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

JAVALUE =
if options[:value].nil?
  '%'
else
  options[:value]
end
# puts "ja-value: ".rjust(20) + JAVALUE.red


################################################################################
#
# SQL
#
sql = "
select skdname,jmaster.jobname,javalue,jafc
from jmaster
join sname on jmaster.skdid = sname.skdid
join jmaster_aux on jmaster.skdid = jmaster_aux.skdid and jmaster.jobname = jmaster_aux.jobname
where skdname like '#{SCHEDULENAME}'
and jmaster.jobname like '#{JOBNAME}'
and javalue like '#{JAVALUE}'
"

sql_null_job = "
select skdname,jmaster.jobname
from jmaster
join sname on jmaster.skdid = sname.skdid
where skdname like '#{SCHEDULENAME}'
and jmaster.jobname like '#{JOBNAME}'
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

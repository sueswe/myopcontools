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

options = {}
optparse = OptionParser.new do |opts|
  opts.banner = 'Usage: jobs-and-department.rb [options]'
  options[:fieldsep] = ' | '
  opts.on('-f', '--fieldseparator F', 'optional; Fieldseparator, default is |') do |x|
    options[:fieldsep] = x
  end
  options[:databaseName] = nil
  opts.on('-d', '--databasename DB', 'Database') do |dbname|
    options[:databaseName] = dbname
  end
  options[:schedule] = nil
  opts.on('-s', '--schedule SCHEDULENAME', 'Schedule Name (no wildcard needed)') do |sn|
    options[:schedule] = sn
  end

  opts.on('-h', '--help', 'Display this screen') do
    puts 'Description: show MASTER-Job-configurations in context with departments .'
    puts opts
    exit
  end
end
optparse.parse!

separator = "#{options[:fieldsep]}"

if options[:databaseName].nil?
  # text = "use -h for Help."
  # puts text.cyan
  puts optparse
  exit 2
end

if options[:databaseName]
  DB = "#{options[:databaseName]}"
  puts 'Database: ' + DB.yellow
end

if options[:schedule]
  schedulename = "#{options[:schedule]}"
  puts 'Schedule: ' + schedulename.yellow
end

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
#
# SQL
#
structuredQueryLanguage = "
  select SKDNAME,JOBNAME,DEPTNAME
from jmaster
join sname on jmaster.skdid = sname.skdid
JOIN depts ON JMASTER.DEPTID = DEPTS.DEPTID
where skdname LIKE '%#{schedulename}%'
"
#
#
################################################################################

################################################################################

dbh = dbConnect

sth = dbh.execute(structuredQueryLanguage)

colCount = sth.column_names.size
colNames = ''
sth.column_names.each do |name|
  colNames.concat(name + separator)
end
puts colNames

while row = sth.fetch
  rowValues = ''
  # for i in (0 .. 9) do
  (0..colCount - 1).each do |n|
    val = row[n]
    val = '<<NULL>>' if val.nil?
    rowValues.concat(val + separator)
  end
  puts rowValues
end
sth.finish

dbh.disconnect if dbh

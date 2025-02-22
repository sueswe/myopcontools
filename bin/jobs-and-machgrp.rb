#!/usr/bin/env ruby

# apt install ruby-dev, unixodbc, unixodbc-dev
# gem install dbi dbd-odbc ruby-odbc

require 'dbi'
require 'colorize'
require 'optionparser'
require_relative 'readconfig'



options = {}
optparse = OptionParser.new do |opts|
  opts.banner = 'Usage: properties [options]'
  options[:databaseName] = nil
  opts.on('-d', '--databasename DB', 'Database') do |dbname|
    options[:databaseName] = dbname
  end
  options[:fieldsep] = ' | '
  opts.on('-f', '--fieldseparator F', 'optional; Fieldseparator, default is |') do |x|
    options[:fieldsep] = x
  end
  options[:schedule] = nil
  opts.on('-s', '--schedule SCHEDULENAME', 'Schedule Name (Optional)') do |sn|
    options[:schedule] = sn
  end
  options[:machgrp] = nil
  opts.on('-m', '--machgrp MACHGRP', 'Machinegroup name') do |mg|
    options[:machgrp] = mg
  end
  opts.on('-h', '--help', 'Display this screen') do
    puts 'Description: show MASTER-Job-configurations in context with machine groups.'
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

if options[:machgrp]
  machinegroup = "#{options[:machgrp]}"
  puts 'Machgrp: ' + machinegroup.yellow
else
  puts 'ERROR: Need a MACHGRP.'
  puts optparse
  exit 1
end

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
#
# SQL
#
structuredQueryLanguage = "
SELECT
  MACHGRP,JOBNAME,SKDNAME
FROM [dbo].[JMASTER]
 JOIN MACHGRPS  ON (jmaster.MACHGRPID=MACHGRPS.MACHGRPID)
 JOIN SNAME ON (jmaster.SKDID=SNAME.SKDID)
where SKDNAME like '%#{schedulename}%'
and MACHGRP like '%#{machinegroup}%'
order by SKDNAME
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

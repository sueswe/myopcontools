#!/usr/bin/env ruby

# apt install ruby-dev, unixodbc, unixodbc-dev
# gem install dbi dbd-odbc ruby-odbc

require 'dbi'
require 'colorize'
require 'optionparser'
require_relative 'readconfig'



################################################################################
#
# SQL
#
sql = "
SELECT
   SKDNAME,JOBNAME,FREQNAME
 FROM [dbo].[JSKD]
 JOIN SNAME ON (jskd.SKDID = SNAME.SKDID)
 --where JAVALUE = '3'
 --AND (JAFC  LIKE '6001' OR JAFC  LIKE '6002')
 WHERE STSTATUS = '-99'
 ORDER BY SKDNAME
 ;
"
################################################################################

options = {}
optparse = OptionParser.new do |opts|
  opts.banner = 'Usage: lsam [options]'
  options[:fieldsep] = ' | '
  opts.on('-f ', '--fieldseparator F', 'optional; Fieldseparator, default is |') do |x|
    options[:fieldsep] = x
  end
  options[:databaseName] = nil
  opts.on('-d', '--databasename DB', 'DB-Name') do |dbname|
    options[:databaseName] = dbname
  end
  opts.on('-h', '--help', 'Display this screen') do
    puts 'Description: lookup jobs with a disabled frequency.'
    puts opts
    exit
  end
end
optparse.parse!

separator = "#{options[:fieldsep]}"

if options[:databaseName].nil?
  puts optparse
  # text = "use -h for Help."
  # puts text.cyan
  exit 2
end

if options[:databaseName]
  DB = "#{options[:databaseName]}"
  puts 'Name of Database: ' + DB.red
end

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

colNames = ''
sth.column_names.each do |name|
  colNames.concat(name + separator)
end

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

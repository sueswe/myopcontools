#!/usr/bin/env ruby

# apt install ruby-dev, unixodbc, unixodbc-dev
# gem install dbi dbd-odbc ruby-odbc

require 'dbi'
require 'colorize'
require 'optionparser'
require_relative 'readconfig'



myname = File.basename(__FILE__)

################################################################################
#
# SQL
#

machgrps_OLD = "
  SELECT DISTINCT machgrp,machname
  FROM MACHS_AUX
  JOIN MACHS ON MACHS_AUX.machid = MACHS.machid
  JOIN MACHGRPS ON MACHS_aux.mavalue = MACHGRPS.machgrpid
  WHERE mafc = 121
  ORDER BY MACHGRP
"

machgrps = "
SELECT DISTINCT machgrp,
 (SELECT mavalue
   FROM MACHS_AUX ma2
   WHERE ma2.MAFC = 129
   AND 	ma2.MACHID = ma1.machid
 ), machname
 FROM MACHS_AUX ma1
 JOIN MACHS ON ma1.machid = MACHS.machid
 JOIN MACHGRPS ON ma1.mavalue = MACHGRPS.machgrpid
 WHERE ma1.mafc = 121
 ORDER BY MACHGRP
 "

################################################################################

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
  opts.on('-h', '--help', 'Display this screen') do
    puts 'Description: selects machinegroups and machines.'
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
  # puts "Name of database: " + DB.red
end

################################################################################
#
# Methods
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

sth = dbh.execute(machgrps)

colCount = sth.column_names.size
# puts "ColCount:         " + colCount.to_s.red
colNames = ''
sth.column_names.each do |name|
  colNames.concat(name + separator)
end
# puts colNames.blue

while row = sth.fetch
  rowValues = ''
  # for i in (0 .. 9) do
  (0..colCount - 1).each do |n|
    
    val = row[n]
    val = '<<NULL>>' if val.nil?
    val = val.gsub(/\s+/, "")

    rowValues.concat(val + separator)
  end
  puts rowValues
end
sth.finish

dbh.disconnect if dbh

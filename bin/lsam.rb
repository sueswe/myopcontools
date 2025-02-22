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
lsamList = "
  SELECT machname as Host, ma.mavalue as OS, ma2.MAVALUE as LSAMversion, ma3.MAVALUE as host, ma4.MAVALUE, ma5.MAVALUE, NETSTATUS
      FROM MACHS m
      JOIN MACHS_AUX ma ON m.machid = ma.machid AND ma.mafc = 137
      JOIN MACHS_AUX ma2 ON m.machid = ma2.machid AND ma2.mafc = 135
      JOIN MACHS_AUX ma3 ON m.machid = ma3.machid AND ma3.mafc = 129
      JOIN MACHS_AUX ma4 ON m.machid = ma4.machid AND ma4.mafc = 120
      JOIN MACHS_AUX ma5 ON m.machid = ma5.machid AND ma5.mafc = 143
      --ORDER BY OS
      ORDER BY LSAMversion DESC
    "
################################################################################

options = {}
optparse = OptionParser.new do |opts|
  opts.banner = 'Usage: lsam [options]'

  options[:fieldsep] = ' | '
  opts.on('-f', '--fieldseparator F', 'optional; Fieldseparator, default is |') do |x|
    options[:fieldsep] = x
  end

  options[:databaseName] = nil
  opts.on('-d', '--databasename DB', 'mandatory; database name (prefix = \'opconxps_\')') do |dbname|
    options[:databaseName] = dbname
  end
  opts.on('-h', '--help', 'Display this screen') do
    puts 'Description: selects agents, OS, ports, and connect-status.'
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
  puts 'Name of database: ' + DB.red
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

puts "NETSTATUS:
This column contains the current status of the network connections between SMANetCom and the LSAM machines."
# puts "OPERSTATUS:
#    This column contains the current statuses of the LSAMs as set by Events or by the graphical interfaces.
#    These statuses decide whether SMANetCom should communicate with each LSAM.
# "

dbh = dbConnect
sth = dbh.execute(lsamList)
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
    # rowValues.concat(val.ljust(30) + " ; ")
    rowValues.concat(val + separator)
  end
  puts rowValues
end
sth.finish

dbh.disconnect if dbh

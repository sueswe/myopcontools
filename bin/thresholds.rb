#!/bin/env ruby

require 'dbi'
require 'colorize'
require 'optionparser'
require_relative 'readconfig'

################################################################################
#
# SQL
#
sql = "
--select THRESHDESC,THRESHVAL,THRESHUSED
select THRESHDESC,THRESHUSED
from THRESH 
where THRESHDESC like '%'
"
################################################################################
myname = File.basename(__FILE__)
options = {}
optparse = OptionParser.new do |opts|
  opts.banner = "Usage: #{myname} [options]"

  options[:fieldsep] = ' | '
  opts.on('-s ', '--fieldseparator F', 'optional; Fieldseparator, default is |') do |x|
    options[:fieldsep] = x
  end

  options[:databaseName] = nil
  opts.on('-d', '--databasename DB', 'mandatory; database name (prefix = \'opconxps_\')') do |dbname|
    options[:databaseName] = dbname
  end
  opts.on('-h', '--help', 'Display this screen') do
    puts 'Description: used thesholds.'
    puts opts
    exit
  end
end
optparse.parse!

separator = "#{options[:fieldsep]}"

if options[:databaseName].nil?
  text = 'use -h for Help.'
  puts text.cyan
  puts optparse
  exit 2
end

if options[:databaseName]
  DB = "#{options[:databaseName]}"
  puts 'Name of Database: ' + DB.red
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

sth = dbh.execute(sql)

colCount = sth.column_names.size
colNames = ''
sth.column_names.each do |name|
    #colNames.concat(name.ljust(30))
    colNames.concat(name + separator)
end
puts colNames


threshold_data = []

while row = sth.fetch
  rowValues = ''
  (0..colCount - 1).each do |n|
    val = row[n].to_s
    val = '<<NULL>>' if val.nil?
    #puts "#{val}"
    rowValues.concat(val + separator)
  end
  #puts rowValues
  threshold_data.push(rowValues)
end
sth.finish
dbh.disconnect if dbh


t_ok = 0
t_error = 0
errorThresholdData = Array.new
threshold_data.each { 
    x = _1
    if x.split[2].to_i != 0
        puts "Achtung, Ressource ist nicht auf 0 : #{x}".red
        t_error += 1
        errorThresholdData.push(x)
    else
        # puts "#{x}".green
        t_ok += 1
    end
}

if t_error > 0
  where_am_i = %x(hostname)
  puts "#{t_ok}".green + " sind OK, " + "#{t_error}".red + " sind in Verwendung." 

  body = "#{t_ok} sind OK (auf 0), #{t_error} sind in Verwendung.\n" + 
  errorThresholdData.to_s + "
  ---
  This mail was sent from #{myname}@#{where_am_i}
  "

  # puts body
  r = system("mailer -t werner.suess@itsv.at,rz.om.stp@itsv.at -s \"THRESHOLDCHECK #{DB}\" -b \"#{body}\"")
  puts "Sent mail: " + r.to_s
else
  puts "#{t_ok}".green + " sind OK, " + "#{t_error}".red + " sind in Verwendung." 
end

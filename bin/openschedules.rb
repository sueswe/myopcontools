#!/usr/bin/env ruby

# Open Schedules.

require 'dbi'
require 'optionparser'
require 'colorize'
require_relative 'readconfig'



sql = '
SELECT top %d convert(datetime,skddate)-2,skdname,count(jobname)
FROM SMASTER
JOIN SNAME ON SMASTER.skdid = SNAME.skdid
WHERE jobstatus = 0
GROUP BY skddate,skdname
ORDER BY skddate
'

myname = File.basename(__FILE__)
options = {}
optparse = OptionParser.new do |opts|
  opts.banner = "Usage: #{myname} [options]"

  options[:fieldsep] = ' | '
  opts.on('-f', '--fieldseparator F', 'optional; Fieldseparator, default is |') do |x|
    options[:fieldsep] = x
  end

  options[:databasename] = nil
  opts.on('-d', '--databasename DB', 'mandatory; database name (prefix = \'opconxps_\')') do |dbname|
    options[:databasename] = dbname
  end
  options[:number] = 15
  opts.on('-n', '--number NUM', 'Output the last NUM lines, instead of the last 15') do |lines|
    options[:number] = lines
  end
  options[:quiet] = false
  opts.on('-q', '--quiet', 'Don\'t post to Chat') do
    options[:quiet] = true
  end
  opts.on('-h', '--help', 'Display this screen') do
    puts 'Description: selects open schedules (not in state completed).'
    puts opts
    # puts String.colors
    # puts String.modes
    # puts String.color_samples
    exit
  end
end
optparse.parse!

separator = "#{options[:fieldsep]}"

if options[:databasename]

  # Ruby Constants
  # https://www.tutorialspoint.com/ruby/ruby_variables.htm
  # Constants begin with an uppercase letter. Constants defined within a
  # class or module can be accessed from within that class or module,
  # and those defined outside a class or module can be accessed globally.

  $dataBaseShortname = "#{options[:databasename]}"
else
  puts "Sorry, missing DATABASE-Name-Option.\nUse '#{myname} -h' for help.".red
  puts optparse
  exit 1
end


################################################################################
def dbConnect
  include Read_config
  $usr = Read_config.get_dbuser
  $pwd = Read_config.get_dbpwd
  dbh = DBI.connect("DBI:ODBC:opconxps_#{$dataBaseShortname}", "#{$usr}", "#{$pwd}")
end
################################################################################

dbh = dbConnect
sth = dbh.execute(sql % options[:number])
colCount = sth.column_names.size
colNames = ''
# sth.column_names.each do |name|
#  colNames.concat(name + " | ")
# end
# puts colNames

result = ''

while row = sth.fetch
  rowValues = ''
  (0..colCount - 1).each do |n|
    val = row[n].to_s
    val.sub!('T00:00:00+00:00', '')
    rowValues.concat(val + separator)
  end
  puts rowValues
  result = result.concat(" ; \n" + rowValues)
end
sth.finish
dbh.disconnect if dbh


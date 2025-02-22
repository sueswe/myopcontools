#!/usr/bin/env ruby

# apt install ruby-dev, unixodbc, unixodbc-dev
# gem install dbi dbd-odbc ruby-odbc

require 'dbi'
require 'colorize'
require 'optionparser'
require_relative 'readconfig'



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

  opts.on('-h', '--help', 'Display this screen') do
    puts 'Description: selects user, login-time and client-version.'
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
  puts 'Missing DB name. Use -h for help.'.cyan
  puts optparse
  exit 2
end

if options[:databaseName]
  DB = "#{options[:databaseName]}"
  puts 'Name of database: ' + DB
end

################################################################################
#
# SQL
#
sql = "
select   USERSIGNON
        ,USERNAME
        ,UAVALUE
    from USERS_AUX
JOIN USERS ON (USERS.USERID = USERS_AUX.USERID)
where UAFC = '131'
ORDER BY USERSIGNON
;
"
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
# sth.column_names.each do |name|
#    colNames.concat(name + " | ")
# end
# puts colNames.blue

while row = sth.fetch
  rowValues = ''
  (0..colCount - 1).each do |n|
    n.to_s.chomp
    val = row[n].rstrip
    rowValues.concat(val + separator)
  end
  puts rowValues
end
sth.finish

dbh.disconnect if dbh

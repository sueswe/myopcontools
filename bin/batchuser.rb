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
sql = 'select USERSPEC from USRSECUR ORDER BY USERSPEC ASC'
################################################################################

options = {}
optparse = OptionParser.new do |opts|
  opts.banner = 'Usage: lsam [options]'

  options[:fieldsep] = ' | '
  opts.on('-s ', '--fieldseparator F', 'optional; Fieldseparator, default is |') do |x|
    options[:fieldsep] = x
  end

  options[:databaseName] = nil
  opts.on('-d', '--databasename DB', 'mandatory; database name (prefix = \'opconxps_\')') do |dbname|
    options[:databaseName] = dbname
  end
  opts.on('-h', '--help', 'Display this screen') do
    puts 'Description: selects the batch-user.'
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
# puts "ColCount:         " + colCount.to_s.red

colNames = ''
# sth.column_names.each do |name|
# colNames.concat(name.ljust(30))
# colNames.concat(name + " | ")
# end
# puts colNames

while row = sth.fetch
  rowValues = ''
  # for i in (0 .. 9) do
  (0..colCount - 1).each do |n|
    val = row[n]
    val = '<<NULL>>' if val.nil?
    # rowValues.concat(val.ljust(30) + " ; ")
    # rowValues.concat(val + ' ; ')
    rowValues.concat(val)
  end
  puts rowValues
end
sth.finish

dbh.disconnect if dbh

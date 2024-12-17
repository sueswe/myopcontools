#!/usr/bin/env ruby

# apt install ruby-dev, unixodbc, unixodbc-dev
# gem install dbi dbd-odbc ruby-odbc

require 'dbi'
require 'colorize'
require 'optparse'
require_relative 'readconfig'




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

  
  opts.on('-h', '--help', '(Display this screen)') do
    puts 'Description: Get a list of databases file with size and free space for a database in SQL Server.'
    puts opts
    # puts String.colors
    # puts "Sonstiges: ".yellow
    # puts " - Wildcard fuer das Datum ist '%' , bspw. 2021-03-%"
    # puts String.modes
    # puts String.color_samples
    exit
  end
end
optparse.parse!

if options[:databaseName].nil?
  # puts "Missing DB name postifx. Use -h for help.".cyan
  puts optparse
  exit 2
end
if options[:databaseName]
  DB = "#{options[:databaseName]}"
  puts 'Name of Database: ' + DB
end


separator = "#{options[:fieldsep]}"
puts "FIELDseparator: #{separator}"


################################################################################
#
# SQL
# https://www.sqlshack.com/how-to-determine-free-space-and-file-size-for-sql-server-databases/
#
sql = "
SELECT DB_NAME() AS DbName, 
    name AS FileName, 
    type_desc,
    size/128.0 AS CurrentSizeMB,  
    size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT)/128.0 AS FreeSpaceMB
FROM sys.database_files
WHERE type IN (0,1);
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
# puts "ColCount: " + colCount.to_s.cyan

colNames = ''
sth.column_names.each do |name|
  colNames.concat(name + ' | ')
end
puts colNames

while row = sth.fetch
  rowValues = ''
  (0..colCount - 1).each do |n|
    val = row[n].to_s
    rowValues.concat(val + separator)
  end
  puts rowValues
end
sth.finish

dbh.disconnect if dbh

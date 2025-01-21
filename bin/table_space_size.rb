#!/usr/bin/env ruby

require 'dbi'
require 'colorize'
require 'optionparser'
require_relative 'readconfig'


################################################################################
#
# SQL
#
#sql = "EXEC sp_spaceused N'dbo.HISTORY'"
sql = "
SELECT 
    t.name AS TableName,
    s.name AS SchemaName,
    p.rows,
    SUM(a.total_pages) * 8 AS TotalSpaceKB, 
    CAST(ROUND(((SUM(a.total_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS TotalSpaceMB,
    SUM(a.used_pages) * 8 AS UsedSpaceKB, 
    CAST(ROUND(((SUM(a.used_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS UsedSpaceMB, 
    (SUM(a.total_pages) - SUM(a.used_pages)) * 8 AS UnusedSpaceKB,
    CAST(ROUND(((SUM(a.total_pages) - SUM(a.used_pages)) * 8) / 1024.00, 2) AS NUMERIC(36, 2)) AS UnusedSpaceMB
FROM 
    sys.tables t
INNER JOIN      
    sys.indexes i ON t.object_id = i.object_id
INNER JOIN 
    sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
INNER JOIN 
    sys.allocation_units a ON p.partition_id = a.container_id
LEFT OUTER JOIN 
    sys.schemas s ON t.schema_id = s.schema_id
WHERE 
    t.name NOT LIKE 'dt%' 
    AND t.is_ms_shipped = 0
    AND i.object_id > 255 
GROUP BY 
    t.name, s.name, p.rows
ORDER BY 
    TotalSpaceMB DESC, t.name
"
################################################################################

options = {}
optparse = OptionParser.new do |opts|
  opts.banner = 'Usage: table_space_size [options]'

  options[:fieldsep] = ' | '
  opts.on('-s ', '--fieldseparator F', 'optional; Fieldseparator, default is |') do |x|
    options[:fieldsep] = x
  end

  options[:databaseName] = nil
  opts.on('-d', '--databasename DB', 'mandatory; database name (prefix = \'opconxps_\')') do |dbname|
    options[:databaseName] = dbname
  end
  opts.on('-h', '--help', 'Display this screen') do
    puts 'Description: selects table spaces in kB, MB '
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
 sth.column_names.each do |name|
 #colNames.concat(name.ljust(30))
 colNames.concat(name + separator)
 end
 puts colNames

while row = sth.fetch
  rowValues = ''
  # for i in (0 .. 9) do
  (0..colCount - 1).each do |n|
    val = row[n].to_s
    val = '<<NULL>>' if val.nil?
    # rowValues.concat(val.ljust(30) + " ; ")
    rowValues.concat(val + separator)
    # rowValues.concat(val)
  end
  puts rowValues
end
sth.finish

dbh.disconnect if dbh

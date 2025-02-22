#!/usr/bin/env ruby

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

  options[:schedulename] = nil
  opts.on('-s', '--schedule-name SN', 'optional; Schedule-Name') do |schname|
    options[:schedulename] = schname
  end

  options[:jobname] = nil
  opts.on('-j', '--jobname JN', 'Job-Name') do |jbn|
    options[:jobname] = jbn
  end

  opts.on('-h', '--help', 'Display this screen') do
    puts 'Description: selects MASTER-Jobs with departement.'
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
  # puts "Missing DB name. Use -h for help.".cyan
  puts optparse
  exit 2
else
  DB = "#{options[:databaseName]}"
  # puts "Name of Database: ".rjust(20) + DB.red
end

SCHEDULENAME =
if options[:schedulename].nil?
  '%'
else
  options[:schedulename]
end
# puts "Schedulename: ".rjust(20) + SCHEDULENAME.red

JOBNAME =
if options[:jobname].nil?
  '%'
else
  options[:jobname]
end


SQL = "select SKDNAME,JOBNAME,DEPTNAME
from JMASTER
    join DEPTS on (JMASTER.DEPTID = DEPTS.DEPTID)
    join SNAME on (JMASTER.SKDID = SNAME.SKDID)
--where DEPTNAME not like '11'
where SKDNAME like '#{SCHEDULENAME}'
and JOBNAME like '#{JOBNAME}'
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
sth = dbh.execute(SQL)

colCount = sth.column_names.size
# puts "(ColCount: " + colCount.to_s.cyan + ")"

colNames = ''
sth.column_names.each do |name|
    colNames.concat(name + separator)
end
# puts colNames

while row = sth.fetch
    rowValues = ''
    (0..colCount - 1).each do |n|
        # val = row[n].to_s.yellow
        val = row[n].to_s
        rowValues.concat(val + separator)
    end
    puts rowValues
end
sth.finish

dbh.disconnect if dbh






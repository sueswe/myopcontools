#!/usr/bin/env ruby

require 'dbi'
require 'colorize'
require 'optionparser'
require_relative 'readconfig'



################################################################################

options = {}
optparse = OptionParser.new do |opts|
  opts.banner = 'Usage: crossscheduledeps.rb [options]'
  options[:databaseName] = nil
  opts.on('-d', '--databasename DB', 'mandatory; database name (prefix = \'opconxps_\')') do |dbname|
    options[:databaseName] = dbname
  end
  options[:fieldsep] = ' | '
  opts.on('-f ', '--fieldseparator F', 'optional; Fieldseparator, default is |') do |x|
    options[:fieldsep] = x
  end
  options[:schedulename] = nil
  opts.on('-s', '--schedule-name SN', 'Schedule-Name') do |schname|
    options[:schedulename] = schname
  end
  opts.on('-h', '--help', 'Display this screen') do
    puts 'Description: selects jobs with cross-schedule-dependencies'
    puts opts
    exit
  end
end
optparse.parse!

separator = "#{options[:fieldsep]}"

if options[:databaseName].nil?
  puts optparse
  exit 1
else
  DB = "#{options[:databaseName]}"
end

if options[:schedulename].nil?
  puts optparse
  exit 1
else
  schedulename = options[:schedulename]
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
#
# SQL
#
structuredQueryLanguage = "
    select a.skdname,jobname,depjobname,b.skdname from jdepjob
    join sname a on jdepjob.skdid = a.skdid join sname b on jdepjob.depskdid = b.skdid
    where a.skdname like '#{schedulename}'
    and jdepjob.skdid != jdepjob.depskdid
"
################################################################################

dbh = dbConnect
sth = dbh.execute(structuredQueryLanguage)

colCount = sth.column_names.size

colNames = ''
sth.column_names.each do |name|
  colNames.concat(name + separator)
end
puts colNames

while row = sth.fetch
  rowValues = ''
  (0..colCount - 1).each do |n|
    val = row[n]
    val = '<<NULL>>' if val.nil?
    rowValues.concat(val + separator)
  end
  puts rowValues
end
sth.finish

dbh.disconnect if dbh

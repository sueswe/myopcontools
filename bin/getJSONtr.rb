#!/usr/bin/env ruby

require 'dbi'
require 'colorize'
require 'optionparser'
require_relative 'readconfig'

myname = File.basename(__FILE__)

################################################################################

options = {}
optparse = OptionParser.new do |opts|
  opts.banner = 'Usage: properties [options]'
  options[:databaseName] = nil
  opts.on('-d', '--databasename DB', 'DB Name (SMAOpconDeploy)') do |x|
    options[:databaseName] = x
  end
  options[:rulename] = nil
  opts.on('-r', '--rule-name RN', 'Rule-Name') do |x|
    options[:rulename] = x
  end
  options[:list] = false
  opts.on('-l', '--list', 'List transformation rules') do
    options[:list] = true
  end
  opts.on('-h', '--help', 'Display this screen') do
    puts 'Description: Read transformation-rules from DEPLOY-DB in JSON format.'
    puts opts
    exit
  end
end
optparse.parse!

if options[:databaseName].nil?
  puts 'use -h for help.'.yellow
  exit 2
end

if options[:databaseName]
  DB = "#{options[:databaseName]}"
  # puts "Name of Database: " + DB.cyan
end

tr = if options[:rulename]
       "#{options[:rulename]}"
     # puts "Name of Schedule: " + sname.cyan
     else
       '%'
     end

def dbConnect
  include Read_config
  $usr = Read_config.get_deployuser
  $pwd = Read_config.get_deploypwd
  dbh = DBI.connect("DBI:ODBC:#{DB}", "#{$usr}", "#{$pwd}")
end

structuredQueryLanguage = "
  SELECT TOP 1 definition
  from deploy_transformation_rule
  where name = '#{tr}'
  ORDER BY version desc
"

listsql = "
  select ID,NAME,VERSION
  FROM deploy_transformation_rule
  where name like '#{tr}'
  ORDER BY version desc
"

dbh = dbConnect

# puts listsql.yellow

if options[:list] == true
  puts 'ID,   NAME,   VERSION'
  sth = dbh.execute(listsql)
else
  sth = dbh.execute(structuredQueryLanguage)
end
# colCount wird für die loop benötigt:
colCount = sth.column_names.size
# puts "ColCount:         " + colCount.to_s.red

# loop über die Spaltenamen:
colNames = ''
sth.column_names.each do |name|
  colNames.concat(name + ' | ')
end
# puts colNames.blue

while row = sth.fetch
  rowValues = ''
  # for i in (0 .. 9) do
  (0..colCount - 1).each do |n|
    val = row[n].to_s.gsub(/\r\n/, "\n")
    val = '<<NULL>>' if val.nil?
    if options[:list] == true
      rowValues.concat(val + ' | ')
    else
      rowValues.concat(val)
    end
  end
  puts rowValues
end
sth.finish

dbh.disconnect if dbh

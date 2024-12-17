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
  options[:schedulename] = nil
  opts.on('-s', '--schedule-name SN', 'Schedule-Name') do |x|
    options[:schedulename] = x
  end
  options[:list] = false
  opts.on('-l', '--list', 'List deploy-schedules') do
    options[:list] = true
  end
  opts.on('-h', '--help', 'Display this screen') do
    puts 'Description: Get Schedules from DEPLOY-DB in JSON format.'
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

sname = if options[:schedulename]
          "#{options[:schedulename]}"
        # puts "Name of Schedule: " + sname.cyan
        else
          '%'
        end

def dbConnect
  include Read_config
  $usr = Read_config.get_dbuser
  $pwd = Read_config.get_dbpwd
  dbh = DBI.connect("DBI:ODBC:#{DB}", "#{$usr}", "#{$pwd}")
end

structuredQueryLanguage = "
  SELECT TOP 1 definition
  from deploy_schedule
  where name = '#{sname}'
  ORDER BY version desc
"

listsql = "
  select ID,NAME,VERSION
  FROM deploy_schedule
  where name like '#{sname}'
  ORDER BY version desc
"

dbh = dbConnect

# puts listsql.yellow

sth = if options[:list] == true
        dbh.execute(listsql)
      else
        dbh.execute(structuredQueryLanguage)
      end
# colCount wird für die loop benötigt:
colCount = sth.column_names.size
# puts "ColCount:         " + colCount.to_s.red

# loop über die Spaltenamen:
colNames = ''
sth.column_names.each do |name|
  colNames.concat(name + ' | ')
end


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

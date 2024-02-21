#!/usr/bin/env ruby

# apt install ruby-dev, unixodbc, unixodbc-dev
# gem install dbi dbd-odbc ruby-odbc

require 'dbi'
require 'colorize'
require 'optionparser'

class Read_config
  require 'yaml'
  targetDir = ENV['HOME'] + '/bin/'
  $config = targetDir + 'opcon.yaml'

  def get_dbuser
    config = YAML.load_file($config)
    config['opconuser']
  end

  def get_dbpwd
    config = YAML.load_file($config)
    config['opconpassword']
  end
end

################################################################################
#
# SQL
#
structuredQueryLanguage = "
    select DISTINCT SKDNAME from SNAME
    JOIN SNAME_AUX ON SNAME.skdid = SNAME_AUX.skdid
    ORDER BY SKDNAME ASC;
    "

sql_mit_docu = "
  select DISTINCT SKDNAME,SAVALUE from SNAME
  JOIN SNAME_AUX ON SNAME.skdid = SNAME_AUX.skdid
  where SAFC = 0
  OR SAVALUE like '%deploy%'
  ORDER BY SKDNAME ASC;
"

autobuild = "
    select distinct SKDNAME from sname_aux
    join sname on sname_aux.skdid = sname.skdid
    and (safc = 105 or safc = 109)
"
#
#
################################################################################

options = {}
optparse = OptionParser.new do |opts|
  opts.banner = 'Usage: properties [options]'

  options[:fieldsep] = ' | '
  opts.on('-f', '--fieldseparator F', 'optional; Fieldseparator, default is |') do |x|
    options[:fieldsep] = x
  end

  options[:databaseName] = nil
  opts.on('-d', '--databasename DB', 'mandatory; database name (prefix = \'opconxps_\')') do |dbname|
    options[:databaseName] = dbname
  end

  options[:autobuild] = nil
  opts.on('-a', '--autoBuild', 'Autobuild Flag') do
    options[:autobuild] = true
  end

  options[:docu] = nil
  opts.on('-s', '--show-docu', 'Select Schedules with Documentationfield') do
    options[:docu] = true
  end

  opts.on('-h', '--help', 'Display this screen') do
    puts 'Description: selects schedules and autobuild-configuration.'
    puts opts
    exit
  end
end
optparse.parse!

separator = "#{options[:fieldsep]}"

if options[:databaseName].nil?
  # text = "use -h for Help."
  # puts text.cyan
  puts optparse
  exit 2
else
  DB = "#{options[:databaseName]}"
  puts 'Name of database: ' + DB.red
end

################################################################################
#
# Methoden
#
################################################################################
def dbConnect
  $usr = Read_config.new.get_dbuser
  $pwd = Read_config.new.get_dbpwd
  dbh = DBI.connect("DBI:ODBC:opconxps_#{DB}", "#{$usr}", "#{$pwd}")
end
################################################################################

dbh = dbConnect

sth = if !options[:autobuild].nil?
        dbh.execute(autobuild)
      elsif !options[:docu].nil?
        dbh.execute(sql_mit_docu)
      else
        dbh.execute(structuredQueryLanguage)
      end

colCount = sth.column_names.size
# puts "ColCount:         " + colCount.to_s.red

colNames = ''
sth.column_names.each do |name|
  colNames.concat(name + separator)
end
puts colNames.blue

while row = sth.fetch
  rowValues = ''
  # for i in (0 .. 9) do
  (0..colCount - 1).each do |n|
    val = row[n]
    val = '<<NULL>>' if val.nil?
    rowValues.concat(val + separator)
  end
  puts rowValues
end
sth.finish

dbh.disconnect if dbh

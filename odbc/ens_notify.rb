#!/usr/bin/env ruby

$sql = "
SELECT SUBSTRING(ACTIONMSG,0,150),GROUPNAME
FROM ENSMESSAGES
JOIN ENSGROUPS ON (ENSGROUPS.GROUPOFID = ENSMESSAGES.GROUPOFID)
--WHERE GROUPNAME LIKE '14%'
ORDER BY GROUPNAME ASC;
"

require 'dbi'
require 'colorize'
require 'optparse'


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
    puts 'Description: Show ENS_NOTIFICATION informations.'
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









def dbConnect
    $usr = Read_config.new.get_dbuser
    $pwd = Read_config.new.get_dbpwd
    dbh = DBI.connect("DBI:ODBC:opconxps_#{DB}", "#{$usr}", "#{$pwd}")
  end
  
################################################################################
  
dbh = dbConnect

sth = dbh.execute($sql)

colCount = sth.column_names.size
# puts "ColCount: " + colCount.to_s.cyan

colNames = ''
sth.column_names.each do |name|
    colNames.concat(name + ' | ')
end
# puts colNames

while row = sth.fetch
    rowValues = ''
    (0..colCount - 1).each do |n|
        val = row[n].to_s
        v = val.gsub('<MAILTO>','').gsub('<MAILCC>',',').gsub('</MAILTO>',',').gsub('</MAILCC>',',').gsub('<MAILBCC>',',').gsub('</MAILBCC>',',')
        w = v.gsub('<MAILSUBJ>',' ; TEXT = ')
        rowValues.concat(w + separator)
    end
    puts rowValues
end
sth.finish

dbh.disconnect if dbh
  
#!/usr/bin/env ruby

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

  options[:gruppe] = nil
  opts.on('-g', '--group GR', 'mandatory; Filter nach Gruppe ') do |g|
    options[:gruppe] = g
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
else
  DB = "#{options[:databaseName]}"
  # puts 'Name of Database: ' + DB
end

if options[:gruppe].nil?
  puts optparse
  exit 2
else
  gruppe = options[:gruppe].to_s
end



separator = "#{options[:fieldsep]}"
# puts "FIELDseparator: #{separator}"



$sql = "
--SELECT GROUPTYPE,GROUPNAME,SUBSTRING(ACTIONMSG,0,180)
SELECT GROUPTYPE,GROUPNAME,ACTIONMSG
FROM ENSMESSAGES
JOIN ENSGROUPS ON (ENSGROUPS.GROUPOFID = ENSMESSAGES.GROUPOFID)
WHERE GROUPNAME LIKE '%#{gruppe}%'
ORDER BY GROUPNAME ASC;
"





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
        puts '#' * 70 + "\n"
        rowValues.concat( w + separator)
    end
    puts rowValues
end
sth.finish

dbh.disconnect if dbh
  
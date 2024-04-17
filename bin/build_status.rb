#!/usr/bin/env ruby

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


def dbConnect
  $usr = Read_config.new.get_dbuser
  $pwd = Read_config.new.get_dbpwd
  dbh = DBI.connect("DBI:ODBC:opconxps_#{DB}", "#{$usr}", "#{$pwd}")
end


def run_the_statement
  dbh = dbConnect
  sth = dbh.execute($sql)
  colCount = sth.column_names.size
  # puts "(ColCount: " + colCount.to_s.cyan + ")"

  colNames = ''
  sth.column_names.each do |name|
    colNames.concat(name + $separator)
  end
  # puts colNames

  while row = sth.fetch
    rowValues = ''
    (0..colCount - 1).each do |n|
      # val = row[n].to_s.yellow
      val = row[n].to_s
      rowValues.concat(val + $separator)
    end
    puts rowValues
  end
  sth.finish

  dbh.disconnect if dbh
  puts "finished. Disconnected".green
end

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
  opts.on('-s', '--schedule-name SN', 'Schedule-Name') do |schname|
    options[:schedulename] = schname
  end

  options[:buildstate] = nil
  opts.on('-b', '--buildstate b', 'BuildState(num)') do |b|
    options[:buildstate] = b
  end
  
  #options[:showbuildtstates] = nil
  #opts.on('-l','--list-states','Show build states from JSTATMAP') do
  #  options[:showbuildtstates] = true
  #end

  opts.on('-h', '--help', 'Display this screen') do
    puts 'Description: find jobstates and frequencies in JOBMASTER.'
    puts opts
    puts ""
    puts "    
    0 = On Hold
    99 = Release
    -1 = Do not schedule
    160 = Build skipped
    -99 = Disabled frequency
    [see table dbo.JSTATMAP]
    "
    exit
  end

end
optparse.parse!


$separator = "#{options[:fieldsep]}"

if options[:databaseName].nil?
  puts "Use -h for help.".red
  puts optparse
  exit 2
else
  DB = "#{options[:databaseName]}"
  # puts "Name of Database: ".rjust(20) + DB.red
end


if options[:showbuildtstates].nil?
  puts ""
else
  $sql = 'select * from dbo.JSTATMAP'
  puts $sql.yellow
  run_the_statement
  exit 0
end

SCHEDULENAME = 
if options[:schedulename].nil?
  puts optparse
  exit 1
else
  options[:schedulename]
end
puts "Schedule = #{SCHEDULENAME}"

BUILD_STATE = 
if options[:buildstate].nil?
  puts optparse
  exit 1
else
  options[:buildstate]
end
puts "buildState = #{BUILD_STATE}"

$sql = "
SELECT
  SKDNAME,JOBNAME,FREQNAME,STSTATUS
FROM [dbo].[JSKD]
JOIN SNAME ON (jskd.SKDID = SNAME.SKDID)
--where JAVALUE = '3'
--WHERE JOBNAME LIKE '%bciabrem13%'
--where JAVALUE like '%bciabrem13%'
--AND (JAFC LIKE '6001' OR JAFC LIKE '6002')
WHERE SKDNAME LIKE '#{SCHEDULENAME}'
AND STSTATUS = '#{BUILD_STATE}'
ORDER BY SKDNAME
"

run_the_statement


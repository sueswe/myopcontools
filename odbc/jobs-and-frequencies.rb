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
  options[:schedule] = nil
  opts.on('-s', '--schedule SCHEDULENAME', 'Schedule Name') do |sn|
    options[:schedule] = sn
  end
  options[:buildstate] = false
  opts.on('-b', '--buildstatus', 'List Build Status') do 
    options[:buildstate] = true
  end
  opts.on('-h', '--help', 'Display this screen') do
    puts 'Description: selects MASTER-Job - configurations and frequencies.'
    puts 'WARNING: selects no OR frequencies.'.red
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
end

if options[:databaseName]
  DB = "#{options[:databaseName]}"
  # puts 'Name of Database: ' + DB.red
end

if options[:schedule]
  schedulename = "#{options[:schedule]}"
  # puts 'Name of schedule: ' + schedulename.red
end

# puts 'WARNING: selects no OR frequencies.'.red

#
# Methods
#

def dbConnect
  $usr = Read_config.new.get_dbuser
  $pwd = Read_config.new.get_dbpwd
  dbh = DBI.connect("DBI:ODBC:opconxps_#{DB}", "#{$usr}", "#{$pwd}")
end
################################################################################
#
# SQL
#

buildStatusSql = "
SELECT SKDNAME, JOBNAME, FREQNAME,STSTATUS
FROM [dbo].[JSKD]
JOIN SNAME ON (jskd.SKDID = SNAME.SKDID)
--where JAVALUE = '3'
--WHERE JOBNAME LIKE '%bciabrem13%'
--where JAVALUE like '%bciabrem13%'
--AND (JAFC LIKE '6001' OR JAFC LIKE '6002')
--WHERE STSTATUS = '160'
AND SKDNAME LIKE '#{schedulename}'
--    OR SKDNAME like '11-PKV')
ORDER BY SKDNAME
"

structuredQueryLanguage = "
SELECT distinct skdname,jobname,freqname,
(
SELECT javalue
from jmaster_aux ja
JOIN sname sa ON ja.skdid = sa.skdid
where ja.jafc = 6001
and sa.skdname = s.skdname
and ja.jobname = j.jobname
),
(
SELECT javalue
from jmaster_aux ja2
JOIN sname sa2 ON ja2.skdid = sa2.skdid
where ja2.jafc = 6002
and sa2.skdname = s.skdname
and ja2.jobname = j.jobname
)
FROM jskd j
JOIN sname s ON j.skdid = s.skdid
WHERE s.skdname like '#{schedulename}'
--and j.freqname not like 'OR%'
"
#
#
################################################################################

################################################################################

dbh = dbConnect

if options[:buildstate]
  puts "selecting buildstates"
  sth = dbh.execute(buildStatusSql)
else
  sth = dbh.execute(structuredQueryLanguage)
end

colCount = sth.column_names.size
#puts 'ColCount:         ' + colCount.to_s.red

colNames = ''
sth.column_names.each do |name|
  colNames.concat(name + separator)
end
puts colNames

while row = sth.fetch
  rowValues = ''
  # for i in (0 .. 9) do
  (0..colCount - 1).each do |n|
    if options[:buildstate]
      # 0 = On Hold
      # 99 = Release
      # -1 = Do not schedule
      # 160 = Build skipped
      # -99 = Disabled frequency
      schedule = row[0].to_s
      job = row[1].to_s
      frequname = row[2].to_s.rstrip
      build = row[3].to_i
      
      case build 
      when -1 
        state = 'Do Not Schedule'
      when 0 
        state = 'On Hold'
      when 99 
        state = 'Release'
      when 160 
        state = 'Build Skipped'
      when -99 
        state = 'Disabled Frequency'
      end
      
      rowValues = schedule + separator + job + separator + frequname + separator + state
    else
      val = row[n]
      val = '<<NULL>>' if val.nil?
      rowValues.concat(val + separator)
    end
    
  end
  puts rowValues
end
sth.finish

dbh.disconnect if dbh

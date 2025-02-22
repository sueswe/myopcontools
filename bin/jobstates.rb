#!/usr/bin/env ruby

# apt install ruby-dev, unixodbc, unixodbc-dev
# gem install dbi dbd-odbc ruby-odbc

require 'dbi'
require 'colorize'
require 'optionparser'
require_relative 'readconfig'

$stdout.sync = true



myname = File.basename(__FILE__)

options = {}
optparse = OptionParser.new do |opts|
  opts.banner = "Usage: #{myname} [options]"
  options[:fieldsep] = ' | '
  opts.on('-f', '--fieldseparator F', 'optional; Fieldseparator, default is |') do |x|
    options[:fieldsep] = x
  end
  options[:databaseName] = nil
  opts.on('-d', '--databasename DB', 'mandatory; Database-name (prefix = \'opconxps_\')') do |dbname|
    options[:databaseName] = dbname
  end

  options[:scheduledate] = nil
  opts.on('-i', '--imerominia SD', 'optional; Schedule-Date (format : yyyy-mm-dd) '.yellow) do |schdate|
    options[:scheduledate] = schdate
  end

  options[:schedulename] = nil
  opts.on('-s', '--schedule SN', 'mandatory; Schedule-Name') do |schname|
    options[:schedulename] = schname
  end

  opts.on('-h', '--help', 'Display this screen') do
    puts 'Description: selects current job-state (dependend on schedule-date and schedule).'
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
  puts 'Missing DB name. Use -h for help.'.cyan
  puts optparse
  exit 2
end
# if options[:scheduledate] == nil
#    puts "Missing schedule-date. Use -h for help.".cyan
#    puts optparse
#    exit 2
# end
if options[:schedulename].nil?
  puts 'Missing schedule-name. Use -h for help.'.cyan
  puts optparse
  exit 2
end

if options[:databaseName]
  DB = "#{options[:databaseName]}"
  puts 'Name of database: '.rjust(20) + DB.red
end
if options[:scheduledate]
  sdate = "#{options[:scheduledate]}"
  puts 'Scheduledate: '.rjust(20) + sdate.red
end
if options[:schedulename]
  sname = "#{options[:schedulename]}"
  puts 'Schedulename: '.rjust(20) + sname.red
end

################################################################################
#
# SQL
#
sql_withoutdate = "
    select
    --CONVERT(smalldatetime,STARTSTAMP - 2),
    CONVERT(smalldatetime,SKDDATE -2)  as SDATE,SKDNAME,JOBNAME,STSTATUS,JOBSTATUS
    from SMASTER
    JOIN SNAME ON (SMASTER.SKDID = SNAME.SKDID)
    where SKDNAME like '%#{sname}%'
    --and CONVERT(smalldatetime,SKDDATE - 2) = (?)
    --and JOBSTATUS != '900'
    ORDER BY JOBSTATUS ASC
"
sql = "
    select
    --CONVERT(smalldatetime,STARTSTAMP - 2),
    CONVERT(smalldatetime,SKDDATE -2)  as SDATE,SKDNAME,JOBNAME,STSTATUS,JOBSTATUS
    from SMASTER
    JOIN SNAME ON (SMASTER.SKDID = SNAME.SKDID)
    where SKDNAME like '%#{sname}%'
    and CONVERT(smalldatetime,SKDDATE - 2) = (?)
    --and JOBSTATUS != '900'
    ORDER BY JOBSTATUS ASC
"
################################################################################


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

sth = if options[:scheduledate].nil?
        dbh.execute(sql_withoutdate)
      else
        dbh.execute(sql, sdate)
      end

colCount = sth.column_names.size
puts 'ColCount: '.rjust(20) + colCount.to_s.red

colNames = ''
sth.column_names.each do |name|
  colNames.concat(name + separator)
end
puts colNames.blue

while row = sth.fetch
  rowValues = ''

  (0..colCount - 1).each do |_n|
    ststatus = row[3].to_i
    jobstatus = row[4].to_i
    date = row[0].to_s
    sch = row[1].to_s
    job = row[2].to_s
    # val = row[n].to_s
    date.sub!('T00:00:00+00:00', '')
    # puts "#{ststatus} und #{jobstatus}"
    derStatus = "#{jobstatus} - #{ststatus}"

    if ststatus == 900
      case jobstatus
      when 100
        mapped_status = 'Attempt to Start'
      when 200
        mapped_status = 'Start Attempted'
      when 205
        mapped_status = 'Still Attempting Start'
      when 210
        mapped_status = 'Initialization Error'
      when 300
        mapped_status = 'Prerun Active'
      when 350
        mapped_status = 'Prerun Failed'
      when 500
        mapped_status = 'Job Running'
      when 510
        mapped_status = 'Job Running; Late to Finish'
      when 550
        mapped_status = 'Job Running; To be terminated'
      when 820
        mapped_status = 'Finished OK; Processing Events'
      when 821
        mapped_status = 'Failed; Processing Events'
      when 830
        mapped_status = 'Marked Finished OK; Processing Events'
      when 831
        mapped_status = 'Marked Failed; Processing Events'
      when 840
        mapped_status = 'Skipped; Processing Events'
      when 842
        mapped_status = 'Under Review; Processing Events'
      when 843
        mapped_status = 'Fixed; Processing Events'
      when 900
        mapped_status = 'Finished OK'
      when 910
        mapped_status = 'Failed'
      when 920
        mapped_status = 'Marked Finished OK'
      when 921
        mapped_status = 'Marked Failed'
      when 940
        mapped_status = 'Skipped'
      when 942
        mapped_status = 'Under Review'
      when 943
        mapped_status = 'Fixed'
      when 950
        mapped_status = 'Cancelled'
      when 960
        mapped_status = 'Missed Start Time'
      end
    elsif ststatus == 901
      case jobstatus
      when 0
        mapped_status = 'Wait to Start; Forced'
      end
    elsif jobstatus == 0
      case ststatus
      when 0
        mapped_status = 'On Hold'
      when 90
        mapped_status = 'Under Construction'
      when 99
        mapped_status = 'Qualifying'
      when 100
        mapped_status = 'Released'
      when 110
        mapped_status = 'Wait Start Time'
      when 120
        mapped_status = 'Wait Job Dependency'
      when 125
        mapped_status = 'Wait Expression Dependency'
      when 130
        mapped_status = 'Wait Threshold/Resource Dependency'
      when 140
        mapped_status = 'Wait Machine'
      when 150
        mapped_status = 'Wait Job Conflict'
      when 160
        mapped_status = 'Job to be Skipped'
      when 170
        mapped_status = 'Late to Start'
      end
    end

    rowValues = "#{date} #{separator} #{sch} #{separator} #{job} #{separator} #{mapped_status}"
  end
  puts rowValues
end
sth.finish

dbh.disconnect if dbh

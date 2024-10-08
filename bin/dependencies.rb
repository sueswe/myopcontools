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

myname = File.basename(__FILE__)


options = {}
optparse = OptionParser.new do |opts|
  opts.banner = "Usage: #{myname} [options]"

  options[:fieldsep] = ' | '
  opts.on('-f ', '--fieldseparator F', 'optional; Fieldseparator, default is |') do |x|
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
  opts.on('-h', '--help', 'Display this screen') do
    puts 'Description: prints jobs and dependecies with frequency'
    puts opts
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

SCHEDULENAME = if options[:schedulename].nil?
                 '%'
               else
                 options[:schedulename]
               end


#####################################################################
# SQL
#####################################################################
sql = "
select 	jobname,
		    depjobname,
		    replace(replace(replace(deptype,'131','Weiter'),'3','Stop'),'1','Benoetigt') as 'DepType',
		    b.skdname from jdepjob
join sname a on jdepjob.skdid = a.skdid join sname b on jdepjob.depskdid = b.skdid
where a.skdname LIKE '#{SCHEDULENAME}'
"


################################################################################
def dbConnect
  $usr = Read_config.new.get_dbuser
  $pwd = Read_config.new.get_dbpwd
  dbh = DBI.connect("DBI:ODBC:opconxps_#{DB}", "#{$usr}", "#{$pwd}")
end
################################################################################

dbh = dbConnect

sth = dbh.execute(sql)

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
    val = row[n].to_s.rstrip
    rowValues.concat(val + separator)
  end
  puts rowValues
end
sth.finish

dbh.disconnect if dbh

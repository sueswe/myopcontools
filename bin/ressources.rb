#!/usr/bin/env ruby

require 'dbi'
require 'optionparser'
require 'colorize'



myname = File.basename(__FILE__)
options = {}
optparse = OptionParser.new do |opts|
  opts.banner = "Usage: #{myname} [options]"

  options[:fieldsep] = ' | '
  opts.on('-f', '--fieldseparator F', 'optional; Fieldseparator, default is |') do |x|
    options[:fieldsep] = x
  end
  options[:databasename] = nil
  opts.on('-d', '--databasename STR', 'mandatory; database name (prefix = \'opconxps_\')') do |dbname|
    options[:databasename] = dbname
  end
  options[:sname] = nil
  opts.on('-s', '--schedulename STR', 'schedule name (optional)') do |sn|
    options[:sname] = sn
  end
  options[:jobname] = nil
  opts.on('-j', '--jobname STR', 'job name (optional)') do |jn|
    options[:jobname] = jn
  end
  options[:resname] = nil
  opts.on('-r', '--ressource STR', 'Ressource Name (optional)') do |es|
    options[:resname] = es
  end
  opts.on('-h', '--help', 'Display this screen') do
    puts 'Description: selects resources, jobs and values.'
    puts opts
    # puts String.colors
    # puts String.modes
    # puts String.color_samples
    puts 'Schedulename | Jobname | Used Ressources | Ressource-name |'.yellow
    exit
  end
end
optparse.parse!

separator = "#{options[:fieldsep]}"

if options[:databasename]

  # Ruby Constants
  # https://www.tutorialspoint.com/ruby/ruby_variables.htm
  # Constants begin with an uppercase letter. Constants defined within a
  # class or module can be accessed from within that class or module,
  # and those defined outside a class or module can be accessed globally.
  # (Für den connect wird eine Methode dbConnect verwendet weiter unten)

  # global var :
  $dataBaseShortname = "#{options[:databasename]}"

  if options[:sname]
    schedule = options[:sname].to_s
  else
    puts "(no Schedulename given. It's okay.)"
  end
  if options[:jobname]
    jobname = "#{options[:jobname]}"
  else
    puts "(no jobname given. It's okay.)"
  end
  if options[:resname]
    ressource = "#{options[:resname]}"
  else
    puts "(no ressource name given. It's okay.)"
  end
else
  puts "Sorry, missing DATABASE-Name-Option.\nUse '#{myname} -h' for help.".red
  puts optparse
  exit 1
end


puts "dataBaseShortname = #{$dataBaseShortname}".green
puts "Jobname = #{jobname}".green
puts "Schedule = #{schedule}".green
puts "Ressourcestring = #{ressource}".green
# exit

###############################################################################
sql = "
SELECT SKDNAME,JOBNAME,THRESHUSED,THRESH.THRESHDESC
FROM JDEPTHR
JOIN THRESH ON (JDEPTHR.DEPTHRID = THRESH.THRESHID)
JOIN SNAME ON (JDEPTHR.SKDID=SNAME.SKDID)
WHERE jobname LIKE '%#{jobname}%'
AND THRESHDESC LIKE '%#{ressource}%'
and SKDNAME LIKE '%#{schedule}%'
ORDER BY THRESHDESC
"
###############################################################################

################################################################################
#
# Methods
#
################################################################################
def dbConnect
  $usr = Read_config.get_dbuser
  $pwd = Read_config.get_dbpwd
  dbh = DBI.connect("DBI:ODBC:opconxps_#{$dataBaseShortname}", "#{$usr}", "#{$pwd}")
end
################################################################################


dbh = dbConnect

sth = dbh.execute(sql)

colCount = sth.column_names.size

colNames = ''
sth.column_names.each do |name|
  colNames.concat(name + separator)
end

while row = sth.fetch
  rowValues = ''

  (0..colCount - 1).each do |n|
    val = row[n].to_s

    rowValues.concat(val + separator)
  end
  puts rowValues
end
sth.finish

dbh.disconnect if dbh

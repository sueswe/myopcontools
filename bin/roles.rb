#!/usr/bin/env ruby

query = "
  select rolename, usersignon,
  (
  SELECT u.uavalue as 'Email'
  FROM USERS_AUX u
  WHERE u.uafc = 107
  AND u.userid = USERS_AUX.userid
  )
  from USERS_AUX
  join users on USERS_AUX.userid = users.userid
  join roles ON USERS_AUX.UAFC = 128 and USERS_AUX.uavalue = roles.roleid
  ORDER BY rolename
;
"


query_only_roles = "
select usersignon,uavalue,uafc from users_aux
join users on users_aux.userid = users.userid
--where UAFC = 128
where UAFC = 106 OR UAFC = 128

;
"

require 'dbi'
require 'colorize'
require 'optionparser'
require_relative 'readconfig'


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
  options[:rolesonly] = nil
  opts.on('-r', '--roles-only', 'gimme just the roles, even empty ones.') do
    options[:rolesonly] = true
  end
  opts.on('-h', '--help', 'Display this screen') do
    puts 'Description: selects roles, users and their email-address.'
    puts opts
    exit
  end
end
optparse.parse!
separator = "#{options[:fieldsep]}"
if options[:databaseName].nil?
  puts 'Missing DB name. Use -h for help.'.cyan
  puts optparse
  exit 2
else
  DB = "#{options[:databaseName]}"
  # puts "Name of database: " + DB
end



def dbConnect
  include Read_config
  $usr = Read_config.get_dbuser
  $pwd = Read_config.get_dbpwd
  dbh = DBI.connect("DBI:ODBC:opconxps_#{DB}", "#{$usr}", "#{$pwd}")
end

################################################################################

dbh = dbConnect

sth = if options[:rolesonly]
        dbh.execute(query_only_roles)
      else
        dbh.execute(query)
      end

colCount = sth.column_names.size

# colNames = ''
# sth.column_names.each do |name|
#    colNames.concat(name + " | ")
# end
# puts colNames.blue

while row = sth.fetch
  rowValues = ''
  (0..colCount - 1).each do |n|
    val = row[n]
    val = '(keine Emailadresse vergeben)' if val.nil?
    val = val.rstrip.ljust(22)
    rowValues.concat(val + separator)
    # rowValues.concat(val)
  end
  puts rowValues
end
sth.finish

dbh.disconnect if dbh

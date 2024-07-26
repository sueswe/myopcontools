# Opcon Ruby Tools for the CLI


> get informations from your SMA OPCON job-control-database.


## Description

This set of ruby-scripts tries to select usefull informations from an OPCON-database.
The idea: use the **great advantage** of the CLI - you could use grep and other tools to parse the results
for your needs; use the output for Markdown- or Latex-Files; send results via Email ...
and much more.


* There are following tools currently available:

| Name | a very short description |
| :--- | :--- |
|audit.rb |       Search the AUDIT-table.|
|batchuser.rb |       selects the batch-user.|
|build_status.rb |       find jobstates and frequencies in JOBMASTER.|
|calendar.rb |       selects data from calenders.|
|crossscheduledeps.rb |       selects jobs with cross-schedule-dependencies'|
|departements.rb |       selects MASTER-Jobs with departement.|
|dependencies.rb |       prints jobs and dependecies with frequency'|
|disabled-frequencies.rb |       lookup jobs with a disabled frequency.|
|diskfree.rb |       Get a list of databases file with size and free space for a database in SQL Server.|
|donotschedule-frequs.rb |       lookup jobs with a frequency set to "Do Not Schedule".|
|events.rb |       selects EVENTS with Jobname, Eventstring and Schedulename.|
|frequencies.rb |       selects all Frequencies, including Frequency-Code and After/On/Before/NotSchedule-configuration.|
|getJSONschedule.rb |       Get Schedules from DEPLOY-DB in JSON format.|
|getJSONtr.rb |       Read transformation-rules from DEPLOY-DB in JSON format.|
|history.rb |       enables the possibility to search the HISTORY-table.|
|jobdetailmaster.rb |       selects MASTER-Jobs - configurations.|
|jobdocu.rb |       selects Job-documentation from the MASTER-Jobs.|
|jobs-and-frequencies.rb |       selects MASTER-Job - configurations and frequencies.|
|jobs-and-machgrp.rb |       show MASTER-Job-configurations in context with machine groups.|
|jobs-on-which-machine.rb |       selects jobnames and machine-groups or machines.|
|jobstates.rb |       selects current job-state (dependend on schedule-date and schedule).|
|lsam.rb |       selects agents, OS, ports, and connect-status.|
|machgrp.rb |       selects machinegroups and machines.|
|opcusersignon.rb |       selects user, login-time and client-version.|
|openschedules.rb |       selects open schedules (not in state completed).|
|properties.rb |       selects properties and values.|
|ressources.rb |       selects resources, jobs and values.|
|roles.rb |       selects roles, included users and their email-adress.|
|schedules.rb |       selects schedules and autobuild-configuration.|
|starttimes.rb |       selects jobs with starttimes (only when start-offset not 0).|



## Prerequisites

* First, you need a read-only-database-user for accessing the opcon-database. The rake-installer will ask you later for username and password.

Now you can prepare your local installation:

For example, on apt-based Linux systems (but it also works with Windows 10, see note below):

```sh
$ sudo apt install ruby-dev unixodbc unixodbc-dev ruby-bundler
```

Then you may configure your user-account , e.g. your .bashrc , with:

```sh
export GEM_HOME="${HOME}/.gem"
export GEM_PATH="${HOME}/.gem"
export PATH="${PATH}:${HOME}/bin:${GEM_PATH}/bin"
```

Don't forget to source your .bashrc again.


Now, run bundle, to select the right versions of the gems:

~~~
$ bundle
~~~



* **NOTE:** If you like to use the toolset under Windows 10, you have to choose an installer with *DEV*-Kit from https://rubyinstaller.org/downloads/



## Linux: install the ODBC-connections

Please refer to:

https://docs.microsoft.com/en-us/sql/connect/odbc/linux-mac/installing-the-microsoft-odbc-driver-for-sql-server?view=sql-server-ver15

After installing the driver, you need to create a $HOME/.odbc.ini:

~~~
[MSSQLTest]  
Driver = ODBC Driver 18 for SQL Server  
# Server = [protocol:]server[,port]  
Server = tcp:localhost,1433
Database = name_of_DB
TrustServerCertificate = yes
Encrypt = yes
~~~

## Installing the tools to ${HOME}/bin

To install the toolset, run

~~~
$ rake
~~~

You will now be asked for the database-user and password.


### How do I have to name my ODBC-connections?

In the code, I currently use a prefix for the database-name:

```ruby
def dbConnect
  $usr = Read_config.new.get_dbuser
  $pwd = Read_config.new.get_dbpwd
  dbh = DBI.connect("DBI:ODBC:opconxps_#{DB}","#{$usr}","#{$pwd}")
end

```

So the prefix is: *opconxps_*

We use three database-stages (production, testing and developement), so we called
our databases opconxps_prod, opconxps_test and opconxps_dev.
If we want to make a select to the production-database, we only need
the shortname for the parameter like:

```sh
$ jobonwhichmachine.rb -d prod -j %somejobname%

```

(the % is the wildcard for the select-statement in the code.)


## Usage

Every script contains a short help by calling it with option '-h' .

For example:

~~~
$ jobstates.rb -h

 selects current job-state (dependend on schedule-date and schedule).
Usage: jobstates.rb [options]
        --databasename DB            Database-Name
    -d, --date SD                    Schedule-Date
    -s, --schedule SN                Schedule-Name
    -h, --help                       Display this screen
~~~



# ODBC Opcon Tools Linux

### Installation

* Base

 - /opt/microsoft/msodbcsql17/lib64/libmsodbcsql-18.1.so 

~~~
sudo su
curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -

#Download appropriate package for the OS version
#Choose only ONE of the following, corresponding to your OS version

#Debian 9
curl https://packages.microsoft.com/config/debian/9/prod.list > /etc/apt/sources.list.d/mssql-release.list

#Debian 10
curl https://packages.microsoft.com/config/debian/10/prod.list > /etc/apt/sources.list.d/mssql-release.list

#Debian 11
curl https://packages.microsoft.com/config/debian/11/prod.list > /etc/apt/sources.list.d/mssql-release.list

exit
sudo apt-get update
sudo ACCEPT_EULA=Y apt-get install -y msodbcsql18
# optional: for bcp and sqlcmd
sudo ACCEPT_EULA=Y apt-get install -y mssql-tools18
echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> ~/.bashrc
source ~/.bashrc
# optional: for unixODBC development headers
sudo apt-get install -y unixodbc-dev
# optional: kerberos library for debian-slim distributions
sudo apt-get install -y libgssapi-krb5-2
~~~


 - apt install ruby-dev, unixodbc, unixodbc-dev
 - gem install dbi dbd-odbc ruby-odbc

* Module installieren

    #> bundle install





## Support

If you need help, feel free to write an issue.

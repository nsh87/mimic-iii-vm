# MIMIC-III VM

This repo creates a virtual machine running PostgreSQL and loads the
MIMIC-III data into a database on the VM. The MIMIC-III data will be
accessible from your host machine by querying the PostgreSQL server on
the VM. Hosting the MIMIC-III data in a VM can be desirable because this
prevents collisions with data on your own computer, and the VM can easily be
destroyed to reclaim disk space once experimentation with the data is complete.
 
## Requirements
You will need to have [Vagrant][1] and [VirtualBox][2] installed. It is
recommended to update to the latest versions if they are already installed.

The installation instructions also make use of Python's [pip][3] and Python
virtual environments using [virtualenv][4] and [virtualenvwrapper][5].

### Windows Users
Ansible is used to provision the Vagrant VM, and since Windows machines
<strike>cannot currently</strike> can be Ansible controllers [with some
work][6] this <strike>will not</strike> should also work on Windows. A Unix
machine (e.g. Linux, Mac OS X) is preferred since Ansible will be automatically
installed into a virtualenv later and will work out of the box on Unix machines.

### Ubuntu Users

On Ubuntu, if you are using the standard Terminal you can quickly get all
your requirements and set up virtualenvwrapper with:

```bash
sudo apt-get update
sudo apt-get install python-pip python-dev build-essential virtualenv virtualenvwrapper vagrant virtualbox
sudo apt-get install --upgrade pip
# Set up virtualenvwrapper
printf '\n%s\n%s\n%s' '# virtualenv' 'export WORKON_HOME=~/virtualenvs' \
'source /usr/local/bin/virtualenvwrapper.sh' >> ~/.bashrc
source ~/.bashrc
mkdir -p $WORKON_HOME
```

[1]: (https://www.vagrantup.com/downloads.html)
[2]: (https://www.virtualbox.org/wiki/Downloads)
[3]: (https://pip.pypa.io/en/stable/installing/)
[4]: (http://docs.python-guide.org/en/latest/dev/virtualenvs/)
[5]: (http://virtualenvwrapper.readthedocs.org/en/latest/install.html)
[6]: (http://www.azavea.com/blogs/labs/2014/10/running-vagrant-with-ansible-provisioning-on-windows/)

System Requirements: 3GB RAM and 90GB Free HD Space.

## VM Provisioning (a.k.a. Installation)
Clone the repo and create a virtualenv using the supplied `requirements.txt`. 
If using virtualenvwrapper, while in the repository's directory you can simply
execute:
 
```bash
mkvirtualenv mimic-iii-vm -a `pwd` -r requirements.txt
```

Then run `vagrant up` to boot the VM and run the Ansible provisioner. You
will be prompted for your PhysioNet username and password so the database
files can be downloaded to the VM as part of provisioning (this could
take a while, depending on your internet connection). The entire dataset
will be loaded into the database. A couple things to note:

1. There is an issue with non-private prompts for the Ansible provisioner
on Vagrant, so all prompts are private and will conceal what you type.
2. Downloading and loading these records will take several hours, but once you
input your username and password the entire process is automated.

You can easily delete the VM and reclaim your disk space with `vagrant halt`
(to stop the VM) and then `vagrant destroy` (to remove it).

If at any point provisioning is interrupted, you can re-provision the VM with
`vagrant --provision` or `vagrant reload --provision`. This will continue
downloads from where they left off, but all data will be erased and reloaded
into Postgres.

Log files will be created throughout the provisioning process. If you would
like to monitor these logs, they will be located in the folder for this repo
(on your host machine).

## Connecting to the Database
While the VM is booted, local port 2345 is forwarded to the guest VM port
5432 (Postgres server's default listening port). Therefore, generally
speaking you can connect using the host _localhost_ and port 2345.

There are two user accounts that have access to the database:

1. User `vagrant` with password `igMDi9RVEqaGMoi2` has read _and_ write access
2. User `mimic` with password `oNuemmLeix9Yex7W` has read-only access

You can change these passwords by editing the file _provisioning/mimic.yml_
prior to installation.

### GUI
A good GUI is pgAdmin3. It's included in the Windows PostgreSQL
installer, but might not be included for Mac or Linux installers. It is
available on Mac, Windows, and Linux. You can find non-bundled pgAdmin3
installers for Windows, OS X, and several flavors of Linux after selecting
a release version [here](http://www.postgresql.org/ftp/pgadmin3/release/).

Once installed, the settings for connecting to the database are:

  * Host: localhost
  * Port: 2345
  * Maintenance DB: mimic
  * Username: `mimic` for read-only access (or `vagrant` if you
    need write access)
  * Password: `igMDi9RVEqaGMoi2` for user `vagrant`, or `oNuemmLeix9Yex7W` for
    user `mimic`

You will find the data tables under the `mimiciii` schema.

### psql (command line)
The Postgres client is accessed through the command line with `psql`. The
command line bin is included with the OS-specific installers above, but
has probably not been added to your `PATH`. If it works after running the
installer, you're fine, otherwise:

  * OS X: Add the bin to your path, or instead you can install Postgres via
    Homebrew and download pgAdmin3 separately using the link above
    (recommended).

    ```bash
    brew install postgres
    initdb /usr/local/var/postgres -E utf8
    ```

  * Windows: Either move `psql.exe` to your current path or specify the full
    path to it, which is something like

    ```bash
    "%PROGRAMFILES%\Postgresql\9.2\bin\psql.exe"
    ```

You can then connect with `psql -h localhost -p 2345 mimiciii mimic`. You
will be prompted to enter the password for user `mimic` (see above for
password).

Below are some commands you can run in the *psql* client:

#### List the tables
You can list the tables, which are within the `mimiciii` schema with

```psql
\dt mimiciii*
```

#### Describe the table `admissions`, including its size on disk

```psql
\dt+ mimiciii.admissions
```

#### Show its columns and some basic info about them 

```psql
\d+ mimiciii.admissions
```

#### Show the first 10 rows

```psql
SELECT * FROM mimiciii.admissions LIMIT 10;
```

#### The Postgres search path looks in the `mimiciii` schema first by default

```psql
SELECT * FROM admissions LIMIT 10;
```

Above, `*` can also be replaced with a single column name.

#### -- DANGER COMMANDS --

You can "reset" your database by deleting the schema:

```bash
drop schema mimiciii cascade;  # drop all tables in the schema. you need
                               # to have read/write access to do so.
```

If you just deleted your data and want to reload it, execute
`vagrant provision` to run the Ansible playbook again.

### Psycopg2 (Python client)
One way to connect to the DB is through Psycopg2, a popular PostgreSQL client
for Python. It is included in `requirements.txt` for this repo.

```python
import psycopg2
conn=psycopg2.connect(
    dbname='mimic',
    user='mimic',
    host='localhost',
    port=2345,
    password='oNuemmLeix9Yex7W'
)
```

Then, to execute queries:

```python
# open a cursor to perform operations
cur = conn.cursor() 

# query the 'admissions' table
cur.execute("SELECT * FROM mimiciii.admissions LIMIT 10;")
colnames = [desc[0] for desc in cur.description]
print colnames
# put results in a list var to print the subject_id
row = cur.fetchall() 
for row in rows:
  print "    ", row[1]
```

You can read this
[quick guide](https://wiki.postgresql.org/wiki/Psycopg2_Tutorial) for the
client and access the [documentation](http://initd.org/psycopg/docs/) for more
information.

## A Word on Remote Connections
PostgreSQL connections are *not encrypted*. If you are going to run this on a
remote server, or connect to your VM over a network, you should encrypt your
connection when accessing the database. One way of doing this is by creating an
SSH tunnel to the VM:

```bash
ssh -L 63333:localhost:5432 vagrant@192.168.34.44
# this will open an SSH connection in your terminal which you should leave open.
# if you're prompted for a password, try 'vagrant'.
```

Here, `192.168.34.44` is the IP address of your VM. Once the SSH tunnel is
created, use local port `63333` to connect to the DB - this port is now
forwarded to the remote port 5432 over SSH. For example, with pgAdmin3
connecting over the SSH tunnel would use settings:

  * Host: localhost
  * Port: 63333
  * Maintenance DB: mimic
  * Username: `mimic` for read-only access (or `vagrant` if you
    need write access)
  * Password: `igMDi9RVEqaGMoi2` for user `vagrant`, or `oNuemmLeix9Yex7W` for
    user `mimic`

Or, with psql:

```bash
psql -h localhost -p 63333 mimic mimic 
```

## Shutting Down and Rebooting the VM
You can shut down the VM with `vagrant halt`. To boot it up again, `cd`
into the repository's directory and execute `vagrant up`. The data will
remain in the VM and once the VM is finished booting you can make
connections to the DB as before.

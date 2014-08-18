#! /bin/sh

echo "Install Java"
sudo yum install -y java-1.7.0-openjdk-devel

echo "Add Cloudera repositories"
wget -c http://archive.cloudera.com/cdh5/one-click-install/redhat/6/x86_64/cloudera-cdh-5-0.x86_64.rpm
sudo yum --nogpgcheck localinstall -y cloudera-cdh-5-0.x86_64.rpm
sudo rpm --import http://archive.cloudera.com/cdh5/redhat/6/x86_64/cdh/RPM-GPG-KEY-cloudera

echo "Install Hadoop with YARN"
sudo yum install -y hadoop-conf-pseudo

echo "Starting Hadoop and Verifying it is Working Properly"
rpm -ql hadoop-conf-pseudo

echo "Format the NameNode."
sudo -u hdfs hdfs namenode -format

echo "Start HDFS"
sudo cp -f /etc/hadoop/conf/hdfs-site.xml /etc/hadoop/conf/hdfs-site.xml.bak
sudo cp -f /vagrant/vagrant.d/config/hdfs-site.xml /etc/hadoop/conf/hdfs-site.xml
sudo cp -f /etc/hadoop/conf/core-site.xml /etc/hadoop/conf/core-site.xml.bak
sudo cp -f /vagrant/vagrant.d/config/core-site.xml /etc/hadoop/conf/core-site.xml
for x in `cd /etc/init.d ; ls hadoop-hdfs-*` ; do sudo service $x start ; done

echo "Create a new /tmp directory and set permissions:"
sudo -u hdfs hadoop fs -mkdir /tmp
sudo -u hdfs hadoop fs -chmod -R 1777 /tmp

echo "Create Staging and Log Directories"
sudo -u hdfs hadoop fs -mkdir -p /tmp/hadoop-yarn/staging/history/done_intermediate
sudo -u hdfs hadoop fs -chown -R mapred:mapred /tmp/hadoop-yarn/staging
sudo -u hdfs hadoop fs -chmod -R 1777 /tmp
sudo -u hdfs hadoop fs -mkdir -p /var/log/hadoop-yarn
sudo -u hdfs hadoop fs -chown yarn:mapred /var/log/hadoop-yarn

echo "Verify the HDFS File Structure:"
sudo -u hdfs hadoop fs -ls -R /

echo "Install Hive"
sudo yum install -y hive hive-metastore hive-server2
sudo cp -f /etc/default/hive-server2 /etc/default/hive-server2.bak
echo "export HADOOP_MAPRED_HOME=/usr/lib/hadoop-mapreduce" | sudo tee -a /etc/default/hive-server2
sudo cp -f /etc/hive/conf/hive-site.xml /etc/hive/conf/hive-site.xml.bak
sudo cp -f /vagrant/vagrant.d/config/hive-site.xml /etc/hive/conf/hive-site.xml

echo "Create Hive Directories"
sudo -u hdfs hadoop fs -mkdir -p /user/hive
sudo -u hdfs hadoop fs -chown hive /user/hive

echo "Install MYSQL"
sudo yum install -y --enablerepo=remi mysql-server
sudo service mysqld start
sudo chkconfig mysqld on
sudo yum install -y mysql-connector-java
sudo ln -s /usr/share/java/mysql-connector-java.jar /usr/lib/hive/lib/mysql-connector-java.jar

echo "Create Local Metastore..."
sudo mysqladmin -u root password 'root'
sudo mysql -uroot -proot -e "CREATE DATABASE metastore DEFAULT CHARACTER SET 'latin1'"
sudo mysql -uroot -proot -e "GRANT ALL PRIVILEGES ON metastore.* TO hive@localhost IDENTIFIED BY 'hive'"
sudo mysql -uroot -proot -e "FLUSH PRIVILEGES"
sudo mysql -uroot -proot metastore < /usr/lib/hive/scripts/metastore/upgrade/mysql/hive-schema-0.12.0.mysql.sql

echo "Restart..."
for x in `cd /etc/init.d ; ls hive-*` ; do sudo service $x stop ; done
for x in `cd /etc/init.d ; ls hive-*` ; do sudo service $x start ; done
for x in `cd /etc/init.d ; ls hive-*` ; do sudo chkconfig $x on ; done

echo "Install Sqoop"
sudo yum install -y sqoop
sudo yum install -y postgresql-jdbc
sudo ln -s /usr/share/java/postgresql-jdbc.jar /usr/lib/sqoop/lib/postgresql-jdbc.jar
sudo ln -s /usr/share/java/mysql-connector-java.jar /usr/lib/sqoop/lib/mysql-connector-java.jar

echo "Restart Hadoop"
for x in `cd /etc/init.d ; ls hadoop-*` ; do sudo service $x restart ; done
for x in `cd /etc/init.d ; ls hadoop-*` ; do sudo chkconfig $x on ; done

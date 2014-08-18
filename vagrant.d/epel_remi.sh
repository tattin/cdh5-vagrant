#! /bin/sh

echo "Add epel"
sudo rpm --import http://apt.sw.be/RPM-GPG-KEY.dag.txt
sudo rpm -ivh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
sudo rpm -q epel-release

echo "Add remi"
sudo rpm --import http://rpms.famillecollet.com/RPM-GPG-KEY-remi
sudo rpm -ivh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
sudo rpm -q remi-release

echo "Install php5.5"
sudo yum -y install --enablerepo=remi --enablerepo=remi-php55 php php-cli php-mcrypt php-mysql php-pgsql php-mbstring
sudo php -v

echo "Install beanstalkd"
sudo yum -y install beanstalkd
sudo service beanstalkd start
sudo chkconfig beanstalkd on

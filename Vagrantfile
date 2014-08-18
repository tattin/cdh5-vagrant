# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  config.vm.box     = "centos6.5_x86_64"
  config.vm.box_url = "http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_centos-6.5_chef-provisionerless.box"

  config.vm.hostname = "dev-wezen"

  config.vm.network :forwarded_port, guest: 80, host: 8080, auto_correct: true

  config.vm.provider :virtualbox do |vb|
    vb.customize(["modifyvm", :id, "--natdnshostresolver1", "off"  ])
    vb.customize(["modifyvm", :id, "--natdnsproxy1",        "off"  ])
    vb.customize(["modifyvm", :id, "--memory",              "1024" ])
  end

  config.vm.synced_folder ".", "/vagrant", :mount_options => ["dmode=777,fmode=666"]

  config.vm.provision :shell, path: "vagrant.d/epel_remi.sh"
  config.vm.provision :shell, path: "vagrant.d/cdh5_yarn_pseudo.sh"
  config.vm.provision :shell, path: "vagrant.d/apache_fluentd_php.sh"

  config.vm.provision "shell", inline: <<-EOS
    sudo service iptables stop
    sudo chkconfig iptables off

    sudo yum install -y postgresql-server
    if [ ! -f "/var/lib/pgsql/data/postgresql.conf" ]; then
      sudo su - postgres -c "/usr/bin/initdb"
    fi
    sudo service postgresql start
    sudo chkconfig postgresql on
    sudo sed -i \
      -e "s/^#listen_addresses = 'localhost'/listen_addresses = '*'/g" \
      /var/lib/pgsql/data/postgresql.conf
    sudo sed -i \
      -e "s:127.0.0.1/32:0.0.0.0/0:g" \
      /var/lib/pgsql/data/pg_hba.conf
    sudo service postgresql restart

    createdb -U postgres -E UTF8 -T template0 refdb
    psql -U postgres refdb < /vagrant/app/Plugin/PvExport/Config/Schema/refdb.schema.sql
    psql -U postgres refdb < /vagrant/app/Plugin/PvExport/Config/Schema/refdb.migrate.sql
    createdb -U postgres -E UTF8 -T template0 core
    createdb -U postgres -E UTF8 -T template0 test

    mysql -uroot -proot -e "CREATE DATABASE exportdb DEFAULT CHARACTER SET utf8"
    mysql -uroot -proot -e "ALTER DATABASE test CHARACTER SET utf8 COLLATE utf8_unicode_ci"

    mysql -uroot -proot exportdb < /vagrant/app/Plugin/ClickExport/Config/Schema/exportdb.schema.sql
    mysql -uroot -proot exportdb < /vagrant/app/Plugin/PvExport/Config/Schema/exportdb.schema.sql
    mysql -uroot -proot exportdb < /vagrant/app/Config/Schema/exportdb.schema.sql
  EOS

end

#! /bin/sh

echo "Stop iptables"
sudo service iptables stop
sudo chkconfig iptables off

echo "Install apache"
sudo yum -y install httpd
sudo httpd -V
sudo service httpd start
sudo chkconfig httpd on
echo '<html><body>It works!</body></html>' | sudo tee /var/www/html/index.html
curl -D - localhost

echo "Install from rpm Fluentd Repository"
curl -L http://toolbelt.treasuredata.com/sh/install-redhat.sh | sh
sudo /usr/lib64/fluent/ruby/bin/fluent-gem install fluent-plugin-webhdfs
sudo /etc/init.d/td-agent start
sudo chkconfig td-agent on
sudo /etc/init.d/td-agent status
curl -X POST -d 'json={"json":"message"}' http://localhost:8888/debug.test
tail /var/log/td-agent/td-agent.log

echo "Setting Fluentd Configuration ApacheLog(LTSV)"
sudo cp -f /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf.bak
echo 'LogFormat "domain:%V\thost:%h\tserver:%A\tident:%l\tuser:%u\ttime:%{%d/%b/%Y:%H:%M:%S %z}t\tmethod:%m\tpath:%U%q\tprotocol:%H\tstatus:%>s\tsize:%b\treferer:%{Referer}i\tagent:%{User-Agent}i\tresponse_time:%D\tcookie:%{cookie}i\tset_cookie:%{Set-Cookie}o" combined' | sudo tee -a /etc/httpd/conf/httpd.conf
sudo chmod o+rx /var/log/httpd
sudo service httpd restart
sudo cp -f /etc/td-agent/td-agent.conf /etc/td-agent/td-agent.conf.bak
sudo tee -a /etc/td-agent/td-agent.conf <<EOF

<source>
  type tail
  path /var/log/httpd/access_log
  format ltsv
  time_key time
  time_format %d/%b/%Y:%H:%M:%S %z
  tag apache.access
  pos_file /var/log/td-agent/apache_access.pos
</source>

<match apache.access>
  type copy
  <store>
    type file
    path /var/log/td-agent/access_log
  </store>
  <store>
    type webhdfs
    host localhost
    port 50070
    path /tmp/logs/fluent/access.%Y%m%d_%H.log
    flush_interval 10s
  </store>
</match>
EOF
sudo /etc/init.d/td-agent restart

echo "Checking Fluentd ApacheLog(LTSV)"
# sleep 5
# curl -v localhost/index.html?foo=bar -H "Host: foo.bar.jp" -A "Mozilla"
# sleep 5
# sudo tail /var/log/td-agent/access_log.*
# sudo -u hdfs hadoop fs -cat /tmp/logs/fluent/access.*.log

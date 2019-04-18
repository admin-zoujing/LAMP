#! /bin/bash
#centos7.4源码编译lamp(http2.4.29+mysql5.7.24+php7.2.14)安装脚本
sourceinstall=/usr/local/src/lamp
chmod -R 777 $sourceinstall
#1、时间时区同步，修改主机名
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
ntpdate cn.pool.ntp.org
hwclock --systohc
echo "*/30 * * * * root ntpdate -s 3.cn.poop.ntp.org" >> /etc/crontab

sed -i 's|SELINUX=.*|SELINUX=disabled|' /etc/selinux/config
sed -i 's|SELINUXTYPE=.*|#SELINUXTYPE=targeted|' /etc/selinux/config
sed -i 's|SELINUX=.*|SELINUX=disabled|' /etc/sysconfig/selinux 
sed -i 's|SELINUXTYPE=.*|#SELINUXTYPE=targeted|' /etc/sysconfig/selinux
setenforce 0 && systemctl stop firewalld && systemctl disable firewalld 
setenforce 0 && systemctl stop iptables && systemctl disable iptables

rm -rf /var/run/yum.pid 
rm -rf /var/run/yum.pid
#一、-----------------------------------安装httpd--------------------------------------------------
#1）解决依赖关系
yum -y install epel-release.noarch 
yum -y install pcre-devel openssl-devel make gcc* expat-devel ncurses-devel libxml2-devel

#2)编译安装apr
cd $sourceinstall
mkdir -pv /usr/local/apr
tar -zxvf apr-1.6.3.tar.gz -C /usr/local/apr
cd /usr/local/apr/apr-1.6.3/
#sed -i 's|$RM "$cfgfile"|# $RM "$cfgfile"|' /usr/local/apr/apr-1.6.3/configure
./configure --prefix=/usr/local/apr
make
make install
#3)编译安装apr-util
cd $sourceinstall
mkdir -pv /usr/local/apr-util
tar -zxvf apr-util-1.6.1.tar.gz -C /usr/local/apr-util/
cd /usr/local/apr-util/apr-util-1.6.1/
./configure --prefix=/usr/local/apr-util --with-apr=/usr/local/apr
make 
make install
#4)编译httpd
cd $sourceinstall
mkdir -pv /usr/local/apache
tar -zxvf httpd-2.4.37.tar.gz -C /usr/local/apache
cd /usr/local/apache/httpd-2.4.37/
./configure --prefix=/usr/local/apache --sysconfdir=/usr/local/apache/conf --enable-so --enable--ssl --enable-cgi --enable-rewrite --with-zlib --with-pcre --with-apr=/usr/local/apr --with-apr-util=/usr/local/apr-util --enable-modeles=most --enable-mpms-shared=all --with-mpm=event --enable-proxy --enable-proxy-http --enable-proxy-ajp --enable-proxy-balancer  --enable-lbmethod-heartbeat --enable-heartbeat --enable-slotmem-shm  --enable-slotmem-plain --enable-watchdog
make 
make install

#二进制程序：
echo 'export PATH=/usr/local/apache/bin:$PATH' > /etc/profile.d/httpd.sh 
source /etc/profile.d/httpd.sh
#头文件输出给系统：
ln -sv /usr/local/apache/include /usr/include/httpd
#库文件输出：
echo '/usr/local/apache/modules' > /etc/ld.so.conf.d/httpd.conf
#让系统重新生成库文件路径缓存
ldconfig
#导出man文件：
echo 'MANDATORY_MANPATH                       /usr/local/apache/man' >> /etc/man_db.conf
source /etc/profile.d/httpd.sh 
sleep 5
source /etc/profile.d/httpd.sh 
#修改配置文件启动
sed -i 's|#ServerName www.example.com:80|ServerName localhost:80|' /usr/local/apache/conf/httpd.conf

#设置开机自启动
cat > /usr/lib/systemd/system/httpd.service <<EOF
[Unit]
Description=The Apache HTTP Server
After=network.target remote-fs.target nss-lookup.target
Documentation=man:httpd(8)
Documentation=man:apachectl(8)

[Service]
Type=forking
ExecStart=/usr/local/apache/bin/httpd -k start
ExecReload=/usr/local/apache/bin/httpd  -k graceful
ExecStop=/usr/local/apache/bin/httpd  -k stop
ExecRestart=/usr/local/apache/bin/httpd  -k restart
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
chown -Rf daemon:daemon /usr/local/apache
systemctl daemon-reload
systemctl enable httpd.service
systemctl restart httpd.service

firewall-cmd --permanent --zone=public --add-port=80/tcp --permanent
firewall-cmd --permanent --query-port=80/tcp
firewall-cmd --reload

#二、-----------------------------------安装mysql--------------------------------------------------
yum -y install epel-release
yum install -y apr* autoconf automake bison bzip2 bzip2* compat* cpp curl curl-devel fontconfig fontconfig-devel freetype freetype* freetype-devel gcc gcc-c++ gd gettext gettext-devel glibc kernel kernel-headers keyutils keyutils-libs-devel krb5-devel libcom_err-devel libpng libpng-devel libjpeg* libsepol-devel libselinux-devel libstdc++-devel libtool* libgomp libxml2 libxml2-devel libXpm* libtiff libtiff* make mpfr ncurses* ntp openssl openssl-devel patch pcre-devel perl php-common php-gd policycoreutils telnet t1lib t1lib* nasm nasm* wget zlib-devel texlive-latex texlive-metapost texlive-collection-fontsrecommended --skip-broken
yum install -y apr* autoconf automake bison bzip2 bzip2* compat* cpp curl curl-devel fontconfig fontconfig-devel freetype freetype* freetype-devel gcc gcc-c++ gd gettext gettext-devel glibc kernel kernel-headers keyutils keyutils-libs-devel krb5-devel libcom_err-devel libpng libpng-devel libjpeg* libsepol-devel libselinux-devel libstdc++-devel libtool* libgomp libxml2 libxml2-devel libXpm* libtiff libtiff* make mpfr ncurses* ntp openssl openssl-devel patch pcre-devel perl php-common php-gd policycoreutils telnet t1lib t1lib* nasm nasm* wget zlib-devel texlive-latex texlive-metapost texlive-collection-fontsrecommended --skip-broken

cd $sourceinstall
mkdir -pv /usr/local/cmake
tar -xzvf cmake-3.9.3.tar.gz -C /usr/local/cmake
cd /usr/local/cmake/cmake-3.9.3/
./configure
make && make install

#1、卸载mysql和marriadb
yum -y remove mysql*
yum -y remove mariadb*
yum -y remove boost*
rpm -e --nodeps `rpm -qa | grep mariadb`
rpm -e --nodeps `rpm -qa | grep mysql`
rpm -e --nodeps `rpm -qa | grep boost`
#2、配置Mysql服务
cd $sourceinstall
groupadd mysql
useradd -g mysql -s /sbin/nologin mysql
mkdir -pv /usr/local/mysql/boost
mv boost_1_59_0.tar.gz /usr/local/mysql/boost
mkdir -pv /usr/local/mysql/{data,conf,logs}
tar -zxvf mysql-5.7.24.tar.gz -C /usr/local/mysql
cd /usr/local/mysql/mysql-5.7.24/
cmake . -DCMAKE_INSTALL_PREFIX=/usr/local/mysql -DMYSQL_DATADIR=/usr/local/mysql/data -DSYSCONFDIR=/usr/local/mysql/conf -DMYSQL_USER=mysql -DMYSQL_UNIX_ADDR=/usr/local/mysql/logs/mysql.sock -DDEFAULT_CHARSET=utf8mb4 -DDEFAULT_COLLATION=utf8mb4_general_ci -DMYSQL_TCP_PORT=3306 -DWITH_MYISAM_STORAGE_ENGINE=1 -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_ARCHIVE_STORAGE_ENGINE=1 -DWITH_BLACKHOLE_STORAGE_ENGINE=1 -DENABLED_LOCAL_INFILE=1 -DWITH_SSL:STRING=bundled -DWITH_ZLIB:STRING=bundled -DENABLE_DOWNLOADS=1 -DDOWNLOAD_BOOST=1 -DWITH_BOOST=/usr/local/mysql/boost -DENABLE_DTRACE=0
make -j `grep processor /proc/cpuinfo | wc -l`
make install
make clean
rm -rf CMakeCache.txt
chown -Rf mysql:mysql /usr/local/mysql

#CentOS安装MySQL时报Curses library not found解决方法
#进入你的mysql解压目录删除CMakecache.txt文件，在解压目录里安装ncurese包，重新编译即可
# rm CMakeCache.txt
# yum -y install ncurses-devel

cat > /usr/local/mysql/conf/my.cnf <<EOF
[client]
default-character-set=utf8mb4

[mysql]
default-character-set=utf8mb4

[mysqld]
port = 3306
socket = /usr/local/mysql/logs/mysql.sock
pid-file = /usr/local/mysql/mysql.pid
basedir = /usr/local/mysql
datadir = /usr/local/mysql/data
tmpdir = /tmp
user = mysql
log-error = /usr/local/mysql/logs/mysql.log
slow_query_log = ON
server-id = 1 
log-bin = mysql-bin
binlog-format=ROW
#max_allowed_packet = 64M
max_connections=1000
log_bin_trust_function_creators=1
character-set-client-handshake = FALSE
character-set-server = utf8mb4 
collation-server = utf8mb4_unicode_ci
init_connect = 'SET NAMES utf8mb4'
sql_mode='STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION'

bulk_insert_buffer_size = 100M

# -------------- #
# InnoDB Options #
# -------------- #
innodb_buffer_pool_size = 4G
innodb_log_buffer_size = 16M
innodb_log_file_size = 256M
max_binlog_cache_size = 2G
max_binlog_size = 1G
expire_logs_days = 7
EOF
chown -Rf mysql:mysql /usr/local/mysql

#二进制程序：
echo 'export PATH=/usr/local/mysql/bin:$PATH' > /etc/profile.d/mysql.sh 
source /etc/profile.d/mysql.sh
#头文件输出给系统：
ln -sv /usr/local/mysql/include /usr/include/mysql
#库文件输出：MySQL数据库的动态链接库共享至系统链接库,一般MySQL数据库会被PHP等服务调用
echo '/usr/local/mysql/lib' > /etc/ld.so.conf.d/mysql.conf
#ln -s /usr/local/mysql/lib/libmysqlclient.so.20 /usr/lib64/libmysqlclient.so.20
#让系统重新生成库文件路径缓存
ldconfig
#导出man文件：
echo 'MANDATORY_MANPATH                       /usr/local/mysql/man' >> /etc/man_db.conf
source /etc/profile.d/mysql.sh 
sleep 5
source /etc/profile.d/mysql.sh 
cat > /usr/lib/systemd/system/mysqld.service <<EOF
[Unit]
Description=MySQL Server
Documentation=man:mysqld(8)
Documentation=http://dev.mysql.com/doc/refman/en/using-systemd.html
After=network.target
After=syslog.target

[Service]
User=mysql
Group=mysql
ExecStart=/usr/local/mysql/bin/mysqld --defaults-file=/usr/local/mysql/conf/my.cnf
LimitNOFILE = 5000
Restart=on-failure
RestartPreventExitStatus=1
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

/usr/local/mysql/bin/mysqld --initialize --user=mysql --basedir=/usr/local/mysql --datadir=/usr/local/mysql/data/
systemctl daemon-reload
systemctl enable mysqld.service
systemctl restart mysqld.service
chown -Rf mysql:mysql /usr/local/mysql

#查看默认root本地登录密码如果不是用空密码初始化的数据库则：
grep 'temporary password' /usr/local/mysql/logs/mysql.log | awk -F: '{print $NF}'
systemctl stop mysqld.service
echo 'skip-grant-tables' >> /usr/local/mysql/conf/my.cnf
systemctl restart mysqld.service 
sleep 5
mysql -uroot -e "update mysql.user set authentication_string=PASSWORD('Root_123456*0987') where User='root';";
sed -i 's|skip-grant-tables|#skip-grant-tables|' /usr/local/mysql/conf/my.cnf;
systemctl restart mysqld.service;
sleep 5
mysql -uroot -pRoot_123456*0987 --connect-expired-password -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'Root_123456*0987';";
mysql -uroot -pRoot_123456*0987 --connect-expired-password -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'Root_123456*0987' WITH GRANT OPTION;";
mysql -uroot -pRoot_123456*0987 --connect-expired-password -e "flush privileges;";

firewall-cmd --permanent --zone=public --add-port=3306/tcp --permanent
firewall-cmd --permanent --query-port=3306/tcp
firewall-cmd --reload


#三、-----------------------------------安装php--------------------------------------------------
yum -y install wget vim pcre pcre-devel openssl openssl-devel libicu-devel gcc gcc-c++ autoconf libjpeg libjpeg-devel libpng libpng-devel freetype freetype-devel libxml2 libxml2-devel zlib zlib-devel glibc glibc-devel glib2 glib2-devel ncurses ncurses-devel curl curl-devel krb5-devel libidn libidn-devel openldap openldap-devel nss_ldap jemalloc-devel cmake boost-devel bison automake libevent libevent-devel gd gd-devel libtool* libmcrypt libmcrypt-devel mcrypt mhash libxslt libxslt-devel readline readline-devel gmp gmp-devel libcurl libcurl-devel openjpeg-devel

#yasm源码包是一款常见的开源汇编器，解压、编译、安装过程：
cd $sourceinstall
mkdir -pv /usr/local/yasm
tar -zxvf yasm-1.3.0.tar.gz -C /usr/local/yasm
cd /usr/local/yasm/yasm-1.3.0/
./configure --prefix=/usr/local/yasm
make && make install
#libmcrypt源码包是用于加密算法的扩展库程序，解压、编译、安装过程：
cd $sourceinstall
mkdir -pv /usr/local/libmcrypt
tar zxvf libmcrypt-2.5.8.tar.gz -C /usr/local/libmcrypt
cd /usr/local/libmcrypt/libmcrypt-2.5.8
./configure --prefix=/usr/local/libmcrypt
make && make install

#tiff源码包是用于提供标签图像文件格式的服务程序，解压、编译、安装过程：
cd $sourceinstall
mkdir -p /usr/local/tiff
tar -zxvf tiff-4.0.3.tar.gz -C /usr/local/tiff
cd /usr/local/tiff/tiff-4.0.3
./configure --prefix=/usr/local/tiff --enable-shared
make && make install
#libpng源码包是用于提供png图片格式支持函数库的服务程序，解压、编译、安装过程：
cd $sourceinstall
mkdir -p /usr/local/libpng
tar -zxvf libpng-1.6.32.tar.gz -C /usr/local/libpng
cd /usr/local/libpng/libpng-1.6.32/
./configure --prefix=/usr/local/libpng --enable-shared
make && make install
#freetype源码包是用于提供字体支持引擎的服务程序，解压、编译、安装过程：
cd $sourceinstall
mkdir -p /usr/local/freetype
tar -zxvf freetype-2.8.tar.gz -C /usr/local/freetype
cd /usr/local/freetype/freetype-2.8/
./configure --prefix=/usr/local/freetype --enable-shared
make && make install
#jpeg源码包是用于提供jpeg图片格式支持函数库的服务程序，解压、编译、安装过程：
cd $sourceinstall
mkdir -p /usr/local/jpeg
tar -zxvf jpegsrc.v9b.tar.gz -C /usr/local/jpeg
cd /usr/local/jpeg/jpeg-9b/
./configure --prefix=/usr/local/jpeg --enable-shared
make && make install
#libgd源码包是用于提供图形处理的服务程序，解压、编译、安装过程，而在编译libgd源码包的时候请记得写入的是jpeg、libpng、freetype、tiff、libvpx等服务程序在系统中的安装路径，即在上面安装过程中使用--perfix参数指定的目录路径：
cd $sourceinstall
mkdir -p /usr/local/libgd
tar -zxvf libgd-2.2.5.tar.gz -C /usr/local/libgd
cd /usr/local/libgd/libgd-2.2.5/
./configure --prefix=/usr/local/libgd --enable-shared --with-jpeg=/usr/local/jpeg --with-png=/usr/local/libpng --with-freetype=/usr/local/freetype --with-fontconfig=/usr/local/freetype --with-xpm=/usr/ --with-tiff=/usr/local/tiff 
make && make install

#此时终于把编译php服务源码包的相关软件包都已经安装部署妥当了，在开始编译源码包前先定义一个名称为LD_LIBRARY_PATH的全局环境变量，该环境变量的作用是帮助系统找到指定的动态链接库文件，是编译php服务源码包的必须元素之一。编译php服务源码包时除了定义要安装到的目录以外，还需要依次定义配置Php服务配置文件保存目录、Mysql数据库服务程序所在目录、Mysql数据库服务程序配置文件所在目录以及libpng、jpeg、freetype、libvpx、zlib、t1lib等等服务程序的安装目录路径，并通过参数启动php服务程序的诸多默认功能：
cd $sourceinstall
groupadd php
useradd php -s /sbin/nologin -g php
mkdir -p /usr/local/php
tar -zxvf php-7.2.14.tar.gz -C /usr/local/php
cd /usr/local/php/php-7.2.14
export LD_LIBRARY_PATH=/usr/local/libgd/lib
# make clean
#./configure --prefix=/usr/local/php --with-config-file-path=/usr/local/php/etc --with-gd --with-png-dir=/usr/local/libpng --with-jpeg-dir=/usr/local/jpeg --with-freetype-dir=/usr/local/freetype --with-xpm-dir=/usr/  --with-zlib-dir=/usr/local/zlib  --with-iconv --enable-libxml --enable-xml --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization --enable-opcache --enable-mbregex --enable-fpm --enable-mbstring --enable-ftp --with-openssl --enable-pcntl --enable-sockets --with-xmlrpc --enable-zip --enable-soap --without-pear --with-gettext --enable-session --with-curl --enable-ctype 
./configure --prefix=/usr/local/php --with-config-file-path=/usr/local/php/etc --enable-mysqlnd --with-mysqli=mysqlnd --with-mysql-sock=/usr/local/mysql/logs/mysql.sock --with-pdo-mysql=mysqlnd --with-gd --with-png-dir=/usr/local/libpng --with-jpeg-dir=/usr/local/jpeg --with-freetype-dir=/usr/local/freetype --with-xpm-dir=/usr/  --with-zlib-dir=/usr/local/zlib  --with-iconv --enable-libxml --enable-xml --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization --enable-opcache --enable-mbregex --enable-fpm --enable-mbstring --enable-ftp --with-openssl --enable-pcntl --enable-sockets --with-xmlrpc --enable-zip --enable-soap --without-pear --with-gettext --enable-session --with-curl --enable-ctype --with-apxs2=/usr/local/apache/bin/apxs
make -j2 && make install  
#在等待php源码包程序安装完成后，需要删除掉当前默认的配置文件，然后从php服务程序目录中复制对应的配置文件过来：
cp -rpf php.ini-production /usr/local/php/etc/php.ini
cp -rpf /usr/local/php/etc/php-fpm.conf.default /usr/local/php/etc/php-fpm.conf
cp -rpf /usr/local/php/etc/php-fpm.d/www.conf.default /usr/local/php/etc/php-fpm.d/www.conf
#php-fpm.conf是php服务程序的重要配置文件之一，咱们需要将其配置内容中约25行左右的pid文件保存路径启用，并在约148-149行的user与group参数分别修改为www帐户和用户组名称：
sed -i 's|;pid = run/php-fpm.pid|pid = run/php-fpm.pid|' /usr/local/php/etc/php-fpm.conf
sed -i 's|user = nobody|user = php|' /usr/local/php/etc/php-fpm.d/www.conf
sed -i 's|group = nobody|group = php|' /usr/local/php/etc/php-fpm.d/www.conf
#配置妥当后便可把服务管理脚本文件复制到/etc/rc.d/init.d中啦，为了能够有执行脚本请记得要给予755权限，最后把php-fpm服务程序加入到开机启动项中：
cat > /usr/lib/systemd/system/php-fpm.service <<EOF
[Unit] 
Description=php-fpm 
After=network.target

[Service] 
Type=simple
PIDFile=/run/php-fpm.pid
ExecStart=/usr/local/php/sbin/php-fpm --nodaemonize --fpm-config /usr/local/php/etc/php-fpm.conf
ExecStop=/bin/kill -SIGINT \$MAINPID
ExecReload=/bin/kill -USR2 \$MAINPID
PrivateTmp=true

[Install] 
WantedBy=multi-user.target
EOF
chmod 755 /usr/lib/systemd/system/php-fpm.service
chown -Rf php:php /usr/local/php
systemctl daemon-reload && systemctl enable php-fpm.service && systemctl restart php-fpm.service

#由于php服务程序的配置参数直接会影响到Web网站服务的运行环境，如果默认开启了例如允许用户在网页中执行Linux命令等等不必要且高危的功能，进而会降低了骇客入侵网站的难度，甚至加大了骇客提权到整台服务器的管理权限的几率。因此需要编辑php.ini配置文件，在约305左右的disable_functions参数后面追加上要禁止的功能名称吧，下面的禁用功能名单是依据运营网站经验而定制的，也许并不能适合每个生产环境，可以在此基础上根据自身工作要求而酌情删减：
sed -i 's|disable_functions =|disable_functions = passthru,exec,system,chroot,scandir,chgrp,chown,shell_exec,proc_get_status,ini_alter,ini_alter,ini_restor e,dl,openlog,syslog,readlink,symlink,popepassthru,stream_socket_server,escapeshellcmd,dll,popen,disk_free_space,checkdnsrr,checkdnsrr,g etservbyname,getservbyport,disk_total_space,posix_ctermid,posix_get_last_error,posix_getcwd,posix_getegid,posix_geteuid,posix_getgid,po six_getgrgid,posix_getgrnam,posix_getgroups,posix_getlogin,posix_getpgid,posix_getpgrp,posix_getpid,posix_getppid,posix_getpwnam,posix_ getpwuid,posix_getrlimit,posix_getsid,posix_getuid,posix_isatty,posix_kill,posix_mkfifo,posix_setegid,posix_seteuid,posix_setgid,posix_ setpgid,posix_setsid,posix_setuid,posix_strerror,posix_times,posix_ttyname,posix_uname|' /usr/local/php/etc/php.ini

#四、-----------------------------------安装PHP redis扩展--------------------------------------------------
cd $sourceinstall
mkdir -pv /usr/local/php/phpredis
tar -zxvf phpredis-4.2.0.tar.gz -C /usr/local/php/phpredis
cd /usr/local/php/phpredis/phpredis-4.2.0
/usr/local/php/bin/phpize
./configure --prefix=/usr/local/php/phpredis --enable-redis --with-php-config=/usr/local/php/bin/php-config
make 
make test
make install
#编辑php.ini，整合php和redis,将redis提供的样例配置导入php.ini
echo 'extension = /usr/local/php/lib/php/extensions/no-debug-non-zts-20170718/redis.so' >> /usr/local/php/etc/php.ini
chown -Rf php:php /usr/local/php/phpredis
systemctl daemon-reload && systemctl restart php-fpm.service 


sed -i '/AddType application\/x-compress/i\    AddType application\/x-httpd-php .php' /usr/local/apache/conf/httpd.conf
sed -i 's|DirectoryIndex index.html|DirectoryIndex index.html index.php|' /usr/local/apache/conf/httpd.conf

#注释111行和112行    sed -i '111,112 s|^|#|g' /usr/local/apache/conf/httpd.conf
#去掉注释111行和112行sed -i '111,112 s|#||g' /usr/local/apache/conf/httpd.conf
mkdir -pv /usr/local/apache/htdocs/php/ 
cat > /usr/local/apache/htdocs/php/index.php <<EOF
<?php
phpinfo();
?>
EOF
chown -R daemon:daemon /usr/local/apache/htdocs/php/ 
systemctl daemon-reload && systemctl restart php-fpm.service && systemctl restart httpd.service


#六、-----------------------------------安装phpMyAdmin--------------------------------------------------
cd $sourceinstall
mkdir -pv /usr/local/php/php/php/fpm/phpmyadmin
unzip phpMyAdmin-4.7.9-all-languages.zip -d /usr/local/php/php/php/fpm/phpmyadmin
cd /usr/local/php/php/php/fpm/phpmyadmin/phpMyAdmin-4.7.9-all-languages
cp config.sample.inc.php config.inc.php 
sed -i "s|\$cfg\['Servers'\]\[\$i\]\['auth_type'\] = 'cookie';|\$cfg\['Servers'\]\[\$i\]\['auth_type'\] = 'config';|" /usr/local/php/php/php/fpm/phpmyadmin/phpMyAdmin-4.7.9-all-languages/config.inc.php 
sed -i "/\$cfg\['Servers'\]\[\$i\]\['host'\] = 'localhost';/a\$cfg\['Servers'\]\[\$i\]\['password'\] = 'Root_123456*0987';" /usr/local/php/php/php/fpm/phpmyadmin/phpMyAdmin-4.7.9-all-languages/config.inc.php 
sed -i "/\$cfg\['Servers'\]\[\$i\]\['host'\] = 'localhost';/a\$cfg\['Servers'\]\[\$i\]\['user'\] = 'root';" /usr/local/php/php/php/fpm/phpmyadmin/phpMyAdmin-4.7.9-all-languages/config.inc.php 
sed -i "s|\$cfg\['Servers'\]\[\$i\]\['host'\] = 'localhost';|\$cfg\['Servers'\]\[\$i\]\['host'\] = '127.0.0.1';|" /usr/local/php/php/php/fpm/phpmyadmin/phpMyAdmin-4.7.9-all-languages/config.inc.php 

cat >> /usr/local/apache/conf/extra/httpd-vhosts.conf <<EOF
<VirtualHost *:80>
    DocumentRoot "/usr/local/php/php/php/fpm/phpmyadmin"
    #DocumentRoot "/home/webroot/apacherooot"
    ServerName phpmyadmin.com
    #ServerName 192.168.8.52:80
    ServerAlias www.phpmyadmin.com
    ErrorLog "logs/phpmyadmin.com-error_log"
    CustomLog "logs/phpmyadmin.com-access_log" common

  ProxyRequests Off
  ProxyPassMatch ^/(.*\.php)\$ fcgi://127.0.0.1:9000/usr/local/php/php/php/fpm/phpmyadmin/phpMyAdmin-4.7.9-all-languages/\$1

    <Directory "/usr/local/php/php/php/fpm/phpmyadmin">
        Options none
        AllowOverride none
        Require all granted
    </Directory>
</VirtualHost>
EOF
sed -i 's|#LoadModule proxy_module modules/mod_proxy.so|LoadModule proxy_module modules/mod_proxy.so|' /usr/local/apache/conf/httpd.conf
sed -i 's|#LoadModule proxy_connect_module modules/mod_proxy_connect.so|LoadModule proxy_connect_module modules/mod_proxy_connect.so|' /usr/local/apache/conf/httpd.conf
sed -i 's|#LoadModule proxy_ftp_module modules/mod_proxy_ftp.so|LoadModule proxy_ftp_module modules/mod_proxy_ftp.so|' /usr/local/apache/conf/httpd.conf
sed -i 's|#LoadModule proxy_http_module modules/mod_proxy_http.so|LoadModule proxy_http_module modules/mod_proxy_http.so|' /usr/local/apache/conf/httpd.conf
sed -i 's|#LoadModule proxy_fcgi_module modules/mod_proxy_fcgi.so|LoadModule proxy_fcgi_module modules/mod_proxy_fcgi.so|' /usr/local/apache/conf/httpd.conf
sed -i 's|#LoadModule proxy_scgi_module modules/mod_proxy_scgi.so|LoadModule proxy_scgi_module modules/mod_proxy_scgi.so|' /usr/local/apache/conf/httpd.conf
#sed -i 's|#LoadModule proxy_ajp_module modules/mod_proxy_ajp.so|LoadModule proxy_ajp_module modules/mod_proxy_ajp.so|' /usr/local/apache/conf/httpd.conf
#sed -i 's|#LoadModule proxy_balancer_module modules/mod_proxy_balancer.so|LoadModule proxy_balancer_module modules/mod_proxy_balancer.so|' /usr/local/apache/conf/httpd.conf
#sed -i 's|#LoadModule proxy_express_module modules/mod_proxy_express.so|LoadModule proxy_express_module modules/mod_proxy_express.so|' /usr/local/apache/conf/httpd.conf

sed -i 's|#Include conf/extra/httpd-vhosts.conf|Include conf/extra/httpd-vhosts.conf|' /usr/local/apache/conf/httpd.conf
sed -i '23,38 s|^|#|g' /usr/local/apache/conf/extra/httpd-vhosts.conf
echo "`ifconfig|grep 'inet'|head -1|awk '{print $2}'|cut -d: -f2` www.phpmyadmin.com" >> /etc/hosts
chown -Rf php:php /usr/local/php/php/php/fpm/phpmyadmin

#注释111行和112行    sed -i '111,112 s|^|#|g' /usr/local/apache/conf/extra/httpd-vhosts.conf
#去掉注释111行和112行sed -i '111,112 s|#||g' /usr/local/apache/conf/extra/httpd-vhosts.conf

#七、-----------------------------------搭建Discuz论坛--------------------------------------------------
# cd $sourceinstall
# mkdir -pv /usr/local/discuz
# unzip Discuz_X3.2_SC_GBK.zip -d /usr/local/discuz
# rm -rf /usr/local/apache/htdocs/{index.html,50x.html}*
# cd /usr/local/discuz/
# mv upload/* /usr/local/apache/htdocs
# chown -Rf daemon:daemon /usr/local/apache/htdocs
# chmod -Rf 777 /usr/local/apache/htdocs

#调优：nginx、php、Apache隐藏版本号
#sed -i '/sendfile            on;/a\    server_tokens      off;' /usr/local/nginx/conf/nginx.conf
sed -i 's|expose_php = On|expose_php = Off|' /usr/local/php/etc/php.ini 
sed -i 's|#Include conf/extra/httpd-default.conf|Include conf/extra/httpd-default.conf|' /usr/local/apache/conf/httpd.conf
sed -i 's|ServerTokens Full|ServerTokens Prod|' /usr/local/apache/conf/extra/httpd-default.conf
# sed -i '|ServerSignature Off|ServerSignature Off|' /usr/local/apache/conf/extra/httpd-default.conf
systemctl daemon-reload 
systemctl restart php-fpm.service 
systemctl restart httpd.service
firewall-cmd --permanent --zone=public --add-port=3306/tcp --permanent;
firewall-cmd --permanent --query-port=3306/tcp;
firewall-cmd --permanent --zone=public --add-port=80/tcp --permanent;
firewall-cmd --permanent --query-port=80/tcp;
firewall-cmd --reload;
# systemctl restart nginx.service
sleep 5
rm -rf $sourceinstall
reboot


#httpd反代tomcat模块
#sed -i 's|#LoadModule proxy_module modules/mod_proxy.so|LoadModule proxy_module modules/mod_proxy.so|' /usr/local/apache/conf/httpd.conf
#sed -i 's|#LoadModule proxy_connect_module modules/mod_proxy_connect.so|LoadModule proxy_connect_module modules/mod_proxy_connect.so|' /usr/local/apache/conf/httpd.conf
#sed -i 's|#LoadModule proxy_ftp_module modules/mod_proxy_ftp.so|LoadModule proxy_ftp_module modules/mod_proxy_ftp.so|' /usr/local/apache/conf/httpd.conf
#sed -i 's|#LoadModule proxy_http_module modules/mod_proxy_http.so|LoadModule proxy_http_module modules/mod_proxy_http.so|' /usr/local/apache/conf/httpd.conf
#sed -i 's|#LoadModule proxy_fcgi_module modules/mod_proxy_fcgi.so|LoadModule proxy_fcgi_module modules/mod_proxy_fcgi.so|' /usr/local/apache/conf/httpd.conf
#sed -i 's|#LoadModule proxy_scgi_module modules/mod_proxy_scgi.so|LoadModule proxy_scgi_module modules/mod_proxy_scgi.so|' /usr/local/apache/conf/httpd.conf
#sed -i 's|#LoadModule proxy_ajp_module modules/mod_proxy_ajp.so|LoadModule proxy_ajp_module modules/mod_proxy_ajp.so|' /usr/local/apache/conf/httpd.conf
#sed -i 's|#LoadModule proxy_balancer_module modules/mod_proxy_balancer.so|LoadModule proxy_balancer_module modules/mod_proxy_balancer.so|' /usr/local/apache/conf/httpd.conf
#sed -i 's|#LoadModule proxy_express_module modules/mod_proxy_express.so|LoadModule proxy_express_module modules/mod_proxy_express.so|' /usr/local/apache/conf/httpd.conf

#redis 实现：使用 tomcat session manager 方法存储  
#网址：https://github.com/jcoleman/tomcat-redis-session-manager 
#同样修改 tomcat 的 conf 目录下的 context.xml 文件： 
#Valve className="com.radiadesign.catalina.session.RedisSessionHandlerValve"; 
#Manager className="com.radiadesign.catalina.session.RedisSessionManager" 
#         host="localhost" 
#         port="6379" 
#         database="0" 
#         maxInactiveInterval="60"/&gt; 
#以上是以 1.2 版为例子，需要用的 jar 包： 
#tomcat-redis-session-manager-1.2-tomcat-6.jar 
#jedis-2.1.0.jar 
#commons-pool-1.6.jar 


##虚拟主机设置,所有请求反代到tomcat8080
#虚拟主机设置多端口，httpd添加Listen 801
#<VirtualHost *:801>
#  ServerName 192.168.8.50:801
#  ProxyVia On
#  ProxyRequests Off
#  ProxyPreserveHost On

#  <Proxy *>
#    Require all granted
#  </Proxy>
#    ProxyPass / http://192.168.8.50:8080/
#    ProxyPassReverse / http://192.168.8.50:8080/

#  <Location />
#      Require all granted
#  </Location>
#</VirtualHost>

 



# 三、配置nginx服务
#1.nginx的虚拟机是用192.168.130.100的ip地址，监听的端口改为是8080，配置如下
#upstream tomcat {
#            ip_hash;                                #基于ip的 session sticky
#            server 192.168.130.128:80;              #TomcatA
#            server 192.168.130.130:80;              #TomcatB
#}
#server {
#    listen          192.168.130.100:8080;
#    server_name     www.luomaozhang.com;
#    root            /var/www/html;
#    location / {
#            proxy_pass http://tomcat;
#    }
#}

##配置webprox1上的nginx，将动态网页的请求转发至web1，将静态网页的请求转发至web2
# location ~* \.jsp$ {
#   proxy_pass http://172.16.100.101;
# } 
# location / {
#   proxy_pass http://172.16.100.102;
# }


#源码安装 Nginx+LAMP 整合
#先修改 apache 访问端口为 8080，Nginx 端口为 80。
#server 配置段内容如下(把nginx的发布目录指向apache的发布目录）
#(定义 upstream 均衡模块，配置动静分离，动态转发至apache，静态文件直接本地响应)
#upstream app_lamp {
#server 127.0.0.1:8080 weight=1 max_fails=2 fail_timeout=30s;
#}
#server {
#   listen 80;
#   server_name localhost;
#   location / {
#           root /usr/local/apache/htdocs;
#           index index.php index.html index.htm;
#           }
#   location ~ .*\.(php|jsp|cgi)?$ {
#           proxy_set_header Host $host;
#           proxy_set_header X-Real-IP $remote_addr;
#           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
#           proxy_pass http://app_lamp;
#           }
#   location ~ .*\.(html|htm|gif|jpg|jpeg|bmp|png|ico|txt|js|css)$ {
#           root /usr/local/apache/htdocs;
#           expires 3d;
#           }
#}

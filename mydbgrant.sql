ALTER USER 'root'@'localhost' IDENTIFIED BY 'Root123456';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'Root123456' WITH GRANT OPTION;
set names utf8;
FLUSH PRIVILEGES;
UPDATE mysql.user SET authentication_string=PASSWORD('Root123456') WHERE User='root';
set names utf8;
FLUSH PRIVILEGES;
# setup-virtualhost

## Description
The purpose of project is to setup a virtual host block for apache2 in just one bash execution.

## Table of Contents
- [Description](#description)
- [Usage](#usage)
- [Options](#options)
- [License](#license)
- [Credits](#credits)
- [Badges](#badges)

## Usage
To check the usage of the script, run the following command:
```
bash enable_project_apache.sh -p /var/www/html/project -a alias_name
```
```
bash enable_project_apache.sh -p /var/www/html/project -i 127.0.0.1 -po 8080
```
```
bash enable_project_apache.sh -o Indexes FollowSymLinks -l All -r all granted -p /var/www/html/project
```

**The VirtualHost do not will work if the project path doesn't have the necessary permissions.**
To check the permissions of the project, run the following command:
```
ls -ld /path/to/directory
```
> The output should be something like this: `drwxr-xr-x` the important part is the read and execute permissions.

To grant the necessary permissions, run the following command:
```
sudo chmod +x /path/to/directory
```
To enable .htaccess on the project:
- Ubuntu: `sudo a2enmod rewrite`
- Arch: Uncomment the line `LoadModule rewrite_module modules/mod_rewrite.so` in `/etc/httpd/conf/httpd.conf`

## Options
```
-w  | --overwrite: Overwrite the conf file if it already exists.
-i  | --ip: The ip address of the virtual host.
-p  | --path: The path of the project.
-po | --port: The port of the virtual host.
-a  | --alias: The alias of the virtual host.
-o  | --options: The options of the virtual host.
-l  | --allow-override: The allow override of the virtual host.
-r  | --require: The require of the virtual host.
-e  | --error-log: The error log of the virtual host.
-c  | --custom-log: The custom log of the virtual host.
-cp | --custom-log-path: The custom log path of the virtual host.
  The default paths are:
    - Linux(linux-gnu): /etc/apache2/apache2.conf
    - MacOS(darwin): /usr/local/etc/httpd/httpd.conf
```

## License
This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.
``

## Credits
- [StackOverflow Post Visited](/Bibliography/stackoverflowPosts.md)
- [Web Page Visited](/Bibliography/webPages.md)

## Badges
![Shell Script](https://img.shields.io/badge/shell_script-%23121011.svg?style=for-the-badge&logo=gnu-bash&logoColor=white)
![Apache](https://img.shields.io/badge/apache-%23D42029.svg?style=for-the-badge&logo=apache&logoColor=white)

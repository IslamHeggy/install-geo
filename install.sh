#!/bin/bash
 
#This shell script installs a bunch of applications.
#Comment and uncomment the functions according to your need.
 
 
#vars
sources_dir=/opt/sources #directory to contain source files downloaded.
inst_dir=/opt #installation directory.

tomcat_url="" #tomcat download url.

geo_url="" #geo server war download url.

yum_packages="wget unzip net-tools telnet" #packages needed for the installation to be installed by yum.

elastic_url="" #elastic search download url.
kibana_url="" #kibana download url.

postgres_url="" #postgresql download url.
postgres_packages="postgresql96 postgresql96-server postgresql96-contrib postgresql96-libs" #packages needed for the postgresql installation.

elastic_stack_key="" #elastic search key.
 
common()
{
 
        echo "Creating sources directory...."
        mkdir $sources_dir
 
        echo "Installing common packages...."
        yum install $yum_packages -y
 
        firewall_ports="80/tcp 443/tcp 5601/tcp 9200/tcp 8080/tcp 5432/tcp"
 
        for i in $firewall_ports; do
                firewall-cmd --permanent --add-port="$i"
        done
        firewall-cmd --reload
 
}

install_java()
{
 
        echo "Installing Java...."
        sudo yum install java-1.8.0-openjdk java-1.8.0-openjdk-devel -y
 
}

 
download_geo()
{
        echo "Downloading Geo Server war...."
        wget $geo_url -P $sources_dir
 
        geo_zip=$(basename $geo_url)
 
        echo "Copying geo server to the installation directory...."
 
        cp "$sources_dir/$geo_zip" $inst_dir/tomcat/webapps/
 
        echo "Deploying geo war...."
        unzip $inst_dir/tomcat/webapps/$geo_zip -d $inst_dir/tomcat/webapps/
}

install_tomcat()
{
 
        echo "Downloading apache tomcat...."
        wget $tomcat_url -P $sources_dir
 
        tomcat_tar=$(basename $tomcat_url)
 
        echo "Copying tomcat to the installation directory...."
        cp "$sources_dir/$tomcat_tar" $inst_dir
 
        mkdir $inst_dir/tomcat
        tar -xvf "$inst_dir/$tomcat_tar" -C $inst_dir/tomcat --strip-components=1
 
        echo "Creating tomcat user and group...."
        groupadd tomcat
        useradd -M -s /bin/nologin -g tomcat -d $inst_dir/tomcat tomcat

        echo "Creating tomcat service file....."
       
        cat > /etc/systemd/system/tomcat.service <<-EOL 

        [Unit]
        Description=Apache Tomcat Web Application Container
        After=syslog.target network.target
         
        [Service]
        Type=forking
         
        Environment=JAVA_HOME=/usr/lib/jvm/jre-openjdk/
        Environment=CATALINA_PID=$inst_dir/tomcat/temp/tomcat.pid
         
        Environment=CATALINA_HOME=$inst_dir/tomcat
        Environment=CATALINA_BASE=$inst_dir/tomcat
        Environment='CATALINA_OPTS=-Xms512M -Xmx6G -server -XX:+UseParallelGC'
        Environment='JAVA_OPTS=-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom'
         
        ExecStart=$inst_dir/tomcat/bin/startup.sh
        ExecStop=/bin/kill -15 $MAINPID
         
        User=tomcat
        Group=tomcat
        Restart=always
         
        [Install]
        WantedBy=multi-user.target

	EOL
	
	    chown tomcat:tomcat $inst_dir/tomcat -R
        
        echo "reloading systemd configuration...."
        systemctl daemon-reload
        echo "Starting tomcat service...."
        systemctl start tomcat.service
        echo "Enabling tomcat service...."
        systemctl enable tomcat.service
 
}
  
install_postgresql()
{
        echo "Installing postgresql...."
        yum install $postgres_url -y
        yum install $postgres_packages -y

        /usr/pgsql-9.6/bin/postgresql96-setup initdb
       
        echo "Enabling postgresql service...."
        systemctl enable postgresql-9.6.service
        echo "Starting postgresql service...."
        systemctl start postgresql-9.6.service
        
}
 
install_postgis()
{  
        echo "Installing postgis...."
        yum install postgis2_96 -y
}

install_nginx()
{
        echo "Installing nginx...."
        yum install nginx  -y
        echo "Starting nginx service...."
        systemctl start nginx
        echo "Enabling nginx service...."
        systemctl enable nginx
}
 
install_elastic_search()
{
        rpm --import $elastic_stack_key
        wget $elastic_url -P $sources_dir

        echo "Installing elastic search...."
        yum localinstall $sources_dir/$(basename $elastic_url) -y
        
        echo "reloading systemd configuration...."
        systemctl daemon-reload
        echo "Enabling elastic search service...."
        systemctl enable elasticsearch.service
        echo "Starting elastic search service...."
        systemctl start elasticsearch.service 
}

install_kibana()
{
 
        rpm --import $elastic_stack_key
        wget $kibana_url -P $sources_dir

        yum localinstall $sources_dir/$(basename $kibana_url) -y
        
        echo "reloading systemd configuration...."
        systemctl daemon-reload
        echo "Enabling kibana search service...."
        systemctl enable kibana.service
        echo "Starting kibana service...."
        systemctl start kibana.service
}

###
# Main body of script starts here
###

#common
#install_java
#install_tomcat
download_geo
#install_postgresql
#install_elastic_search
#install_kibana
#install_nginx


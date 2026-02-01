#!/bin/bash

USERID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"
SCRIPT_DIR=$PWD
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

if [ $USERID -ne 0 ]; then
    echo -e "$R Please run this script with root user access $N" | tee -a $LOGS_FILE
    exit 1
fi

mkdir -p $LOGS_FOLDER

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e "$2 ... $R FAILURE $N" | tee -a $LOGS_FILE
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N" | tee -a $LOGS_FILE
    fi
}

dnf module disable nginx -y
VALIDATE $? "Disable Nginx"

dnf module enable nginx:1.24 -y
VALIDATE $? "Enabled Nginx 1.24"

dnf install nginx -y
VALIDATE $? "Installing Nginx"

systemctl enable nginx 
systemctl start nginx 
VALIDATE $? "Enabled and started Nginx"

rm -rf /usr/share/nginx/html/*
VALIDATE $? "Removing existing index.html file"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip
VALIDATE $? "Downloading front end configuration"

cd /usr/share/nginx/html 
VALIDATE $? "Changing directory to /usr/share/nginx/html"

unzip /tmp/frontend.zip
VALIDATE $? "unzip front end configuration"

cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf
VALIDATE $? "Copying nginx config"

systemctl restart nginx 
VALIDATE $? "Restarted Nginx"



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

dnf install maven -y
VALIDATE $? "Installing maven"

id roboshop &>>$LOGS_FILE
if [ $? -ne 0 ]; then
  useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOGS_FILE
  VALIDATE $? "creating roboshop user"
else
echo -e "Roboshop user already exists .... $Y SKIPPING $N"
fi

mkdir -p /app
VALIDATE $? "Creating app directory"

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip 
VALIDATE $? "Downloading shipping code"

cd /app 
VALIDATE $? "Change directory to /app"

rm -rf /app/*
VALIDATE $? "removing if there is code exists"

unzip /tmp/shipping.zip
VALIDATE $? "Unziping code into /app"

mvn clean package 
VALIDATE $? "packaging"

mv target/shipping-1.0.jar shipping.jar 
VALIDATE $? "renaming and moving to /app"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service
VALIDATE $? "copying shipping.service file"

systemctl daemon-reload
systemctl enable shipping 
systemctl start shipping
VALIDATE $? "Enabled and started shipping service"

dnf install mysql -y 
VALIDATE $? "Installing mysql client"

mysql -h mysql.ramireddy.co.in -uroot -pRoboShop@1 < /app/db/schema.sql
VALIDATE $? "Loading schema in to db"

mysql -h mysql.ramireddy.co.in -uroot -pRoboShop@1 < /app/db/app-user.sql 
VALIDATE $? "Create app user in mysql db"

mysql -h mysql.ramireddy.co.in -uroot -pRoboShop@1 < /app/db/master-data.sql
VALIDATE $? "Loading master data in to db"

systemctl restart shipping
VALIDATE $? "restarting shipping service"

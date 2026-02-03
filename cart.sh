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

source ./common-script.sh

dnf module disable nodejs -y &>>$LOGS_FILE
VALIDATE $? "Disable nodejs"

dnf module enable nodejs:20 -y &>>$LOGS_FILE
VALIDATE $? "Enable nodejs 20"

dnf install nodejs -y
VALIDATE $? "Installing nodejs" &>>$LOGS_FILE

id roboshop &>>$LOGS_FILE
if [ $? -ne 0 ]; then
  useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOGS_FILE
  VALIDATE $? "creating roboshop user"
else
echo -e "Roboshop user already exists .... $Y SKIPPING $N"
fi

mkdir -p /app &>>$LOGS_FILE

curl -L -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip &>>$LOGS_FILE
VALIDATE $? "Downloading cart code"

cd /app 
VALIDATE $? "Changing directory to /app"

rm -rf /app/*
VALIDATE $? "removing if there is any existing code"

unzip /tmp/cart.zip &>>$LOGS_FILE
VALIDATE $? "Unzipping code to /app"

npm install &>>$LOGS_FILE
VALIDATE $? "installing npm"

cp $SCRIPT_DIR/cart.service /etc/systemd/system/cart.service

systemctl daemon-reload
systemctl enable cart 
systemctl start cart
VALIDATE $? "Enables and started cart service"




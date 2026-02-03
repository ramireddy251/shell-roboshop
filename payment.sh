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


dnf install python3 gcc python3-devel -y &>>$LOGS_FILE
VALIDATE $? "Installing python3"

id roboshop &>>$LOGS_FILE
if [ $? -ne 0 ]; then
  useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOGS_FILE
  VALIDATE $? "creating roboshop user"
else
echo -e "Roboshop user already exists .... $Y SKIPPING $N"
fi

mkdir -p /app &>>$LOGS_FILE
VALIDATE $? "created app directory"

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>>$LOGS_FILE
VALIDATE $? "Downloading payment code"

cd /app &>>$LOGS_FILE
VALIDATE $? "Changed directory to /app"

rm -rf /app/* &>>$LOGS_FILE
VALIDATE $? "removing if there is code exists"

unzip /tmp/payment.zip &>>$LOGS_FILE
VALIDATE $? "Unziping code"

pip3 install -r requirements.txt &>>$LOGS_FILE
VALIDATE $? "installing requirements.txt"

cp $SCRIPT_DIR/payment.service /etc/systemd/system/payment.service &>>$LOGS_FILE

systemctl daemon-reload
systemctl enable payment 
systemctl start payment
VALIDATE $? "Enabled and started payment service"

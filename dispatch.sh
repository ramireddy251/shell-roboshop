#!/bin/bash

USERID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"
SCRIPT_DIR=$PWD
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

# if [ $USERID -ne 0 ]; then
#     echo -e "$R Please run this script with root user access $N" | tee -a $LOGS_FILE
#     exit 1
# fi

# mkdir -p $LOGS_FOLDER

# VALIDATE(){
#     if [ $1 -ne 0 ]; then
#         echo -e "$2 ... $R FAILURE $N" | tee -a $LOGS_FILE
#         exit 1
#     else
#         echo -e "$2 ... $G SUCCESS $N" | tee -a $LOGS_FILE
#     fi
# }

source ./common-script.sh

dnf install golang -y &>>$LOGS_FILE
VALIDATE $? "Installing golang"

id roboshop &>>$LOGS_FILE
if [ $? -ne 0 ]; then
  useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOGS_FILE
  VALIDATE $? "creating roboshop user"
else
echo -e "Roboshop user already exists .... $Y SKIPPING $N"
fi

mkdir -p /app &>>$LOGS_FILE
VALIDATE $? "Creating app directory"

curl -L -o /tmp/dispatch.zip https://roboshop-artifacts.s3.amazonaws.com/dispatch-v3.zip &>>$LOGS_FILE
VALIDATE $? "Downloading dispatch code"

cd /app &>>$LOGS_FILE
VALIDATE $? "Changing directory to /app"

rm -rf /app/* &>>$LOGS_FILE
VALIDATE $? "Removing if code exists"

unzip /tmp/dispatch.zip &>>$LOGS_FILE
VALIDATE $? "Unziping code"

go mod init dispatch &>>$LOGS_FILE
VALIDATE $? "init go"

go get &>>$LOGS_FILE
VALIDATE $? "get go"

go build &>>$LOGS_FILE
VALIDATE $? "Build go"

cp $SCRIPT_DIR/dispatch.service /etc/systemd/system/dispatch.service &>>$LOGS_FILE

systemctl daemon-reload
systemctl enable dispatch 
systemctl start dispatch
VALIDATE $? "Enabled and started dispatch service"
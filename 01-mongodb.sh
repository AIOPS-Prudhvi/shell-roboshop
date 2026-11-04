#!/bin/bash

LOGS_FOLDER=/home/ec2-user/var/log/roboshop
sudo mkdir -p $LOGS_FOLDER
sudo chown ec2-user:ec2-user $LOGS_FOLDER
sudo chmod 755 $LOGS_FOLDER

LOG_FILE="$LOGS_FOLDER/$0.log"

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
if [ $USERID -ne 0 ]; then
    echo -e " $TIMESTAMP [ERROR] $R This script must be run as root $N" | tee -a $LOG_FILE
    exit 1
fi

VALIDATE() {
    if [ $1 -ne 0 ]; then
        echo -e " $TIMESTAMP [ERROR] $R $2 is ..... FAILED $N" | tee -a $LOG_FILE
        exit 1

    else
        echo -e " $TIMESTAMP [INFO] $G $2 is ....... SUCCESS $N" | tee -a $LOG_FILE    
    fi
}

cp mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Copying mongo.repo"

dnf install mongodb-org -y &>> $LOG_FILE
VALIDATE $? "Installing MongoDB" 

systemctl enable --now mongod &>> $LOG_FILE
VALIDATE $? "Starting and Enabling MongoDB"

sed -i 's/127.0.0.0/0.0.0.0/g' /etc/mongod.conf
VALIDATE $? "Updating MongoDB config file"

systemctl restart mongod &>> $LOG_FILE
VALIDATE $? "Restarting MongoDB"
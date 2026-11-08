#!/bin/bash

LOGS_FOLDER=/home/ec2-user/var/log/shell-script
sudo mkdir -p $LOGS_FOLDER
sudo chown ec2-user:ec2-user $LOGS_FOLDER
sudo chmod 755 $LOGS_FOLDER
LOG_FILE="$LOGS_FOLDER/$0.log"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
R="\e[31m"
G="\e[32m"  
Y="\e[33m"
N="\e[0m"

if [ $(id -u) -ne 0 ]; then
    echo -e "$TIMESTAMP [ERROR] $R Run this script as a root user or sudo user $N" | tee -a $LOG_FILE
    exit 1
fi

VALIDATE() {
    if [ $1 -ne 0 ]; then
        echo -e "$TIMESTAMP [ERROR] $R $2 IS ...FAILED $N" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$TIMESTAMP [INFO] $G $2 IS ...SUCCESS $N" | tee -a $LOG_FILE
    fi
}

dnf install mysql-server -y | tee -a $LOG_FILE
VALIDATE $? "Installing MySQL Server"

systemctl enable mysqld | tee -a $LOG_FILE
VALIDATE $? "Enabling MySQL Service"

systemctl start mysqld | tee -a $LOG_FILE
VALIDATE $? "Starting MySQL Service"


mysql_secure_installation --set-root-pass RoboShop@1 | tee -a $LOG_FILE
VALIDATE $? "Securing MySQL Installation"
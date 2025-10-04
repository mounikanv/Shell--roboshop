#!/bin/bash

#-----1-----
USERID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

logs_folder="/var/log/roboshop"
script_name=$(echo $0 | cut -d "." -f1) 
log_file="$logs_folder/$script_name.log"

mkdir -p $logs_folder

pwd=$PWD


#checks user id
if [ $USERID -eq 0 ]

then 
   echo -e "$G User has root access " | tee -a $log_file
else
   echo -e "$R User doesn't have root access " | tee -a $log_file
   exit 1
fi


VALID() {
if [ $1 -eq 0 ]
then
    echo -e "$N $2 is ....$G Successful" | tee -a $log_file
else
    echo -e "$N $2 is ....$R Failure" | tee -a $log_file
    exit 1
fi 
}

dnf module disable nodejs -y &>>$log_file
VALID $? "Disabling nodejs"

dnf module enable nodejs:20 -y &>>$log_file
VALID $? "Enabling nodejs"

dnf install nodejs -y &>>$log_file &>>$log_file
VALID $? "Installing nodejs"

id roboshop
if [ $? -ne 0 ]
then 
useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$log_file
else 
echo "User already exists"
fi
VALID $? "Adding User" 

mkdir -p /app  &>>$log_file
VALID $? "Creating Directory"

curl -L -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip
VALID $? "Downloading Zipfile"

rm -rf /app/*
cd /app  &>>$log_file
unzip /tmp/cart.zip &>>$log_file
VALID $? "Unzipping into directory" 

npm install &>>$log_file
VALID $? "Installing dependencies"

cp $pwd/cart.service /etc/systemd/system/cart.service &>>$log_file
VALID $? "Copying service"

systemctl daemon-reload &>>$log_file
VALID $? "Reloading"

systemctl enable cart  &>>$log_file
VALID $? "Enabling Cart"

systemctl start cart &>>$log_file
VALID $? "Starting cart" 


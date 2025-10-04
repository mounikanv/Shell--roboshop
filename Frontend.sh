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

pwd=$PWD

mkdir -p $logs_folder

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

dnf module disable nginx -y &>>$log_file
VALID $? "Disabling nginx"

dnf module enable nginx:1.24 -y &>>$log_file
VALID $? "Enabling nginx version 1.24"

dnf install nginx -y  &>>$log_file 
VALID $? "Installing nginx"

systemctl enable nginx  &>>$log_file 
VALID $? "Enabling nginx"

systemctl start nginx  
VALID $? "Starting nginx"

rm -rf /usr/share/nginx/html/* 
VALID $? "Removing default content"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$log_file
VALID $? "Downloading nginx"

cd /usr/share/nginx/html 
unzip /tmp/frontend.zip
VALID $? "Loading Roboshop content"

rm -rf /etc/nginx/nginx.conf &>>$log_file
VALID $? "Remove default nginx conf"

cp $pwd/nginx.conf /etc/nginx/nginx.conf
VALID $? "Copying Configrations"

systemctl restart nginx &>>$log_file
VALID $? "Restarting nginx"
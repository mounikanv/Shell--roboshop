#!/bin/bash

#-----1-----
USERID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

log_folder="/var/log/roboshop"
script_name=$(echo $0 | cut -d "." -f1) 
log_file="$log_folder/$script_name.log"

mkdir -p $log_folder

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
echo -e "User already exists....$Y Skipping $N"
fi


mkdir -p /app  &>>$log_file
VALID $? "Creating Directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip  &>>$log_file
VALID $? "Downloading Zipfile"

rm -rf /app/*
cd /app  &>>$log_file
unzip /tmp/catalogue.zip &>>$log_file
VALID $? "Unzipping into directory" 

npm install &>>$log_file
VALID $? "Installing nodepackage manager"

cp $pwd/catalogue.service /etc/systemd/system/catalogue.service &>>$log_file
VALID $? "Copying service"

systemctl daemon-reload &>>$log_file
systemctl enable catalogue  &>>$log_file
systemctl start catalogue &>>$log_file
VALID $? "Starting catalogue" 

cp $pwd/mongo.repo /etc/yum.repos.d/mongo.repo &>>$log_file
VALID $? "copying mongo repos"

dnf install mongodb-mongosh -y &>>$log_file
VALID $? "Installing Mongo Client"

STATUS=$(mongosh --host mongodb.mounika.site --eval 'db.getMongo().getDBNames().indexOf("catalogue")')
if [ $STATUS -lt 0 ]
then
   mongosh --host mongodb.mounika.site</app/db/master-data.js &>>$log_file
VALID $? "Loading master data to site"
else
    echo -e "Data is already loaded ... $Y SKIPPING $N"
fi

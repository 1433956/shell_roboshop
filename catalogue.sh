#!/bin/bash
userid=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

Log_Folder="/var/log/catalogue-logs"
Script_Name=$(echo $0 | cut -d "." -f1)
LOG_FILE="$Log_Folder/$Script_Name.log"
mkdir -p $Log_Folder
SCRIPT_DIR=$PWD

echo "Catlog script is started executing at :: $(date)" | tee -a $LOG_FILE

if [ $userid -ne 0 ]
then
    echo -e "$R please log as Root user $N" | tee -a $LOG_FILE
    exit 1
else
    echo -e "$G Logged as a root User $N" | tee -a $LOG_FILE
f1

#validate functions takes input as exit status, what command they tried to install

 VALIDATE(){
    if [ $1 -eq 0 ]
    then

       echo -e " $2 is ... $G SUCCESS $N" | tee -a $LOG_FILE
    else
        echo -e "$2 is .. $R Failure $N" | tee -a $LOG_FILE
        exit 1
    fi
}

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disabling default nodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "enabling nodejs version: 20"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "installing nodejs"

id roboshop
  if [ $? -ne 0 ]
  then
      useradd --system --home /app --shell /sbin/nologin --comment "creating system user" roboshop
      VALIDATE $? "Creating roboshop system user"
  else
       echo -e"System user roboshop already created ... $Y SKIPPING $N"
  fi


mkdir -p /app
VALIDATE $? "Creating app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading Catalogue"

rm -rf /app/*
cd /app
unzip /tmp/catalogue.zip &>>$LOG_FILE
VALIDATE $? "unzipping catalogue folder"
 
 npm install

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "Copying catalogue service"

systemctl daemon-reload &>>$LOG_FILE
systemctl enable catalogue  &>>$LOG_FILE
systemctl start catalogue
VALIDATE $? "Starting Catalogue"
 cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongod.repo

 dnf install mongodb-mongosh -y &>>$LOG_FILE
 VALIDATE $? "Installing MongoDB Client"
 STATUS=$(mongosh --host mongodb.devops73.site --eval 'db.getMongo().getDBNames().indexOf("catalogue")')
  if [ $STATUS -lt 0 ]
  then
     mongosh --host mongodb.daws84s.site </app/db/master-data.js &>>$LOG_FILE
     VALIDATE $? "Loading data into MongoDB"

  else
      echo -e "Data is already loaded ... $Y SKIPPING $N"
  fi
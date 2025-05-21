#!/bin/bash
userid=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
Log_Folder="/var/logs/catalogue-logs"
Script_Name=$(echo $0 | cut -d "." -f1)
Log_File="$Log_Folder/$Script_Name.log"
SYS_DIR=$PWD
echo -e "$Y script is started at=$(date) $N"

mkdir -p $Log_Folder

if [ $userid -ne 0 ]
then 
    echo -e "$R please log as a root user $N" &>>$Log_File
    exit 1
else
    echo -e "$G logged as a root user $N" &>>$Log_File
fi 

VALIDATE() {
    if [ $1 -eq 0 ]
    then
        echo -e "$2.. $G success $N" | tee -a $Log_File
    else
        echo -e "$2.. $R failed $N" | tee -a $Log_File
        exit 1
    fi
}

dnf module disable nodejs -y &>>$Log_File
VALIDATE $? "disabling nodejs "

dnf module enable nodejs:20 -y &>>$Log_File
VALIDATE $? "enabling nodejs version:20 "

dnf install nodejs -y &>>$Log_File
VALIDATE $? "installing nodejs"

#create system user 
 
id roboshop
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$Log_File
    VALIDATE $? "Creating roboshop system user"
else
    echo -e "System user roboshop already created ... $Y SKIPPING $N"
fi
mkdir -p /app 

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$Log_File
VALIDATE $? " downloading catalogue project "

rm -rf /app/* &>>$Log_File
 cd /app

if [ $? -eq 0 ]
then
    echo -e"$G unzipping the catalogue project $N" 
    unzip /tmp/catalogue.zip &>>$Log_File
else
     echo -e "$Y ALready extracted $N"
fi

npm install  &>>$Log_File
VALIDATE $? "installing nodejs dependcies"

cp $SYS_DIR/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "catalogue service is created"

systemctl daemon-reload &>> $Log_File
VALIDATE $? "reloading catalogue service"

systemctl enable catalogue &>> $Log_File
VALIDATE $? "enabling catalogue service"

systemctl start catalogue 
VALIDATE $? "starting catalogue service"

# MongoDB

cp $SYS_DIR/mongo.repo /etc/yum.repos.d/mongo.repo &>>$Log_File

mongodb-mongosh -V &>>$LOG_FILE

if [ $? -ne 0]
then
     echo -e "$Y mongodb is not installed $N" &>>$Log_File
     dnf install mongodb-mongosh -y &>>$Log_File
else
     echo -e"$G Mongodb is already installed $N" &>>$Log_File
fi
STATUS=$(mongosh --host mongodb.daws84s.site --eval 'db.getMongo().getDBNames().indexOf("catalogue")')

if [ $STATUS -lt 0]
then
    mongosh --host mongodb.devops73.site </app/db/master-data.js &>>$Log_File
    VALIDATE $? "Loading data into MongoDB"
else
    echo -e "Data is already loaded ... $Y SKIPPING $N"
fi
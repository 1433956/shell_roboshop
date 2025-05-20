#!/bin/bash
userid=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
 Log_Folder="/var/log/mongodb-logs"
 Script_Name=$(echo $0 | cut -d "." -f1)
 LOG_FILE="$Log_Folder/$Script_Name.log"

 mkdir -p $Log_Folder

 echo -e "$G script is execution started at:$(date) $N" | tee -a $LOG_FILE

 #check user has root privilages 
if [ $userid -ne 0]
then
     echo -e "$R ERROR:: Please run this script with root access $N" | tee -a $LOG_FILE
     exit 1
else 
     echo -e "$G You are running with root access $N" &>>$LOG_FILE

fi

# validate functions takes input as exit status, what command they tried to install
$VALIDATE() {
    if [ $1 -eq 0 ]
    then
        echo -e "$2  is ... $G SUCCESS $N" | tee -a $LOG_FILE
    else
        echo -e "$2 is ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    fi
}

cp mongo.repo /etc/yum.repos.d/mongod.repo
VALIDATE $? "Copying MongoDB repo"

dnf install mongodb-org -y &>>$LOG_FILE
VALIDATE $? "Installing mongodb server"

systemctl enable mongod
VALIDATE $? "Enabling MongoDB" &>>$LOG_FILE

systemctl start mongod 
VALIDATE $? "Starting MongoDB" &>>$LOG_FILE

 sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
 VALIDATE $? "Editing MongoDB conf file for remote connections"

systemctl restart mongod &>>$LOG_FILE
VALIDATE $? "Restarting MongoDB"

from confluent_kafka import Consumer, KafkaError
import base64
from project import http_requests
from project.utilities import init_participants_dict,run_time_minutes,run_time_minutes_from,marking_frame_box,commit_attendance_results,final_attendance_results
from project.pretrained_models.model_methods import realtime,prepare_model,regconition_model
import numpy as np
from datetime import datetime
import argparse
import os
import yaml
import json
import io
from PIL import Image
from project.clog import clog
from logging import Logger
def get_cusom_Path_from_here(filename):
    #type: (str)->str
    thisLocationFolder=os.path.dirname(os.path.abspath(__file__))
    if filename!="":return os.path.join(thisLocationFolder,filename)
    return thisLocationFolder

def main(kafkaHost,apiHost,kafkaTopic,account,classId,logger):
    #type: (str,str,str,dict,int,Logger) -> None
    kafka_config = {
        'bootstrap.servers': kafkaHost,
        'group.id': '1',
        'auto.offset.reset': 'earliest'
    }

    # Create Consumer instance
    class_id=classId
    host="localhost:8080" if apiHost==None else apiHost
    consumer = Consumer(kafka_config)
    # Subscribe to topic
    topic = kafkaTopic
    consumer.subscribe([topic])
    account=yaml.safe_load(open(account))
    token=http_requests.authenticate(account.get("username",""),account.get("password",""),host).get("token","")
    
    class_start_time,class_end_time=http_requests.extract_class_timestamps(http_requests.getClass(class_id=class_id,token=token,host=host))
    class_duration=(class_end_time-class_start_time).seconds/60
    raw_response,class_members=http_requests.getClassMembers_name(class_id=class_id,token=token,host=host)
    
    logger.debug(f"Basic Run Info:\nAccount: {account}\nKafka_config: {kafka_config}\nClass id: {class_id}, Class_Start: {class_start_time}, Class_End: {class_end_time}\nMembers_info: {raw_response}")
    yolo_model,facenet,svm_model,encoder=prepare_model()
    
    participants_dict=init_participants_dict(class_members)
    
    usual_run=False
    runtime=0
    while runtime<class_duration:
        msg = consumer.poll(timeout=1.0)
        if msg is None:
            continue
        if msg.error():
            if msg.error().code() == KafkaError._PARTITION_EOF:
                # End of partition
                logger.warning(f"Reached end of partition {msg.topic()} [{msg.partition()}]")
                break
            else:
                logger.warning(f"Error: {msg.error()}")
                break
        # Decode the base64-encoded image data
        raw= json.loads(msg.value())
        logger.debug(f"Receving from kafka: {raw}")
        images_encoded_array=raw.get("data",[])
        timestamp=raw.get("timestamp",0)
        if timestamp<class_start_time.timestamp():
            continue
        if runtime==0 and timestamp>class_end_time.timestamp():
            break
        usual_run=True
        images_decoded_array=[]
        for img in images_encoded_array:
            decoded_string = base64.b64decode(img)
            raw_image = Image.open(io.BytesIO(decoded_string))
            decoded_image = np.array(raw_image)
            images_decoded_array.append(decoded_image)
        results=regconition_model(images_decoded_array,facenet,svm_model,encoder)
        time_elapsed=run_time_minutes_from(timestamp,class_start_time.timestamp())-runtime
        runtime=run_time_minutes_from(timestamp,class_start_time.timestamp())
        commit_attendance_results(results,participants_dict,time_elapsed)
    
    if usual_run:
        final_attendance_results(participants_dict,class_duration)
        # print(participants_dict)
        for key,value in participants_dict.items():
            participants_id=raw_response[key]
            # print(f"{participants_id}   {class_id}")
            status=http_requests._update_class_attendance(value,participants_id,class_id,token,host)
            logger.debug(f"Successfully updated attendance status for {key}") if status else logger.warning(f"updated attendance status for {key} failed !")
            
    # Leave group and commit final offsets
    logger.debug("It's a usual Run. Commitments have been made !") if usual_run else logger.warning("It's a UNUSUAL Run. No Commitment have been made !")
    consumer.close()
        
# NEED TO WRITE SOME ARGPARSER AND IF __NAME__ HERE !!!!!!

if __name__ == "__main__":
    argparse=argparse.ArgumentParser("Options to run script.")
    argparse.add_argument("--kafka_host",help="The host address of kafka broker to get images from.",type=str,default="192.168.120.46:9092")
    argparse.add_argument("--kafka_topic",help="The topic to get data from kafka broker.",type=str,default="test")
    default_account_path=get_cusom_Path_from_here(os.path.join("account","admin.yaml"))
    argparse.add_argument("--account",help=f"(OPTIONAL) The yaml file of the managemant account to run this script. The default account will be located at {default_account_path}.",type=str,default=default_account_path)
    argparse.add_argument("--api_host",help=f"(OPTIONAL) The host address of api server to make http request. The default host will be 'localhost:8080'",type=str,default="localhost:8080")
    argparse.add_argument("--class_id",help=f"The class id to run this script on.",default=1)
    default_logging_path=get_cusom_Path_from_here(os.path.join("logs","default_log.log"))
    argparse.add_argument("--log",help=f"(OPTIONAL) Set the logging file directory. The default directory is {default_logging_path}",default=default_logging_path)
    log=clog("default_log",default_logging_path).setup_logger()
    args=argparse.parse_args()
    main(kafkaHost=args.kafka_host,apiHost=args.api_host,kafkaTopic=args.kafka_topic,account=args.account,classId=args.class_id,logger=log)
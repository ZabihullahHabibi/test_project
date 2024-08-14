import json
import boto3
import os


client = boto3.client('sns')
         
def lambda_handler(event, context):
   try:  
      
      topic_arn = os.environ.get('TOPIC_ARN')
      one = "One"
      two = 2
      totale = sum(one, two)
      return totale
   except TypeError:
      
      client.publish(TopicArn=topic_arn,Message="type error ")
        

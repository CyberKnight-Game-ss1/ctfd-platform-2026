# wsl_identity_check.py — verify danh tính AWS từ phía WSL (boto3 apt)
# Chỉ in Account/Arn, KHÔNG in credentials. File tiện ích cho agent.
import boto3

i = boto3.Session().client("sts").get_caller_identity()
print("WSL_IDENTITY_ACCOUNT:", i["Account"])
print("WSL_IDENTITY_ARN:", i["Arn"])

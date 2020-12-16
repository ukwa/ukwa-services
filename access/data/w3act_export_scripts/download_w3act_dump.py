import urllib.request
import zipfile

urllib.request.urlretrieve("http://hdfs.api.wa.bl.uk/webhdfs/v1/9_processing/w3act/w3act-db-csv.zip?user.name=access&op=OPEN", "w3act-db-csv.zip")

with zipfile.ZipFile("w3act-db-csv.zip", 'r') as zip_ref:
    zip_ref.extractall(".")

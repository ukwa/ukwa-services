

useradd -u 50000 -G docker airflow

DockerOperator work fine but must return 1 on errors to get picked up. Presumably stderr gets logged and stdout is for XCom and should return JSON.


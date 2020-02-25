FROM  python:3-alpine

COPY requirements.txt /tmp/requirements.txt
RUN  pip install -r /tmp/requirements.txt

COPY tests /tests

# Setup as environment viariable:
ENV HOST=http://www.webarchive.org.uk/

ENTRYPOINT [ "robot" ]


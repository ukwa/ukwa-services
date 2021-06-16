import os
import re
import shutil
import logging
from argparse import ArgumentParser
from prometheus_client import CollectorRegistry, Gauge, push_to_gateway

logger = logging.getLogger(__name__)

def send_metrics(metrics):

    registry = CollectorRegistry()

    g = Gauge('ukwa_files_moved_total_count',
                'Total number of files moved by this task.',
                labelnames=['kind'], registry=registry)
    g.labels(kind='warcprox-warcs').set(metrics['total_moved'])

    if os.environ.get("PUSH_GATEWAY"):
        push_to_gateway(os.environ.get("PUSH_GATEWAY"), job=task.get_task_family(), registry=registry)
    else:
        logger.error("No metrics gateway configured!")


def main():
    parser = ArgumentParser(prog='warcprox-warc-mv')
    parser.add_argument('prefix', 
        help="The location of the root of the crawler storage.", 
        default="/mnt/gluster/fc")
    args = parser.parse_args()
    print("Scanning %s..." % args.prefix)

    metrics = { 
        'total_moved': 0
    }

    # Expected filenaming:
    p = re.compile("BL-....-WEBRENDER-([a-z\-0-9]+)-([0-9]{14})-([a-z\-0-9]+)\.warc\.gz")
    # List all matching files in source directory:
    webrender_path = os.path.join(args.prefix, 'heritrix/wren/')
    for file_path in os.listdir(webrender_path):
        if file_path.endswith('.warc.gz'):
            file_name = os.path.basename(file_path)
            matches = p.search(file_name)
            if matches:
                destination_folder_path = "%s/heritrix/output/%s/%s/warcs" %( args.prefix, matches.group(1), matches.group(2))
                if not os.path.exists(destination_folder_path):
                    raise Exception("Expected destination folder does not exist! :: %s" % destination_folder_path)
                if not os.path.isdir(destination_folder_path):
                    raise Exception("Expected destination folder is not a folder! :: %s" % destination_folder_path)
                source_file_path = os.path.join(webrender_path, file_name)
                destination_file_path = os.path.join(destination_folder_path, file_name)
                if os.path.exists(destination_file_path):
                   raise Exception("Destination file already exists! :: %s" % destination_file_path)
                logger.info("Moving %s to %s..." %( source_file_path, destination_file_path ))
                shutil.move( source_file_path, destination_file_path )
                metrics['total_moved'] += 1

    # Update metrics
    send_metrics(metrics)


if __name__ == '__main__':
    main()

-- migrate:up

CREATE TABLE documents_found (
	document_url VARCHAR(4096) PRIMARY KEY,
	title TEXT,
	filename VARCHAR(1024) NOT NULL,
	landing_page_url VARCHAR(4096) NOT NULL,
	source VARCHAR(4096) NOT NULL,
	wayback_timestamp VARCHAR(14) NOT NULL,
	launch_id VARCHAR(255),
	job_name VARCHAR(255) NOT NULL,
	size INTEGER NOT NULL,
	target_id INTEGER,
	status VARCHAR(255) NOT NULL
);

-- migrate:down

DROP TABLE documents_found;
-- Add FQN and UUID to data_quality_data_time_series records
UPDATE data_quality_data_time_series dqdts
INNER JOIN test_case tc ON dqdts.entityFQNHash = tc.fqnHash
SET dqdts.json = JSON_SET(dqdts.json,
	'$.testCaseFQN', tc.json->'$.fullyQualifiedName',
	'$.id', (SELECT UUID())
);

-- Add id column to data_quality_data_time_series table
-- after we have added the id values to the records
ALTER TABLE data_quality_data_time_series
ADD COLUMN id VARCHAR(36) GENERATED ALWAYS AS (json ->> '$.id') STORED NOT NULL,
ADD CONSTRAINT UNIQUE (id);

-- Create index on id column
CREATE INDEX data_quality_data_time_series_id_index ON data_quality_data_time_series (id);

-- Remove VIRTUAL status column from test_case table and remove
-- testCaseResult state from testCase; fetch from search repo.
ALTER TABLE test_case DROP COLUMN status;
UPDATE test_case SET json = JSON_SET(json, '$.testCaseStatus', JSON_EXTRACT(json, '$.testCaseResult.testCaseStatus'));
ALTER TABLE test_case ADD COLUMN status VARCHAR(56) GENERATED ALWAYS AS (JSON_UNQUOTE(JSON_EXTRACT(json, '$.testCaseStatus'))) STORED;


-- Remove test case result states
UPDATE test_suite
SET json = JSON_REMOVE(json, '$.testCaseResultSummary');

UPDATE test_case
SET json = JSON_REMOVE(json, '$.testCaseResult');
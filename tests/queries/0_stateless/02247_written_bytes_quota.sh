#!/usr/bin/env bash
# Tags: no-parallel

CURDIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../shell_config.sh
. "$CURDIR"/../shell_config.sh

${CLICKHOUSE_CLIENT} -q "DROP TABLE IF EXISTS written_bytes_02247"
${CLICKHOUSE_CLIENT} -q "DROP ROLE IF EXISTS r02247"
${CLICKHOUSE_CLIENT} -q "DROP USER IF EXISTS u02247"
${CLICKHOUSE_CLIENT} -q "DROP QUOTA IF EXISTS q02247"

${CLICKHOUSE_CLIENT} -q "CREATE TABLE written_bytes_02247(s String) ENGINE = Memory"

${CLICKHOUSE_CLIENT} -q "CREATE ROLE r02247"
${CLICKHOUSE_CLIENT} -q "CREATE USER u02247"
${CLICKHOUSE_CLIENT} -q "GRANT ALL ON *.* TO r02247"
${CLICKHOUSE_CLIENT} -q "GRANT r02247 to u02247"
${CLICKHOUSE_CLIENT} -q "CREATE QUOTA q02247 FOR INTERVAL 100 YEAR MAX WRITTEN BYTES = 10 TO r02247"

${CLICKHOUSE_CLIENT} --user u02247 --async_insert 1 -q "INSERT INTO written_bytes_02247 VALUES ('qwqwqw')"
${CLICKHOUSE_CLIENT} --user u02247 --async_insert 0 -q "INSERT INTO written_bytes_02247 VALUES ('qwqwqw')"
${CLICKHOUSE_CLIENT} --user u02247 --async_insert 1 -q "INSERT INTO written_bytes_02247 VALUES ('qwqwqw')" 2>&1 | grep -m1 -o QUOTA_EXPIRED
${CLICKHOUSE_CLIENT} --user u02247 --async_insert 0 -q "INSERT INTO written_bytes_02247 VALUES ('qwqwqw')" 2>&1 | grep -m1 -o QUOTA_EXPIRED

${CLICKHOUSE_CLIENT} -q "SELECT written_bytes > 10 FROM system.quotas_usage WHERE quota_name = 'q02247'"
${CLICKHOUSE_CLIENT} -q "SELECT count() FROM written_bytes_02247"

${CLICKHOUSE_CLIENT} -q "DROP QUOTA q02247"
${CLICKHOUSE_CLIENT} -q "CREATE QUOTA q02247 FOR INTERVAL 100 YEAR MAX WRITTEN BYTES = 100 TO r02247"
${CLICKHOUSE_CLIENT} -q "TRUNCATE TABLE written_bytes_02247"

${CLICKHOUSE_CLIENT} --user u02247 -q "INSERT INTO written_bytes_02247 SELECT toString(number) FROM numbers(50)"

${CLICKHOUSE_CLIENT} --user u02247 -q "INSERT INTO written_bytes_02247 SELECT toString(number) FROM numbers(1)" 2>&1 | grep -m1 -o QUOTA_EXPIRED
${CLICKHOUSE_CLIENT} --user u02247 --async_insert 1 -q "INSERT INTO written_bytes_02247 VALUES ('qwqwqw')" 2>&1 | grep -m1 -o QUOTA_EXPIRED
${CLICKHOUSE_CLIENT} --user u02247 --async_insert 0 -q "INSERT INTO written_bytes_02247 VALUES ('qwqwqw')" 2>&1 | grep -m1 -o QUOTA_EXPIRED

${CLICKHOUSE_CLIENT} -q "SELECT written_bytes > 100 FROM system.quotas_usage WHERE quota_name = 'q02247'"
${CLICKHOUSE_CLIENT} -q "SELECT count() FROM written_bytes_02247"

${CLICKHOUSE_CLIENT} -q "DROP TABLE IF EXISTS written_bytes_02247"
${CLICKHOUSE_CLIENT} -q "DROP ROLE IF EXISTS r02247"
${CLICKHOUSE_CLIENT} -q "DROP USER IF EXISTS u02247"
${CLICKHOUSE_CLIENT} -q "DROP QUOTA IF EXISTS q02247"

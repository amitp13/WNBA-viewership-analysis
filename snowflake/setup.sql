-- Snowflake setup for the WNBA viewership project.
-- Creates: 
    -- a role for dbt, a small warehouse, the project database, a schema for raw data, and a service user for dbt.

use role accountadmin;

-- 1. Role: the set of permissions dbt gets (and nothing more)
create role if not exists transformer
  comment = 'Builds and tests the WNBA dbt project';
grant role transformer to role sysadmin;           -- admins inherit it
set my_user = '"' || current_user() || '"';
grant role transformer to user identifier($my_user); -- so I can use it in Snowsight too

-- 2. Warehouse: the compute that runs queries. Smallest size,
--    pauses after 60 idle seconds so it doesn't burn trial credits.
create warehouse if not exists wnba_wh
  warehouse_size = 'XSMALL'
  auto_suspend = 60
  auto_resume = true
  initially_suspended = true
  comment = 'Compute for loading and dbt runs';
grant usage on warehouse wnba_wh to role transformer;

-- 3. Database: where all project tables live
create database if not exists wnba
  comment = 'WNBA viewership project';
grant usage, create schema on database wnba to role transformer;

-- 4. Raw schema, created by the dbt role so the role owns it
use role transformer;
create schema if not exists wnba.raw
  comment = 'Raw files loaded as-is (wehoop, Elo, NFL schedule)';
use role accountadmin;

-- 5. Service user for dbt. TYPE = SERVICE means no password and no
--    interactive login; it signs in with a key pair instead.
--    Paste the public key (one line, no BEGIN/END lines) below.
create user if not exists dbt_user
  type = service
  default_role = transformer
  default_warehouse = wnba_wh
  default_namespace = wnba.raw
  comment = 'Service user for dbt';
grant role transformer to user dbt_user;
alter user dbt_user set rsa_public_key = '<public here placeholder>';

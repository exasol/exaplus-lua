set autocommit off;

CONTROL SET TRACE LEVEL NOTICE WITH LOG TIMEOUT 0;

drop user tpcuser cascade;
create user tpcuser identified by "tpcuser";
grant create session to tpcuser;
grant create table to tpcuser;
grant create view to tpcuser;
grant create schema to tpcuser;
grant select any dictionary to tpcuser; -- to get debug output of system tables
grant IMPORT, EXPORT to PUBLIC; 
alter system set query_cache='off';

commit;

-- display tables, aux & conf params info
select * from exa_all_columns;
select INDEX_SCHEMA,INDEX_TABLE,INDEX_OWNER,INDEX_OBJECT_ID,INDEX_TYPE,CREATED,LAST_COMMIT,REMARKS from exa_all_indices;
select * from EXA_PARAMETERS;
select * from "$EXA_SYSTEM_EVENTS";


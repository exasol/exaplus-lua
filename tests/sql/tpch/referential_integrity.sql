set autocommit off;
open schema tpc;

select distinct L_ORDERKEY from LINEITEM
where not exists
(select O_ORDERKEY from ORDERS where O_ORDERKEY=L_ORDERKEY);

select distinct L_PARTKEY, L_SUPPKEY from LINEITEM
where not exists
(select PS_PARTKEY, PS_SUPPKEY from PARTSUPP where L_PARTKEY=PS_PARTKEY and L_SUPPKEY=PS_SUPPKEY);

select distinct O_CUSTKEY from ORDERS
where not exists
(select C_CUSTKEY from CUSTOMER where C_CUSTKEY=O_CUSTKEY);

select distinct C_NATIONKEY from CUSTOMER
where not exists
(select N_NATIONKEY from NATION where N_NATIONKEY=C_NATIONKEY);

select distinct PS_PARTKEY from PARTSUPP
where not exists
(select P_PARTKEY from PART where P_PARTKEY=PS_PARTKEY);

select distinct PS_SUPPKEY from PARTSUPP
where not exists
(select S_SUPPKEY from SUPPLIER where S_SUPPKEY=PS_SUPPKEY);

select distinct S_NATIONKEY FROM SUPPLIER
where not exists
(select N_NATIONKEY from NATION where N_NATIONKEY=S_NATIONKEY);

select distinct N_REGIONKEY FROM NATION
where not exists
(select R_REGIONKEY from REGION where R_REGIONKEY=N_REGIONKEY);

rollback;

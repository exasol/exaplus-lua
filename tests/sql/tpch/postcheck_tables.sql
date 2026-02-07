-- all table data from reference dataset must be in the base tables or - for LINEITEM and ORDERS - in the deleted keys
create or replace table POSTCHECK.PARTSUPP_nonexisting as select * from POSTCHECK.PARTSUPP where (PS_PARTKEY,PS_SUPPKEY,PS_AVAILQTY,PS_SUPPLYCOST,PS_COMMENT) not in (select * from TPC.PARTSUPP);
create or replace table POSTCHECK.PART_nonexisting as select * from POSTCHECK.PART where (P_PARTKEY,P_NAME,P_MFGR,P_BRAND,P_TYPE,P_SIZE,P_CONTAINER,P_RETAILPRICE,P_COMMENT) not in (select * from TPC.PART);
create or replace table POSTCHECK.ORDERS_nonexisting as select * from POSTCHECK.ORDERS where (O_ORDERKEY,O_CUSTKEY,O_ORDERSTATUS,O_TOTALPRICE,O_ORDERDATE,O_ORDERPRIORITY,O_CLERK,O_SHIPPRIORITY,O_COMMENT) not in (select * from TPC.ORDERS);
create or replace table POSTCHECK.NATION_nonexisting as select * from POSTCHECK.NATION where (N_NATIONKEY,N_NAME,N_REGIONKEY,N_COMMENT) not in (select * from TPC.NATION);
create or replace table POSTCHECK.REGION_nonexisting as select * from POSTCHECK.REGION where (R_REGIONKEY,R_NAME,R_COMMENT) not in (select * from TPC.REGION);
create or replace table POSTCHECK.CUSTOMER_nonexisting as select * from POSTCHECK.CUSTOMER where (C_CUSTKEY,C_NAME,C_ADDRESS,C_NATIONKEY,C_PHONE,C_ACCTBAL,C_MKTSEGMENT,C_COMMENT) not in (select * from TPC.CUSTOMER);
create or replace table POSTCHECK.SUPPLIER_nonexisting as select * from POSTCHECK.SUPPLIER where (S_SUPPKEY,S_NAME,S_ADDRESS,S_NATIONKEY,S_PHONE,S_ACCTBAL,S_COMMENT) not in (select * from TPC.SUPPLIER);
create or replace table POSTCHECK.LINEITEM_nonexisting as select * from POSTCHECK.LINEITEM where (L_ORDERKEY,L_PARTKEY,L_SUPPKEY,L_LINENUMBER,L_QUANTITY,L_EXTENDEDPRICE,L_DISCOUNT,L_TAX,L_RETURNFLAG,L_LINESTATUS,L_SHIPDATE,L_COMMITDATE,L_RECEIPTDATE,L_SHIPINSTRUCT,L_SHIPMODE,L_COMMENT) not in (select * from TPC.LINEITEM);

-- with exception of LINEITEM and ORDERS all the just created tables must be empty since all values should exist
select count(*) from POSTCHECK.PARTSUPP_nonexisting;
select count(*) from POSTCHECK.PART_nonexisting;
select count(*) from POSTCHECK.NATION_nonexisting;
select count(*) from POSTCHECK.REGION_nonexisting;
select count(*) from POSTCHECK.CUSTOMER_nonexisting;
select count(*) from POSTCHECK.SUPPLIER_nonexisting;

-- for lineitem and orders additionally check the remaining rows (if any) for deletion by refresh functions
create or replace table POSTCHECK.LINEITEM_nonexisting_nondeleted as select * from POSTCHECK.LINEITEM_nonexisting where L_ORDERKEY not in (select * from POSTCHECK.DELETED_ORDERKEYS);
create or replace table POSTCHECK.ORDERS_nonexisting_nondeleted as select * from POSTCHECK.ORDERS_nonexisting where O_ORDERKEY not in (select * from POSTCHECK.DELETED_ORDERKEYS);

-- some rows might exist in the reference data that are not in the tables any more (because of deletion in RF2) so the tables with just the nonexisting rows might have some rows ...
select count(*) from POSTCHECK.LINEITEM_nonexisting;
select count(*) from POSTCHECK.ORDERS_nonexisting;
-- ... but those rows must be deleted so nonexisting rows that are not deleted may not exist (so the following tables again must be empty)
select count(*) from POSTCHECK.LINEITEM_nonexisting_nondeleted;
select count(*) from POSTCHECK.ORDERS_nonexisting_nondeleted;

@postcheck2.sql;

-- @schema_info_after.sql;

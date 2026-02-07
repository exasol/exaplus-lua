set autocommit off;

drop schema postcheck;
create schema postcheck;
open schema postcheck;

-- keys dec(11)
-- integers dec(10)
-- decimals dec(12,2)

--base tables
create or replace table nation  ( n_nationkey dec(11), n_name char(25), n_regionkey dec(11), n_comment varchar(152) );
create or replace table region  ( r_regionkey dec(11), r_name char(25), r_comment varchar(152) );
create or replace table part  ( p_partkey dec(11), p_name varchar(55), p_mfgr char(25), p_brand char(10), p_type varchar(25), p_size dec(10), p_container char(10), p_retailprice decimal(12,2), p_comment varchar(23) );
create or replace table supplier ( s_suppkey dec(11), s_name char(25), s_address varchar(40), s_nationkey dec(11), s_phone char(15), s_acctbal decimal(12,2), s_comment varchar(101) );
create or replace table partsupp ( ps_partkey dec(11), ps_suppkey dec(11), ps_availqty dec(10), ps_supplycost decimal(12,2), ps_comment varchar(199) );
create or replace table customer ( c_custkey dec(11), c_name varchar(25), c_address varchar(40), c_nationkey dec(11), c_phone char(15), c_acctbal decimal(12,2), c_mktsegment char(10), c_comment varchar(117) );
create or replace table orders  ( o_orderkey dec(12), o_custkey dec(11), o_orderstatus char(1), o_totalprice decimal(12,2), o_orderdate date, o_orderpriority char(15), o_clerk char(15), o_shippriority dec(10), o_comment varchar(79) );
create or replace table lineitem ( l_orderkey dec(12), l_partkey dec(11), l_suppkey dec(11), l_linenumber dec(10), l_quantity decimal(12,2), l_extendedprice decimal(12,2), l_discount decimal(12,2), l_tax decimal(12,2), l_returnflag char(1), l_linestatus char(1), l_shipdate date, l_commitdate date, l_receiptdate date, l_shipinstruct char(25), l_shipmode char(10), l_comment varchar(44) );

--deleted keys
create or replace table deleted_orderkeys  ( o_orderkey dec(12));

commit;


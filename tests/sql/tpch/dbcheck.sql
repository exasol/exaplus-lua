open schema tpc;
set autocommit off;
commit;

-- get timestamp
select to_char (systimestamp, 'HH:MI:SS') start_time from dual;

-- display tables, aux & conf params info
rollback;
@params.sql;


-------------------------------------------------
-- REGION ---------------------------------------
-------------------------------------------------
--drop table temp_region;

create or replace table temp_region as
select * from region
where r_regionkey = 1;

update temp_region
set r_regionkey = 2147483647;

insert into region
(select * from temp_region);

select * from region
where r_regionkey = 2147483647
or r_regionkey = 1;

delete from region
where r_regionkey = 2147483647;

drop table temp_region;
commit;

-------------------------------------------------
-- NATION ---------------------------------------
-------------------------------------------------
--drop table temp_nation;

create or replace table temp_nation as
select * from nation
where n_nationkey = 1;

update temp_nation
set n_nationkey = 2147483647;

insert into nation
(select * from temp_nation);

select * from nation
where n_nationkey = 2147483647
or n_nationkey = 1;

delete from nation
where n_nationkey = 2147483647;

drop table temp_nation;
commit;

-------------------------------------------------
-- PART -----------------------------------------
-------------------------------------------------
--drop table temp_parts;

create or replace table temp_parts as
select * from part
where p_partkey = 1;

update temp_parts
set p_partkey = 2147483647;

insert into part
(select * from temp_parts);

select * from part
where p_partkey = 2147483647
or p_partkey = 1;

delete from part
where p_partkey = 2147483647;

drop table temp_parts;
commit;

-------------------------------------------------
-- SUPPLIER -------------------------------------
-------------------------------------------------
--drop table temp_supplier;

create or replace table temp_supplier as
select * from supplier
where s_suppkey = 1;

update temp_supplier
set s_suppkey = 2147483647;

insert into supplier
(select * from temp_supplier);

select * from supplier
where s_suppkey = 2147483647
or s_suppkey = 1;

delete from supplier
where s_suppkey = 2147483647;

drop table temp_supplier;
commit;

-------------------------------------------------
-- PARTSUPP -------------------------------------
-------------------------------------------------
--drop table temp_partsupp;

create or replace table temp_partsupp as
select * from partsupp
where ps_partkey = 1
and ps_suppkey = 2;

update temp_partsupp
set ps_partkey = 2147483647,
ps_suppkey = 2147483647;

insert into partsupp
(select * from temp_partsupp);

select * from partsupp
where (ps_partkey = 2147483647
and ps_suppkey = 2147483647)
or (ps_partkey = 1
and ps_suppkey = 2);

delete from partsupp
where ps_partkey = 2147483647
and ps_suppkey = 2147483647;

drop table temp_partsupp;
commit;

-------------------------------------------------
-- CUSTOMER -------------------------------------
-------------------------------------------------
--drop table temp_customer;

create or replace table temp_customer as
select * from customer
where c_custkey = 1;

update temp_customer
set c_custkey = 2147483647;

insert into customer
(select * from temp_customer);

select * from customer
where c_custkey = 2147483647
or c_custkey = 1;

delete from customer
where c_custkey = 2147483647;

drop table temp_customer;
commit;

-------------------------------------------------
-- ORDERS ---------------------------------------
-------------------------------------------------
--drop table temp_orders;

create or replace table temp_orders as
select * from orders
where o_orderkey = (select min(o_orderkey) from orders);

update temp_orders
set o_orderkey = 2147483647;

insert into orders
(select * from temp_orders);

select * from orders
where o_orderkey = 2147483647
or o_orderkey = (select min(o_orderkey) from orders);

delete from orders
where o_orderkey = 2147483647;

drop table temp_orders;
commit;

-------------------------------------------------
-- LINEITEM -------------------------------------
-------------------------------------------------
--drop table temp_lineitem;

create or replace table temp_lineitem as
select * from lineitem
where l_orderkey = (select min(o_orderkey) from orders)
and l_linenumber = 1;

update temp_lineitem
set l_orderkey = 2147483647,
l_partkey = 2147483647,
l_suppkey = 2147483647,
l_linenumber = -2147483646;

insert into lineitem
(select * from temp_lineitem);

select * from lineitem
where (l_orderkey = 2147483647
and l_partkey = 2147483647
and l_suppkey = 2147483647
and l_linenumber = -2147483646)
or (l_orderkey = (select min(o_orderkey) from orders)
and l_linenumber = 1);

delete from lineitem
where l_orderkey = 2147483647
and l_partkey = 2147483647
and l_suppkey = 2147483647
and l_linenumber = -2147483646;

drop table temp_lineitem;
commit;

-- get timestamp
select to_char (systimestamp, 'HH:MI:SS') my_timestamp from dual;

-------------------------------------------------
-- REGION ---------------------------------------
-------------------------------------------------
insert into region
(r_regionkey, r_name, r_comment)
values
(2147483647,
'Ze ends of the earth....E',
'A reasonable comment would go herE');

select * from region
where r_regionkey = 2147483647;

delete from region
where r_regionkey = 2147483647;

-------------------------------------------------
-- NATION ---------------------------------------
-------------------------------------------------
insert into nation
(n_nationkey, n_name, n_regionkey, n_comment)
values
(2147483647,
'Ze Republic d MakebelievE',
2147483647,
'A nation comment for field size 152 no E');

select * from nation
where n_nationkey = 2147483647
and n_regionkey = 2147483647;

delete from nation
where n_nationkey = 2147483647
and n_regionkey = 2147483647;

-------------------------------------------------
-- PART -----------------------------------------
-------------------------------------------------
insert into part
(p_partkey, p_name, p_mfgr, p_brand, p_type,
p_size, p_container, p_retailprice, p_comment)
values
(2147483647, 'Pname text .......2.........3.........4....5E',
'Pmfgr text........2....5E','Pbrand 10E',
'Ptype varchar.....2....5E', 2147483646,
'PcontainrE', 1234567890.12,
'Part comment field 23E');

select * from part
where p_partkey = 2147483647;

delete from part
where p_partkey = 2147483647;

-------------------------------------------------
-- SUPPLIER -------------------------------------
-------------------------------------------------
insert into supplier
(s_suppkey, s_name, s_address, s_nationkey, s_phone,
s_acctbal, s_comment)
values
(2147483647, 'NAME text ............25E',
'Address varchar ............30.......40E',
2147483647,'This is phone E', 1234567890.12,
'Supplier comment field is 101 long no E');

select * from supplier
where s_suppkey = 2147483647;

delete from supplier
where s_suppkey = 2147483647;

-------------------------------------------------
-- PARTSUPP -------------------------------------
-------------------------------------------------
insert into partsupp
(ps_partkey, ps_suppkey, ps_availqty, ps_supplycost,
ps_comment)
values
(2147483647, 2147483647, -2147483646, 1234567890.12,
'PS comment field is 199 long no E');

select * from partsupp
where ps_partkey = 2147483647
and ps_suppkey = 2147483647;

delete from partsupp
where ps_partkey = 2147483647
and ps_suppkey = 2147483647;

-------------------------------------------------
-- CUSTOMER -------------------------------------
-------------------------------------------------
insert into customer
(c_custkey, c_name, c_address, c_nationkey,
c_phone, c_acctbal, c_mktsegment, c_comment)
values
(2147483647, 'Customer Name goes to 25E',
'Customer Address goes here..3.........4E',
2147483647, 'This is phone E', 1234567890.12,
'ZMark segE', 'Customer comments fiels is 117 long no E');

select * from customer
where c_custkey = 2147483647;

delete from customer
where c_custkey = 2147483647;

-------------------------------------------------
-- ORDER ----------------------------------------
-------------------------------------------------
insert into orders
(o_orderkey, o_custkey, o_orderstatus, o_totalprice,
o_orderdate, o_orderpriority, o_clerk, o_shippriority,
o_comment)
values
(2147483647, 2147483647, 'X', 1234567890.12,
TO_DATE('2005-12-30','YYYY-MM-DD'),
'Order Priorty5E', 'Fixed text 15E', -2147483646,
'Order comments field is 79 no E');

select * from orders
where o_orderkey = 2147483647
and o_custkey = 2147483647;

delete from orders
where o_orderkey = 2147483647
and o_custkey = 2147483647;

-------------------------------------------------
-- LINEITEM -------------------------------------
-------------------------------------------------
insert into lineitem
(l_orderkey, l_partkey, l_suppkey, l_linenumber,
l_quantity, l_extendedprice, l_discount, l_tax,
l_returnflag, l_linestatus, l_shipdate, l_commitdate,
l_receiptdate, l_shipinstruct, l_shipmode, l_comment)
values
(2147483647,
2147483647,
2147483647,
-2147483646,
-1234567890.12,
-1234567890.12,
-1234567890.12,
-1234567890.12,
'Q',
'R',
TO_DATE('2005-12-30','YYYY-MM-DD'),
TO_DATE('2005-12-30','YYYY-MM-DD'),
TO_DATE('2005-12-30','YYYY-MM-DD'),
'Ship by camel .........5E',
'Ship ASAPE',
'Is this really what you wanted? 44 long....E');

select * from lineitem
where l_orderkey = 2147483647
and l_partkey = 2147483647
and l_suppkey = 2147483647
and l_linenumber = -2147483646;

delete from lineitem
where l_orderkey = 2147483647
and l_partkey = 2147483647
and l_suppkey = 2147483647
and l_linenumber = -2147483646;

-- get timestamp
select to_char (systimestamp, 'HH:MI:SS') end_time from dual;


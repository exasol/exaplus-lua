open schema tpc;
set autocommit off;
commit;

-- get timestamp
select to_char (systimestamp, 'HH:MI:SS') start_time from dual;

-------------------------------------------------
-- REGION ---------------------------------------
-------------------------------------------------
select * from region;

-------------------------------------------------
-- NATION ---------------------------------------
-------------------------------------------------
select count(*) from nation;

select * from nation
where n_nationkey in (3,10,14,20)
order by n_nationkey;

-------------------------------------------------
-- PART -----------------------------------------
-------------------------------------------------
select count(*) from part;
select * from part
where p_partkey in (1,984,8743,9028,13876,17899,20000)
order by p_partkey;

select * from part limit 10;

-------------------------------------------------
-- SUPPLIER -------------------------------------
-------------------------------------------------
select count(*) from supplier;

select * from supplier
where s_suppkey in (83,265,492,784,901,1000)
order by s_suppkey;

select * from supplier limit 10;

-------------------------------------------------
-- PARTSUPP -------------------------------------
-------------------------------------------------
select count(*) from partsupp;

select * from partsupp
where ps_partkey = 3398
and ps_suppkey = (select min(ps_suppkey)
from partsupp where ps_partkey = 3398);

select * from partsupp
where ps_partkey =15873
and ps_suppkey = (select min(ps_suppkey)
from partsupp where ps_partkey = 15873);

select * from partsupp
where ps_partkey = 11394
and ps_suppkey = (select min(ps_suppkey)
from partsupp where ps_partkey = 11394);

select * from partsupp
where ps_partkey = 6743
and ps_suppkey = (select min(ps_suppkey)
from partsupp where ps_partkey = 6743);

select * from partsupp
where ps_partkey = 19763
and ps_suppkey = (select min(ps_suppkey)
from partsupp where ps_partkey =19763);

select * from partsupp limit 10;

-------------------------------------------------
-- CUSTOMER -------------------------------------
-------------------------------------------------
select count(*) from customer;

select * from customer
where c_custkey in ( 12, 922, 6226, 39922, 73606, 142549 )
order by c_custkey;

select * from customer limit 10;

-------------------------------------------------
-- ORDERS ---------------------------------------
-------------------------------------------------
select count(*) from orders;

select * from orders
where o_orderkey in ( 7, 44065, 287590, 411111, 483876, 599942 )
order by o_orderkey;

select * from orders limit 10;

-------------------------------------------------
-- LINEITEM -------------------------------------
-------------------------------------------------
select count(*) from lineitem;

select * from lineitem
where l_orderkey in
( 4, 26598, 148577, 387431, 56704, 517442, 600000)
and l_linenumber = 1
order by l_orderkey;

select * from lineitem limit 10;

-------------------------------------------------
-- Min & Max ------------------------------------
-------------------------------------------------
--drop table minmax;

create or replace table minmax
  (tname char(15),
   keymin integer,
   keymax integer);

insert into minmax
select 'lineitem_ord',min(l_orderkey),max(l_orderkey)
from lineitem;

insert into minmax
select 'lineitem_nbr',min(l_linenumber),max(l_linenumber)
from lineitem;

insert into minmax
select 'orders',min(o_orderkey),max(o_orderkey)
from orders;

insert into minmax
select 'customer',min(c_custkey),max(c_custkey)
from customer;

insert into minmax
select 'part',min(p_partkey),max(p_partkey)
from part;

insert into minmax
select 'supplier',min(s_suppkey),max(s_suppkey)
from supplier;

insert into minmax
select 'partsupp_part',min(ps_partkey),max(ps_partkey)
from partsupp;

insert into minmax
select 'partsupp_supp',min(ps_suppkey),max(ps_suppkey)
from partsupp;

insert into minmax
select 'nation',min(n_nationkey),max(n_nationkey)
from nation;

insert into minmax
select 'region',min(r_regionkey),max(r_regionkey)
from region;

select * from minmax;


-- display tables, aux & conf params info
rollback;
@params.sql;

-- get timestamp
select to_char (systimestamp, 'HH:MI:SS') end_time from dual;


-- @schema_info_before.sql;


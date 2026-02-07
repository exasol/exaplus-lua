drop schema postcheck2 cascade;
create schema postcheck2;
open schema postcheck2;

--PARTSUPP
create or replace table postcheck2.partsupp_noexisting as
 select ps1.ps_partkey, ps1.ps_suppkey, ps1.ps_availqty, ps1.ps_supplycost, ps1.ps_comment  
 from postcheck.partsupp ps1
        left outer join tpc.partsupp ps2
        on ps1.ps_partkey = ps2.ps_partkey
        and ps1.ps_suppkey = ps2.ps_suppkey
        where ps2.ps_suppkey is null;

select count(*) from postcheck2.partsupp_noexisting;


--PART
create or replace table postcheck2.part_noexisting as
    select p1.p_partkey, p1.p_name, p1.p_mfgr, p1.p_brand, p1.p_type,
           p1.p_size, p1.p_container, p1.p_retailprice, p1.p_comment
        from postcheck.part p1
        left outer join tpc.part p2
            on p1.p_partkey = p2.p_partkey
            where p2.p_partkey is null; 

select count(*) from postcheck2.part_noexisting;


--CUSTOMER
create or replace table postcheck2.customer_noexisting as
    select c1.c_custkey, c1.c_nationkey, c1.c_mktsegment, c1.c_name,
           c1.c_address, c1.c_phone, c1.c_acctbal, c1.c_comment 
        from postcheck.customer c1
        left outer join tpc.customer c2
            on c1.c_custkey = c2.c_custkey
            where c2.c_custkey is null;

select count(*) from postcheck2.customer_noexisting;


--SUPPLIER
create or replace table postcheck2.supplier_noexisting as
    select s1.s_suppkey, s1.s_name, s1.s_address, s1.s_nationkey,
           s1.s_phone, s1.s_acctbal, s1.s_comment
        from postcheck.supplier s1
        left outer join tpc.supplier s2
            on s1.s_suppkey = s2.s_suppkey
            where s2.s_suppkey is null;

select count(*) from postcheck2.supplier_noexisting;

            
--ORDERS
create or replace table postcheck2.orders_noexisting as
    select o1.o_orderkey, o1.o_custkey, o1.o_orderstatus, o1.o_totalprice, 
           o1.o_orderdate, o1.o_orderpriority, o1.o_clerk, o1.o_shippriority, o1.o_comment
           from postcheck.orders o1
                left outer join tpc.orders o2
             on o1.o_orderkey = o2.o_orderkey
          where o2.o_orderkey is null;
          

select count(*) from postcheck2.orders_noexisting;

--not existing because of delete
select count(*)
    from postcheck2.orders_noexisting n
    inner join postcheck.deleted_orderkeys d
    on n.o_orderkey = d.o_orderkey;
          

--LINEITEM
create or replace table postcheck2.lineitem_noexisting as
     select l1.l_orderkey, l1.l_partkey,l1.l_suppkey,l1.l_linenumber, l1.l_quantity,
            l1.l_extendedprice,l1.l_discount,l1.l_tax, l1.l_returnflag,l1.l_linestatus,
            l1.l_shipdate,l1.l_commitdate,l1.l_receiptdate,l1.l_shipinstruct,l1.l_shipmode,l1.l_comment
     from postcheck.lineitem l1 left outer join tpc.lineitem l2
       on l1.l_orderkey = l2.l_orderkey and l1.l_linenumber = l2.l_linenumber
     where l2.l_orderkey is null;


select count(*) from postcheck2.lineitem_noexisting;

--not existing because of delete
select count(*) 
    from postcheck2.lineitem_noexisting n
    inner join postcheck.deleted_orderkeys d
    on n.l_orderkey = d.o_orderkey;
   


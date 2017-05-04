set serveroutput on
set timing on
set autotrace on

exec pkg_costes.run_test;


--run the function:
bill('99/48764198/49T', '11', '2016' ,'Premium Rider'); --'Alba','Perez'


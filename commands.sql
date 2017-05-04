set serveroutput on
set timing on
set autotrace on

exec pkg_costes.run_test;


--run the function:
bill('99/48764198/49T', '11', '2016' ,'Premium Rider'); --'Alba','Perez'


--RESULTS OF THE EXECUTION:
/*Contratos facturados en este mes:  4758
Contratos facturados en este mes:  4758
Contratos facturados en este mes:  4758
Contratos facturados en este mes:  4758
Contratos facturados en este mes:  4758
Contratos facturados en este mes:  4758
Contratos facturados en este mes:  4758
Contratos facturados en este mes:  4758
Contratos facturados en este mes:  4758
Contratos facturados en este mes:  4758
Contratos facturados en este mes:  4758
RESULTS AT 05-MAY-17
TIME CONSUMPTION: 158656 milliseconds.
CONSISTENT GETS: 192096 blocks

PL/SQL procedure successfully completed.

Elapsed: 00:07:19.25*/



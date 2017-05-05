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


--RESULTS OF QUERY 1
/*Statistics
----------------------------------------------------------
       1575  recursive calls
          0  db block gets
      15482  consistent gets
      10080  physical reads
          0  redo size
     218485  bytes sent via SQL*Net to client
       3440  bytes received via SQL*Net from client
        283  SQL*Net roundtrips to/from client
         23  sorts (memory)
          0  sorts (disk)
       4217  rows processed
*/

--RESULTS OF QUERY 2
/*Statistics
----------------------------------------------------------
       1045  recursive calls
          0  db block gets
       5606  consistent gets
       5215  physical reads
          0  redo size
        503  bytes sent via SQL*Net to client
        349  bytes received via SQL*Net from client
          2  SQL*Net roundtrips to/from client
         20  sorts (memory)
          0  sorts (disk)
          5  rows processed*/

--RESULTS OF QUERY 3
/*Statistics
----------------------------------------------------------
        694  recursive calls
          0  db block gets
       1618  consistent gets
       1463  physical reads
          0  redo size
        544  bytes sent via SQL*Net to client
        349  bytes received via SQL*Net from client
          2  SQL*Net roundtrips to/from client
         11  sorts (memory)
          0  sorts (disk)
          5  rows processed
*/

--RESULTS OF QUERY 4
/*Statistics
----------------------------------------------------------
        497  recursive calls
        274  db block gets
       4931  consistent gets
       2599  physical reads
     142628  redo size
        735  bytes sent via SQL*Net to client
        349  bytes received via SQL*Net from client
          2  SQL*Net roundtrips to/from client
          7  sorts (memory)
          0  sorts (disk)
         12  rows processed
*/

--RESULTS OF THE FUNCTION
/**/

--RESULTS OF THE PROCEDURE
/**/

--RESULTS OF THE PACKAGE ATTEMPT 2
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
TIME CONSUMPTION: 269922 milliseconds.
CONSISTENT GETS: 441440.3 blocks

PL/SQL procedure successfully completed.*/


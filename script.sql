CREATE OR REPLACE PACKAGE PKG_COSTES AS

-- auxiliary function converting an interval into a number (milliseconds)
	FUNCTION interval_to_seconds(x INTERVAL DAY TO SECOND) RETURN NUMBER;

-- WORKLOAD definition
	PROCEDURE PR_WORKLOAD(N NUMBER);

-- RE-STABLISH DB STATE
	PROCEDURE PR_RESET(N NUMBER);

-- Execution of workload (10 times) displaying some measurements 
	PROCEDURE RUN_TEST;

END PKG_COSTES;
/

CREATE OR REPLACE PACKAGE BODY PKG_COSTES AS FUNCTION interval_to_seconds(x INTERVAL DAY TO SECOND ) RETURN NUMBER IS
 BEGIN
 return (((extract( day from x)*24 + extract( hour from x))*60 + extract( minute from x))*60 + extract( second from x))*1000;
 END interval_to_seconds;
 
PROCEDURE PR_WORKLOAD(N NUMBER) IS
BEGIN

-- INSERTS
-- INSERT INTO ...


-- QUERY 1 
 FOR f IN (
 SELECT SURNAME, SEC_SURNAME, NAME, CONTRACT_TYPE, STARTDATE,ENDDATE,TYPE  
FROM
 (SELECT CLIENTID, CONTRACT_TYPE, STARTDATE,ENDDATE FROM CONTRACTS WHERE  ENDDATE>SYSDATE OR ENDDATE IS NULL) A 
  JOIN 
 (SELECT TYPE, PRODUCT_NAME FROM PRODUCTS) B ON (A.CONTRACT_TYPE=B.PRODUCT_NAME)
  JOIN 
 CLIENTS C ON (A.CLIENTID=C.CLIENTID)
ORDER BY SURNAME, SEC_SURNAME, NAME
          ) LOOP 
     NULL;
 END LOOP;


-- QUERY 2
FOR g IN (
SELECT * 
FROM (SELECT B.ACTOR, COUNT('X') USA_MOVIES 
         FROM (SELECT MOVIE_TITLE FROM MOVIES WHERE COUNTRY='USA') A 
              JOIN CASTS B ON (A.MOVIE_TITLE=B.TITLE) 
         GROUP BY B.ACTOR 
         ORDER BY USA_MOVIES DESC)
WHERE ROWNUM<6
          ) LOOP 
     NULL;
 END LOOP;


-- QUERY 3
FOR h IN (
SELECT A.CLIENT, A.TITLE                     
   FROM (SELECT CLIENT,TITLE,COUNT('X') N_EPISODIOS FROM LIC_SERIES GROUP BY CLIENT,TITLE) A
        JOIN (SELECT TITLE, SUM(EPISODES) TOTAL_EP FROM SEASONS GROUP BY TITLE) B 
        ON (A.TITLE=B.TITLE AND A.N_EPISODIOS=B.TOTAL_EP)
          ) LOOP 
     NULL;
 END LOOP;


-- QUERY 4
FOR i IN (
WITH A AS (SELECT TITLE, TO_CHAR(VIEW_DATETIME,'YYYY-MM') eachmonth FROM TAPS_MOVIES),
     B AS (SELECT CASTS.ACTOR, A.eachmonth, COUNT('X') totaltaps          
              FROM A JOIN CASTS ON (A.TITLE=CASTS.TITLE)
              GROUP BY CASTS.ACTOR, A.eachmonth),
     C AS (SELECT eachmonth,MAX(totaltaps) maxtaps FROM B GROUP BY eachmonth)
SELECT C.eachmonth month, B.ACTOR, B.totaltaps
   FROM C JOIN B ON (B.eachmonth=C.eachmonth AND B.totaltaps=C.maxtaps)
   ORDER BY C.eachmonth)
     LOOP 
     NULL;
 END LOOP;
-- CALL PROCEDURE
 BILLING(8, 2016);
END PR_WORKLOAD;


  
PROCEDURE PR_RESET(N NUMBER) IS
  BEGIN

--   DELETE FROM ... WHERE ...;
	DBMS_OUTPUT.PUT_LINE('venga va un poquito'); 
--   ...

END PR_RESET;

  

PROCEDURE RUN_TEST IS
	t1 TIMESTAMP;
	t2 TIMESTAMP;
	auxt NUMBER;
	g1 NUMBER;
	g2 NUMBER;
	auxg NUMBER;
	localsid NUMBER;
    BEGIN
  PKG_COSTES.PR_WORKLOAD(0);  -- first run for preparing db_buffers
	select distinct sid into localsid from v$mystat; 
	SELECT SYSTIMESTAMP INTO t1 FROM DUAL;
	select S.value into g1 from (select * from v$sesstat where sid=localsid) S join (select * from v$statname where name='consistent gets') using(STATISTIC#);
    	--- EXECUTION OF THE WORKLOAD -----------------------------------
	FOR i IN 1..10 LOOP
	    PKG_COSTES.PR_WORKLOAD (i);
	END LOOP;
    	-----------------------------------
	SELECT SYSTIMESTAMP INTO t2 FROM DUAL;
	select S.value into g2 from (select * from v$sesstat where sid=localsid) S join (select * from v$statname where name='consistent gets') using(STATISTIC#);
	auxt:= interval_to_seconds(t2-t1);
	auxg:= (g2-g1) / 10;
    	--- DISPLAY RESULTS -----------------------------------
	DBMS_OUTPUT.PUT_LINE('RESULTS AT '||SYSDATE); 
	DBMS_OUTPUT.PUT_LINE('TIME CONSUMPTION: '|| auxt ||' milliseconds.'); 
	DBMS_OUTPUT.PUT_LINE('CONSISTENT GETS: '|| auxg ||' blocks'); 
	FOR J IN 0..10 LOOP
	    PKG_COSTES.PR_RESET (J);
	END LOOP;
END RUN_TEST;
  

BEGIN
   DBMS_OUTPUT.ENABLE (buffer_size => NULL);
END PKG_COSTES;
/

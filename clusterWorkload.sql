-- WORKLOAD

-- QUERY 1 (4284 VS. 4280)
SELECT SURNAME, SEC_SURNAME, NAME, CONTRACT_TYPE, STARTDATE,ENDDATE,TYPE  
FROM 
 (SELECT CLIENTID, CONTRACT_TYPE, STARTDATE,ENDDATE FROM CONTRACTS WHERE  ENDDATE>SYSDATE OR ENDDATE IS NULL) A 
  JOIN 
 (SELECT TYPE, PRODUCT_NAME FROM PRODUCTS) B ON (A.CONTRACT_TYPE=B.PRODUCT_NAME)
  JOIN 
 CLIENTS C ON (A.CLIENTID=C.CLIENTID)
ORDER BY SURNAME, SEC_SURNAME, NAME; 


--QUERY 2

SELECT * 
FROM (SELECT B.ACTOR, COUNT('X') USA_MOVIES 
         FROM (SELECT MOVIE_TITLE FROM MOVIES WHERE COUNTRY='USA') A 
              JOIN CASTS B ON (A.MOVIE_TITLE=B.TITLE) 
         GROUP BY B.ACTOR 
         ORDER BY USA_MOVIES DESC)
WHERE ROWNUM<6;


-- QUERY 3

-- First interpretation: a whole tv series (all seasons, all episodes): NONE
SELECT A.CLIENT, A.TITLE                     
   FROM (SELECT CLIENT,TITLE,COUNT('X') N_EPISODIOS FROM LIC_SERIES GROUP BY CLIENT,TITLE) A
        JOIN (SELECT TITLE, SUM(EPISODES) TOTAL_EP FROM SEASONS GROUP BY TITLE) B 
        ON (A.TITLE=B.TITLE AND A.N_EPISODIOS=B.TOTAL_EP); 

-- Second interpretation: a whole season of any series (2139)
SELECT A.CLIENT, A.TITLE, A.SEASON
   FROM (SELECT CLIENT,TITLE,SEASON, COUNT('X') N_EPISODIOS FROM LIC_SERIES GROUP BY CLIENT,TITLE,SEASON) A
   JOIN SEASONS B 
   ON (A.TITLE=B.TITLE AND A.SEASON=B.SEASON AND A.N_EPISODIOS=B.EPISODES); 



-- QUERY 4

WITH A AS (SELECT TITLE, TO_CHAR(VIEW_DATETIME,'YYYY-MM') eachmonth FROM TAPS_MOVIES),
     B AS (SELECT CASTS.ACTOR, A.eachmonth, COUNT('X') totaltaps          
              FROM A JOIN CASTS ON (A.TITLE=CASTS.TITLE)
              GROUP BY CASTS.ACTOR, A.eachmonth),
     C AS (SELECT eachmonth,MAX(totaltaps) maxtaps FROM B GROUP BY eachmonth)
SELECT C.eachmonth month, B.ACTOR, B.totaltaps
   FROM C JOIN B ON (B.eachmonth=C.eachmonth AND B.totaltaps=C.maxtaps)
   ORDER BY C.eachmonth);



-- BILLING FUNCTION AND PROCEDURE

CREATE OR REPLACE FUNCTION bill (month IN NUMBER, year IN NUMBER, 
          cust IN CLIENTS.clientId%TYPE, product IN products.product_name%TYPE)  
          RETURN NUMBER IS

tariff products%ROWTYPE;
low_date DATE; top_date DATE;
ppcs NUMBER; ppvs NUMBER;
mins NUMBER; days NUMBER; 
promoends DATE;
total NUMBER;
aux NUMBER;

BEGIN
   SELECT * INTO tariff FROM products WHERE product_name=product;
   low_date := TO_DATE(month||'/'||year,'MM/YYYY'); 
	top_date  := ADD_MONTHS(low_date,1) -1;
    
   If tariff.type='V' THEN ppcs:=0;
      ELSE
           SELECT count('x')*2 INTO ppcs FROM lic_movies 
              WHERE client=cust AND datetime>=low_date AND datetime<top_date;
           SELECT ppcs+count('x') INTO ppcs FROM lic_series 
              WHERE client=cust AND datetime>=low_date AND datetime<top_date;
   END IF;


   If tariff.type='C' THEN ppvs:=0;
      ELSE
 -- We will count all views and then substract views with a licence
 -- Count movie_views with licence
         SELECT count('x') INTO aux 
            FROM (SELECT * FROM taps_movies
                    WHERE view_datetime>=low_date AND view_datetime<top_date 
                          AND pct>tariff.zapp) A 
                 NATURAL JOIN 
                 (SELECT contractId FROM contracts WHERE clientId=cust) B
               JOIN 
                 (SELECT title,datetime FROM lic_movies WHERE client=cust) C
                 ON (A.title=C.title AND A.view_datetime>=C.datetime);
      
 -- Count movie_views without licence
         SELECT (count('x')-aux)*2 INTO ppvs
            FROM (SELECT contractId FROM contracts WHERE clientId=cust) 
                 NATURAL JOIN taps_movies
            WHERE view_datetime>=low_date AND view_datetime<top_date 
                  AND pct>tariff.zapp;

 -- Count series_views with licence
         SELECT count('x') INTO aux 
            FROM (SELECT * FROM taps_series
                    WHERE view_datetime>=low_date AND view_datetime<top_date 
                          AND pct>tariff.zapp) A 
                 NATURAL JOIN 
                 (SELECT contractId FROM contracts WHERE clientId=cust) B
                 JOIN 
                 (SELECT title,datetime,season,episode FROM lic_series 
                     WHERE client=cust) C
                 ON (A.title=C.title AND A.season=C.season AND A.episode=C.episode 
                     AND A.view_datetime>=C.datetime);
 -- count series_views without licence minus the latter
      SELECT ppvs+(count('x')-aux) INTO ppvs
           FROM (SELECT contractId FROM contracts WHERE clientId=cust) 
                NATURAL JOIN taps_series
           WHERE view_datetime>=low_date AND view_datetime<top_date 
                   AND pct>tariff.zapp;
             
   END IF;
  

-- Count days
   SELECT count('x') INTO days
      FROM ((SELECT DISTINCT TO_CHAR(view_datetime,'DD')
               FROM (SELECT contractId FROM contracts WHERE clientId=cust) 
                    NATURAL JOIN taps_movies
               WHERE view_datetime>=low_date AND view_datetime<top_date 
                     AND pct>tariff.zapp)
            UNION
            (SELECT DISTINCT TO_CHAR(view_datetime,'DD')
               FROM (SELECT contractId FROM contracts WHERE clientId=cust) 
                    NATURAL JOIN taps_series
               WHERE view_datetime>=low_date AND view_datetime<top_date 
                     AND pct>tariff.zapp));

-- Count minutes regarding movies
   SELECT sum(B.duration*A.pct/100) INTO mins
      FROM ((SELECT title,pct
            FROM (SELECT contractId FROM contracts WHERE clientId=cust) 
                 NATURAL JOIN taps_movies
                 WHERE view_datetime>=low_date AND view_datetime<top_date) A
            NATURAL JOIN (SELECT movie_title title, duration FROM movies) B);

   SELECT NVL(mins,0)+sum(B.avgduration*A.pct/100) INTO mins
      FROM (SELECT title,season,pct
            FROM (SELECT contractId FROM contracts WHERE clientId=cust) 
                 NATURAL JOIN taps_series
                 WHERE view_datetime>=low_date AND view_datetime<top_date) A
            NATURAL JOIN (SELECT title,season,avgduration FROM seasons) B;


-- Calculates total
total := tariff.fee + tariff.tap_cost*(ppcs+ppvs)+ tariff.ppm*nvl(mins,0) + tariff.ppd*days;  

-- We calculate when the promotion ends
SELECT MAX((nvl(enddate,sysdate)-startdate)/8+startdate) INTO promoends 
   FROM contracts 
   WHERE (clientId=cust) AND 
         ( (low_date BETWEEN startdate AND nvl(enddate,sysdate))
           OR ((top_date-1) BETWEEN startdate AND nvl(enddate,sysdate))
         );

-- And we substract the discount in case
 IF top_date<promoends THEN total:=total*((100-tariff.promo)/100); END IF;


RETURN trunc(nvl(total,0),2);

END;



CREATE OR REPLACE PROCEDURE billing (month IN NUMBER, year IN NUMBER) IS
  low_date DATE; 
  top_date DATE;
BEGIN
   low_date := TO_DATE(TO_CHAR(month)||'/'||TO_CHAR(year),'MM/YYYY'); 
   top_date := ADD_MONTHS(low_date,1) -1;
   
     INSERT INTO Invoices
       SELECT B.contractID, month, year, sysdate,bill(month,year,B.clientID,B.contract_type)
          FROM (SELECT clientID,MAX(startdate) startdate FROM Contracts 
                   WHERE ((low_date BETWEEN startdate AND NVL(enddate,sysdate)) 
                           OR (startdate BETWEEN low_date AND top_date))
                   GROUP BY clientID) A JOIN contracts B on A.clientID=B.clientID and A.startdate=B.startdate;
				   
	
	/* Note: you can't run this twice for the same month without deleting;
                 Thus, run each iteration with a different month: billing(N); */

EXCEPTION
   WHEN NO_DATA_FOUND THEN DBMS_OUTPUT.PUT_LINE('There are no billing data.');
   WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Billing is not possible');

END; 

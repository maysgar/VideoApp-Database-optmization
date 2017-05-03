CREATE OR REPLACE PROCEDURE billing ( 
P_Anio VARCHAR2,
P_Mes VARCHAR2
)
AS

/* The structure for the table INVOICES used in this procedure is given by the following creation script

CREATE TABLE invoices(
clientId VARCHAR2(15),  
month  VARCHAR2(2) ,
year  VARCHAR2(4) ,
amount NUMBER(8,2) NOT NULL,
CONSTRAINT PK_invcs PRIMARY KEY (clientId,month,year),
CONSTRAINT FK_invcs FOREIGN KEY (clientId) REFERENCES clients
);
if yours has a different structure, please make convenient changes to the INSERT /UPDATE commands below  */

   low_date DATE:= TO_DATE('01'||P_Mes||P_Anio, 'DDMMYYYY');   -- 1º día del mes pedido
   top_date DATE := ADD_MONTHS(TO_DATE('01'||P_Mes||P_Anio, 'DDMMYYYY'),1) -1;  -- último día del mes pedido

CosteTotal Number(6,2);
Facturado INTEGER;
Contador INTEGER :=0;

CURSOR Contratos_activos  IS
SELECT * FROM (
(SELECT clientID,MAX(startdate) startdate FROM Contracts 
                   WHERE ((low_date BETWEEN startdate AND NVL(enddate,sysdate)) 
                           OR (startdate BETWEEN low_date AND top_date) )
                   GROUP BY clientID)A
               NATURAL JOIN Contracts
);


BEGIN
-- Recuperamos todos los contratos activos en ese mes y año
		FOR I IN Contratos_Activos  LOOP

			CosteTotal:= bill (I.ClientID, P_Anio, P_Mes, I.Contract_Type);
			--Actualizamos la factura
			SELECT count(*) into Facturado 
			FROM Invoices WHERE ClientID= I.ClientId AND Year= TO_NUMBER(P_Anio) AND Month= TO_NUMBER(P_Mes);
			
			IF (FActurado=0) THEN
			
					INSERT INTO INVOICES (ClientId, Year, Month, Amount) VALUES(
						I.ClientID, TO_NUMBER(P_Anio),TO_NUMBER(P_Mes),CosteTotal );
			ELSE
					UPDATE INVOICES SET Amount= CosteTotal
					WHERE ClientID= I.ClientId AND Year= TO_NUMBER(P_Anio) AND Month= TO_NUMBER(P_Mes);
			END IF;
			
			Contador:= Contador+1;

		END LOOP;   -- Fin del recorrido de los contratos del mes
		
		DBMS_OUTPUT.PUT_LINE(' Contratos facturados en este mes:  ' || Contador);
		  
		  EXCEPTION
		  WHEN NO_DATA_FOUND THEN
				DBMS_OUTPUT.PUT_LINE ('No se encontraron  contratos activos  en esas fechas');
		
		  
		  WHEN OTHERS THEN
				DBMS_OUTPUT.PUT_LINE (SQLCODE ||'---'||SQLERRM);
			
  
  END billing;

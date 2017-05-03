CREATE OR REPLACE FUNCTION bill ( 
P_Cliente VARCHAR2,
P_Anio VARCHAR2,
P_Mes VARCHAR2,
P_TipoContrato VARCHAR2 ) RETURN  NUMBER
AS
-- Establezco cursores necesarios
Producto Products%ROWTYPE;
Contrato Contracts%ROWTYPE;

low_date DATE := TO_DATE('01'||P_Mes||P_Anio, 'DDMMYYYY');   -- 1º día del mes pedido
top_date DATE:= ADD_MONTHS(TO_DATE('01'||P_Mes||P_Anio, 'DDMMYYYY'),1) -1;  -- último día del mes pedido

CosteTotal Number(6,2);
CosteDia NUmber(4,2);
DiaMes INTEGER;
Duracion INTEGER;
Encontrada INTEGER;

CURSOR Visualizaciones (P_Contrato VARCHAR2, P_Anio VARCHAR2, P_MES Varchar2) IS
SELECT 'M' Tipo, Title,1 Season ,1 Episode, PCT, To_Number(to_char(View_Datetime, 'DD')) Dia
FROM TAPS_MOVIES
WHERE TO_CHAR(View_Datetime,'MMYYYY')= P_Mes||P_Anio AND ContractID=P_Contrato
UNION
SELECT 'S' Tipo, Title,Season,Episode, PCT,  To_Number(to_char(View_Datetime, 'DD')) Dia
FROM TAPS_SERIES
WHERE TO_CHAR(View_Datetime,'MMYYYY')= P_Mes||P_Anio AND ContractID=P_Contrato
ORDER BY Dia;

BEGIN
-- Recuperamos el primer contrato activo del cliente en ese mes
SELECT * INTO Contrato
FROM (
 SELECT * FROM Contracts 
 WHERE ((low_date BETWEEN startdate AND NVL(enddate,sysdate)) 
        OR (startdate BETWEEN low_date AND top_date) ) AND clientID= P_Cliente
ORDER BY startdate
) WHERE rownum <2;

--dbms_output.put_line(contrato.contractid);       --TRaza para controlar posibles errores

-- Recuperamos todos los datos del tipo de contrato que pasamos por parámetro
SELECT * INTO Producto
FROM Products
WHERE Product_Name= P_TipoContrato;

-- Imputamos el coste mensual
CosteTotal:= Producto.Fee;

-- Bucle para el recorrido de todas las visualizaciones del cliente
-- Comenzaremos por el primer día del mes, por tanto hacemos
DiaMes:=1;
CosteDia:=0;
FOR T IN Visualizaciones (Contrato.ContractID, P_Anio, P_Mes) LOOP
    -- Si Cambiamos de día de mes, inicializamos el coste de día
	--dbms_output.put_line('Titulo...'||T.Title);   Traza para control de errores
    IF (T.Dia <> DiaMes) THEN
        DiaMes:=T.Dia;
        CosteTotal:= CosteTotal+ CosteDia;
        CosteDia:=0; -- Lo inicializamos para el nuevo día
    END IF;
                
        -- Recuperamos la duración del contenido visualizado
        CASE T.Tipo
            WHEN 'M' THEN
              SELECT Duration INTO Duracion
              FROM Movies where Movie_Title=T.Title;
            WHEN 'S' THEN
              SELECT AvgDuration INTO Duracion
              FROM Seasons where Title=T.Title and Season=T.Season;
          END CASE;
          -- Ahora sumamos al coste los minutos visualizados
		  --dbms_output.put_line('Duracion...'||Duracion);   --Traza para control de errrores
          CosteTotal:= CosteTotal + Duracion*(T.PCT/100)* Producto.PPM;
        
         -- Si se supera el tiempo de Zapp, añadimos el resto de costes
		 
         IF (T.PCT > Producto.ZAPP ) THEN
              CosteDia:= Producto.PPD;
              -- Buscamos una licencia para este contenido con fecha de compra anterior al día 1 del mes
			  
			  -- Esta parte la añadimos dentro de un bloque BEGIN para que, si provoca una excepción, no implique salida del programa
			 BEGIN
				  CASE T.Tipo
					  WHEN 'M' THEN
						SELECT 1 INTO Encontrada
						FROM Lic_Movies 
						where Client=P_Cliente AND Title=T.Title
						AND DateTime< TO_DATE('01'||P_Mes||P_Anio, 'DDMMYYYY');
					  WHEN 'S' THEN
						SELECT 1 INTO Encontrada
						FROM Lic_Series
						where Client=P_Cliente 
						AND Title=T.Title AND Season=T.Season AND Episode=T.Episode
						AND DateTime< TO_DATE('01'||P_Mes||P_Anio, 'DDMMYYYY');
					END CASE;
					-- Si no encontramos la licencia, tenemos que cobrar el coste del contenido; el doble para una película
				EXCEPTION
					WHEN NO_DATA_FOUND THEN  
					
								CASE T.Tipo
										WHEN 'M' THEN
												CosteTotal:= CosteTotal + 2*Producto.Tap_cost;
										  
										WHEN 'S' THEN
												 CosteTotal:= CosteTotal + Producto.Tap_cost;
									  END CASE;
			
					END;
					
				
         
         END IF; -- Fin de las acciones si se supera el tiempo de Zapping para el contenido
 
END LOOP;   -- Fin del recorrido de las visualizaciones
  -- Determinamos ahora si procede realizar descuento por estar en el 1/8 inicial de la duración del contrato
  
  IF (Contrato. EndDate is NOT NULL AND  
        ( ADD_MONTHS(TO_DATE('01'||P_Mes||P_Anio, 'DDMMYYYY'),1)-Contrato.StartDate <= (Contrato.EndDate-Contrato.StartDate)/8 )) THEN
          CosteTotal:= CosteTotal* (1- NVL(Producto.Promo/100,0));
  END IF;
  
  Return CosteTotal;
  
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
		DBMS_OUTPUT.PUT_LINE ('No se encontraron visualizaciones o contratos activos de ese cliente en esas fechas');
		return -1;
  
  WHEN TOO_MANY_ROWS THEN
		DBMS_OUTPUT.PUT_LINE ('Hay duplicados, posiblemente del contrato para ese cliente');
		return -1;
  
  WHEN OTHERS THEN
		DBMS_OUTPUT.PUT_LINE (SQLCODE ||'---'||SQLERRM);
		return -1;
  
  END bill;

CREATE PROCEDURE sp_rdd_devuelve_dv(sBarraAux char(45))
RETURNING char(1);

DEFINE sBarra    	char(60);
DEFINE dv_barra   char(1);
DEFINE largo		int;
DEFINE i				int;
DEFINE totPar		int;
DEFINE totImp		int;

DEFINE sParte1 	char(10);
DEFINE largo1 		int;
DEFINE cParte1 	char(1);
	
DEFINE sParte2		char(10);
DEFINE largo2		int;

	LET largo = length(sBarraAux);
	LET totPar = 0;
	LET totImp = 0;
	LET i=1;
	
	FOR i= 1 TO largo
		IF mod(i,2) = 0 THEN
			LET totPar = totPar + to_number(substr(sBarraAux,i,1));
		ELSE
			LET totImp = totImp + to_number(substr(sBarraAux,i, 1));
		END IF;
	END FOR;

	LET sParte1 = trim(to_char((totImp * 3 + totPar)));
	LET largo1 = length(sParte1);
	LET cParte1 = substr(sParte1, largo1, 1);
	
	LET sParte2 = trim(to_char((10 - round(to_number(cParte1),0))));
	LET largo2 = length(sParte2);
	LET dv_barra = substr(sParte2, largo2, 1);

	RETURN dv_barra;
END PROCEDURE;

GRANT EXECUTE ON sp_rdd_devuelve_dv TO
superpjp, supersre, supersbl, supersc, corbacho,
guardt1, fuse,
ctousu, batchsyn, procbatc, "UCENTRO", "OVIRTUAL",
pjp, sreyes, sbl, ssalve, gtricoci,
pablop, aarrien, vdiaz, ldvalle, vaz;

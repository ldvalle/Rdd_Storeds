drop procedure rdd_existe_deuda;

CREATE PROCEDURE rdd_existe_deuda(
tipo_busqueda		char(25),
valor_busqueda		char(100))
RETURNING char(3) as codigo_retorno, char(50) as descripcion_retorno;

DEFINE numero_suministro 	char(8);
DEFINE nro_cliente_barra	char(8);
DEFINE codigo				char(3);
DEFINE descripcion 			char(250);
DEFINE nro_cliente			integer;
DEFINE nrows                integer;
                                        
	IF trim(tipo_busqueda) = 'nro_suministro' THEN
		LET nro_cliente = TO_NUMBER(valor_busqueda);
		
		-- ver que el cliente exista
		SELECT '0', 'OK sum'
		INTO codigo, descripcion
		FROM cliente c
		WHERE c.numero_cliente = nro_cliente;

	ELSE
		LET nro_cliente_barra=valor_busqueda[8,15];
		LET nro_cliente = TO_NUMBER(nro_cliente_barra);
		
		-- ver que el cliente exista
		SELECT '0', 'OK barra'
		INTO codigo, descripcion
		FROM cliente c
		WHERE c.numero_cliente = nro_cliente;
		
	END IF; 

    LET nrows = DBINFO('sqlca.sqlerrd2');
    
    IF nrows=0 THEN
        LET codigo = '003';
        LET descripcion = 'Cliente/Barra no existe';
    END IF;
    
	RETURN codigo, descripcion;

END PROCEDURE;

GRANT EXECUTE ON rdd_existe_deuda TO
superpjp, supersre, supersbl, supersc, corbacho,
guardt1, fuse,
ctousu, batchsyn, procbatc, "UCENTRO", "OVIRTUAL",
pjp, sreyes, sbl, ssalve, gtricoci,
pablop, aarrien, vdiaz, ldvalle, vaz;

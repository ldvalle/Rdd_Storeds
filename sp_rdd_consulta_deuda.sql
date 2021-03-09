drop procedure rdd_consulta_deuda;

CREATE PROCEDURE rdd_consulta_deuda(
codigo_empresa      integer,
tipo_busqueda		char(25),
valor_busqueda		char(100),
codigo_recaudador	char(20))
RETURNING char(3) as codigo_retorno, 
	char(50) as descripcion_retorno, 
	char(46) as cod_barra, 
	char(5) as tipo_deuda, 
	decimal(12,2) as monto_deuda,
	char(2) as tipo_documento,
	char(12) as nro_documento,
	char(10) as fecha_emision,
	char(10) as fecha_vencimiento,
	char(100) as nombre_cliente,
	char(1) as estado_cliente,
	char(80) as direccion,
    char(10) as mensaje,
    char(10) as publicidad;

DEFINE numero_suministro char(8);

DEFINE empresa_barra		char(3);
DEFINE sucursal_barra		char(2);
DEFINE plan_barra			char(2);
DEFINE nro_cliente_barra	char(8);
DEFINE importe_barra		char(9);
DEFINE vcto1_barra			char(6);
DEFINE recargo_barra		char(6);
DEFINE vcto2_barra			char(4);
DEFINE corr_factu_barra		char(3);
DEFINE tipo_mov_barra		char(2);
DEFINE dv_barra 			char(1);

DEFINE barra_aux1			char(45);
DEFINE dv_barra_aux1		char(1);

DEFINE nro_cliente			integer;
DEFINE dFechaVcto1			date;
DEFINE dFechaVcto2			date;
DEFINE sFechaVcto2			char(6);
DEFINE fMonto				float;
DEFINE fRecargo				float;
DEFINE barra_corr_factu     integer;

DEFINE cli_nombre			char(40);
DEFINE cli_estado_cliente	integer;
DEFINE cli_tipo_cliente		char(2);
DEFINE cli_est_cob			char(1);
DEFINE cli_corr_factu		integer;
DEFINE cli_tipo_fpago		char(1);
DEFINE cli_saldo			float;
DEFINE cli_calle			char(25);
DEFINE cli_altura			char(5);
DEFINE cli_piso				char(6);
DEFINE cli_depto			char(6);
DEFINE cli_partido			char(25);
DEFINE cli_comuna			char(25);

DEFINE len_barra			int;
DEFINE nrows				int;

DEFINE cod_gd				char(3);
DEFINE descri_gd			char(100);
DEFINE tope_recauda         decimal(12,2);

-- Valores a devolver
DEFINE ret_cod_barra 	char(46);
DEFINE ret_tipo_deuda	char(5);
DEFINE ret_monto_deuda	float;
DEFINE ret_tipo_documento 	char(2);
DEFINE ret_nro_documento	char(12);
DEFINE ret_fecha_emision	char(10);
DEFINE ret_fecha_vencimiento	char(10);
DEFINE ret_nombre_cliente		char(100);
DEFINE ret_estado_cliente		char(1);
DEFINE ret_direccion_sum		char(200);

    SET ISOLATION TO DIRTY READ;
    
    IF codigo_empresa != 4 THEN
        RETURN '013', 'EMPRESA INVALIDA','', '', 0, '', '', '', '', '', '', '', '', '';
    END IF;
    
	IF trim(tipo_busqueda) = 'nro_suministro' THEN
		LET nro_cliente = TO_NUMBER(valor_busqueda);
		
	ELIF trim(tipo_busqueda) = 'cod_barra' THEN
		-- validar la barra
		LET len_barra= LENGTH(valor_busqueda);
		IF (len_barra != 46) THEN
			RETURN '105', 'Longitud de barra incorrecto','', '', 0, '', '', '', '', '', '', '', '', '';
		END IF;
		
		LET empresa_barra=valor_busqueda[1,3];
		LET sucursal_barra=valor_busqueda[4,5];
		LET plan_barra=valor_busqueda[6,7];
		LET nro_cliente_barra=valor_busqueda[8,15];
		LET importe_barra=valor_busqueda[16,24];
		LET vcto1_barra=valor_busqueda[25,30];
		LET recargo_barra=valor_busqueda[31,36];
		LET vcto2_barra=valor_busqueda[37,40];
		LET corr_factu_barra=valor_busqueda[41,43];
		LET tipo_mov_barra=valor_busqueda[44,45];
		LET dv_barra=valor_busqueda[46,46];

		LET sFechaVcto2=valor_busqueda[25,26] || valor_busqueda[37,40]; 
		
		LET nro_cliente = TO_NUMBER(nro_cliente_barra);
		LET dFechaVcto1=TO_DATE(vcto1_barra, '%y%m%d');
		LET dFechaVcto2=TO_DATE(sFechaVcto2, '%y%m%d');
		
		LET fMonto = (TO_NUMBER(importe_barra)/100);
		LET fRecargo = (TO_NUMBER(recargo_barra)/100);
        LET barra_corr_factu = TO_NUMBER(corr_factu_barra);
		
		IF (tipo_mov_barra != '05') THEN
			IF (tipo_mov_barra != '06') THEN
				IF (tipo_mov_barra != '10') THEN
					IF (tipo_mov_barra != '96') THEN
						RETURN '105', 'Tipo de barra incorrecto','', '', 0, '', '', '', '', '', '', '', '', '';
					END IF;
				END IF;
			END IF;
		END IF;
	
        
		LET barra_aux1=valor_busqueda[1,45];
		EXECUTE PROCEDURE sp_rdd_devuelve_dv(barra_aux1) INTO dv_barra_aux1;
		
		IF dv_barra != dv_barra_aux1 THEN
			RETURN '105', 'Digito Verificador de barra incorrecto','', '', 0, '', '', '', '', '', '', '', '', '';
		END IF;
		
		LET ret_cod_barra=valor_busqueda;
		LET ret_tipo_deuda='BAR';
		LET ret_monto_deuda=to_char(fMonto);
		LET ret_tipo_documento=tipo_mov_barra;
		--LET ret_nro_documento='008080'; -- despues levantarlo del documento
		--LET ret_fecha_emision=to_char(dFechaVcto1, '%d/%m/%Y'); -- despues levantarlo del documento
		LET ret_fecha_vencimiento=to_char(dFechaVcto1, '%d/%m/%Y');
		
	ELSE
		RETURN '008', 'TIPO DE BUSQUEDA INCORRECTO.','', '', 0, '', '', '', '', '', '', '', '', '';
	END IF; 

	-- ver que el cliente exista
	SELECT c.nombre, c.estado_cliente, c.tipo_cliente, c.estado_cobrabilida, c.corr_facturacion, c.tipo_fpago,
	(saldo_actual+saldo_int_acum+saldo_imp_suj_int+saldo_imp_no_suj_i-valor_anticipo),
	trim(c.nom_calle), trim(c.nro_dir), nvl(c.piso_dir, ' '), nvl(c.depto_dir, ' '), trim(c.nom_partido), trim(c.nom_comuna)
	INTO
		cli_nombre,
		cli_estado_cliente,
		cli_tipo_cliente,
		cli_est_cob,
		cli_corr_factu,
		cli_tipo_fpago,
		cli_saldo,
		cli_calle,
		cli_altura,
		cli_piso,
		cli_depto,
		cli_partido,
		cli_comuna
	FROM cliente c
	WHERE c.numero_cliente = nro_cliente;

	LET nrows = DBINFO('sqlca.sqlerrd2');
	IF nrows = 0 THEN
		RETURN '003', 'Cliente/Barra no existe.','', '', 0, '', '', '', '', '', '', '', '', '';
	END IF;
	
    IF trim(tipo_busqueda) = 'cod_barra' THEN
        IF tipo_mov_barra = '06' OR tipo_mov_barra = '96' THEN
            IF barra_corr_factu != cli_corr_factu THEN
                RETURN '021', 'CLIENTE COMUNICARSE CON ATE.COMERCIAL ENEL','', '', 0, '', '', '', '', '', '', '', '', '';
            END IF;
        END IF;
    END IF;

	LET ret_nombre_cliente=cli_nombre;
	LET ret_estado_cliente=cli_estado_cliente;
	LET ret_direccion_sum= 'Calle ' || trim(cli_calle) || ' ' || trim(cli_altura) || ' Piso ' || trim(cli_piso) || ' Dpto ' || trim(cli_depto) || ' Partido ' || trim(cli_partido) || ' Comuna ' || trim(cli_comuna);
	-- ver que tenga deuda 
	IF cli_saldo <= 0 THEN
		RETURN '005', 'SIN DEUDA VIGENTE.','', '', 0, '', '', '', '', '', '', '', '', '';
	END IF;
	
	-- ver el tipo cliente
	IF cli_tipo_cliente = 'OM' THEN
		RETURN '021', 'CLIENTE COMUNICARSE CON ATE.COMERCIAL ENEL','', '', 0, '', '', '', '', '', '', '', '', '';
	ELIF cli_tipo_cliente = 'OP' THEN
		RETURN '021', 'CLIENTE COMUNICARSE CON ATE.COMERCIAL ENEL','', '', 0, '', '', '', '', '', '', '', '', '';
	ELIF cli_tipo_cliente = 'ON' THEN
		RETURN '021', 'CLIENTE COMUNICARSE CON ATE.COMERCIAL ENEL','', '', 0, '', '', '', '', '', '', '', '', '';
	ELIF cli_tipo_cliente = 'AP' THEN
		RETURN '021', 'CLIENTE COMUNICARSE CON ATE.COMERCIAL ENEL','', '', 0, '', '', '', '', '', '', '', '', '';
	END IF;	
	
	-- Ver lo del estado de cobrabilidad
	
	IF trim(tipo_busqueda) = 'nro_suministro' THEN
		-- en este caso tengo que levantar la ultima factura.
		EXECUTE PROCEDURE rdd_get_ultifactu(nro_cliente) INTO ret_cod_barra, ret_monto_deuda, ret_nro_documento, ret_fecha_emision, ret_fecha_vencimiento;
		
		LET ret_tipo_deuda='UF';
		LET ret_tipo_documento=ret_cod_barra[44,45];
	ELSE
		-- en este caso, tengo que recuperar el documento origen de la barra.
		EXECUTE PROCEDURE rdd_get_documento(valor_busqueda) INTO cod_gd, descri_gd, ret_monto_deuda, ret_nro_documento, ret_fecha_emision, ret_fecha_vencimiento;
		
		IF cod_gd != '0' THEN
			RETURN cod_gd, descri_gd,'', '', 0, '', '', '', '', '', '', '', '', '';
		END IF;
		
		LET ret_tipo_deuda='BAR';
	END IF

	-- ver lo del ente recaudador
    SELECT monto_tope INTO tope_recauda FROM rdd_recaudadores
    WHERE cod_recaudador = codigo_recaudador
    AND tarifa = 'T1'
    AND tipo_documento = ret_tipo_documento
    AND fecha_activacion <= TODAY
    AND (fecha_desactivac IS NULL OR fecha_desactivac > TODAY);

	LET nrows = DBINFO('sqlca.sqlerrd2');
	IF nrows = 0 THEN
		RETURN '010', 'RECAUDADOR INVALIDO.','', '', 0, '', '', '', '', '', '', '', '', '';
	END IF;
	
    IF ret_monto_deuda > tope_recauda THEN
        RETURN '021', 'CLIENTE COMUNICARSE CON ATE.COMERCIAL ENEL','', '', 0, '', '', '', '', '', '', '', '', '';
    END IF;
    
	RETURN '0', 'OK', ret_cod_barra, ret_tipo_deuda, round(ret_monto_deuda,2), ret_tipo_documento, ret_nro_documento, ret_fecha_emision, ret_fecha_vencimiento, ret_nombre_cliente, ret_estado_cliente, ret_direccion_sum, '', '';

END PROCEDURE;

GRANT EXECUTE ON rdd_consulta_deuda TO
superpjp, supersre, supersbl, supersc, corbacho,
guardt1, fuse,
ctousu, batchsyn, procbatc, "UCENTRO", "OVIRTUAL",
pjp, sreyes, sbl, ssalve, gtricoci,
pablop, aarrien, vdiaz, ldvalle, vaz;

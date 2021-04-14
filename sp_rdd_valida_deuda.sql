drop procedure rdd_valida_deuda;

CREATE PROCEDURE rdd_valida_deuda(
codigo_empresa      integer,
tipo_busqueda		char(25),
valor_busqueda		char(100),
codigo_recaudador	char(20))
RETURNING char(3) as codigo_retorno, char(50) as descripcion_retorno;

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
DEFINE fechaTope            date;

-- Valores a recuperar
DEFINE aux_cod_barra 	char(46);
DEFINE aux_tipo_deuda	char(5);
DEFINE aux_monto_deuda	float;
DEFINE aux_tipo_documento 	char(2);
DEFINE aux_nro_documento	char(12);
DEFINE aux_fecha_emision	char(10);
DEFINE aux_fecha_vencimiento	char(10);

    SET ISOLATION TO DIRTY READ;
    
    IF codigo_empresa != 4 THEN
        RETURN '013', 'EMPRESA INVALIDA';
    END IF;
    
	IF trim(tipo_busqueda) = 'nro_suministro' THEN
		LET nro_cliente = TO_NUMBER(valor_busqueda);
		
	ELIF trim(tipo_busqueda) = 'cod_barra' THEN
		-- validar la barra
        SELECT TODAY - valor INTO fechaTope FROM tabla 
        WHERE nomtabla = 'RDDIAS'
        AND codigo = '1'
        AND sucursal = '0000'
        AND fecha_activacion <= TODAY
        AND (fecha_desactivac IS NULL OR fecha_desactivac > TODAY);
        
		LET len_barra= LENGTH(valor_busqueda);
		IF (len_barra != 46) THEN
			RETURN '105', 'LONGITUD DE BARRA INCORRECTO';
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
						RETURN '105', 'LONGITUD DE BARRA INCORRECTO';
					END IF;
				END IF;
			END IF;
		END IF;
	
        IF (dFechaVcto1 < fechaTope) THEN
            RETURN '021', 'ESTIMADO CLIENTE FAVOR DE COMUNICARSE CON ATE.COMERCIAL ENEL';
        END IF;
        
		LET barra_aux1=valor_busqueda[1,45];
		EXECUTE PROCEDURE sp_rdd_devuelve_dv(barra_aux1) INTO dv_barra_aux1;
		
		IF dv_barra != dv_barra_aux1 THEN
			RETURN '105', 'DIGITO VERIFICADOR DE BARRA INCORRECTO';
		END IF;
		LET aux_tipo_documento=tipo_mov_barra;
	ELSE
		RETURN '008', 'TIPO DE BUSQUEDA INCORRECTO.';
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
		RETURN '003', 'CLIENTE/BARRA NO EXISTE';
	END IF;
	
    IF trim(tipo_busqueda) = 'cod_barra' THEN
        IF tipo_mov_barra = '06' OR tipo_mov_barra = '96' THEN
            IF barra_corr_factu != cli_corr_factu THEN
                RETURN '021', 'ESTIMADO CLIENTE FAVOR DE COMUNICARSE CON ATE.COMERCIAL ENEL';
            END IF;
        END IF;
    END IF;

	-- ver que tenga deuda 
	IF cli_saldo <= 0 THEN
		RETURN '005', 'SIN DEUDA VIGENTE.';
	END IF;
	
	-- ver el tipo cliente
	IF cli_tipo_cliente = 'OM' THEN
		RETURN '021', 'ESTIMADO CLIENTE FAVOR DE COMUNICARSE CON ATE.COMERCIAL ENEL';
	ELIF cli_tipo_cliente = 'OP' THEN
		RETURN '021', 'ESTIMADO CLIENTE FAVOR DE COMUNICARSE CON ATE.COMERCIAL ENEL';
	ELIF cli_tipo_cliente = 'ON' THEN
		RETURN '021', 'ESTIMADO CLIENTE FAVOR DE COMUNICARSE CON ATE.COMERCIAL ENEL';
	ELIF cli_tipo_cliente = 'AP' THEN
		RETURN '021', 'ESTIMADO CLIENTE FAVOR DE COMUNICARSE CON ATE.COMERCIAL ENEL';
	END IF;	
	
	-- Ver lo del estado de cobrabilidad
    SELECT COUNT(*) INTO nrows FROM tabla
    WHERE nomtabla = 'RDDECO'
    AND sucursal = '0000'
    AND codigo = cli_est_cob
    AND fecha_activacion <= TODAY
    AND (fecha_desactivac IS NULL OR fecha_desactivac > TODAY);
    
    IF nrows > 0 THEN
        RETURN '021', 'ESTIMADO CLIENTE FAVOR DE COMUNICARSE CON ATE.COMERCIAL ENEL';
    END IF;
	
	IF trim(tipo_busqueda) = 'nro_suministro' THEN
		-- en este caso tengo que levantar la ultima factura.
		EXECUTE PROCEDURE rdd_get_ultifactu(nro_cliente) INTO aux_cod_barra, aux_monto_deuda, aux_nro_documento, aux_fecha_emision, aux_fecha_vencimiento;
		
		LET aux_tipo_deuda='UF';
		LET aux_tipo_documento=aux_cod_barra[44,45];
	ELSE
		-- en este caso, tengo que recuperar el documento origen de la barra.
		EXECUTE PROCEDURE rdd_get_documento(valor_busqueda) INTO cod_gd, descri_gd, aux_monto_deuda, aux_nro_documento, aux_fecha_emision, aux_fecha_vencimiento;
		
		IF cod_gd != '0' THEN
			RETURN cod_gd, descri_gd;
		END IF;
		
		LET aux_tipo_deuda='BAR';
	END IF

	-- ver lo del ente recaudador
    SELECT monto_tope INTO tope_recauda FROM rdd_recaudadores
    WHERE cod_recaudador = codigo_recaudador
    AND tarifa = 'T1'
    AND tipo_documento = aux_tipo_documento
    AND fecha_activacion <= TODAY
    AND (fecha_desactivac IS NULL OR fecha_desactivac > TODAY);

	LET nrows = DBINFO('sqlca.sqlerrd2');
	IF nrows = 0 THEN
		RETURN '010', 'RECAUDADOR INVALIDO.';
	END IF;
	
    IF aux_monto_deuda > tope_recauda THEN
        RETURN '021', 'ESTIMADO CLIENTE FAVOR DE COMUNICARSE CON ATE.COMERCIAL ENEL';
    END IF;

	RETURN '000', 'OK';
		
END PROCEDURE;

GRANT EXECUTE ON rdd_valida_deuda TO
superpjp, supersre, supersbl, supersc, corbacho,
guardt1, fuse,
ctousu, batchsyn, procbatc, "UCENTRO", "OVIRTUAL",
pjp, sreyes, sbl, ssalve, gtricoci,
pablop, aarrien, vdiaz, ldvalle, vaz;

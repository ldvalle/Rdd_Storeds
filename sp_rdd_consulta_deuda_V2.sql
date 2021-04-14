drop procedure rdd_consulta_deuda_v2;

CREATE PROCEDURE rdd_consulta_deuda_v2(
codigo_empresa      integer,
tipo_busqueda		char(25),
valor_busqueda		char(100),
codigo_recaudador	char(20))
RETURNING char(46) as cod_barra, 
	char(5) as tipo_deuda, 
	decimal(12,2) as monto_deuda,
	char(2) as tipo_documento,
	char(12) as numero_documento,
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

-- Valores a insertar
DEFINE aux_cod_barra 	char(46);
DEFINE aux_tipo_deuda	char(5);
DEFINE aux_monto_deuda	float;
DEFINE aux_tipo_documento 	char(2);
DEFINE aux_nro_documento	char(12);
DEFINE aux_fecha_emision	char(10);
DEFINE aux_fecha_vencimiento	char(10);
DEFINE aux_nombre_cliente		char(100);
DEFINE aux_estado_cliente		char(1);
DEFINE aux_direccion_sum		char(200);

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


	ON EXCEPTION IN (-206)  --tabal no encontrada
	END EXCEPTION WITH RESUME;
    
    drop table tempo1;

    CREATE TEMP TABLE tempo1 (
		cod_barra	char(46), 
		tipo_deuda	char(5), 
		monto_deuda	decimal(12,2),
		tipo_documento	char(2),
		nro_documento	char(12),
		fecha_emision	char(10),
		fecha_vencimiento	char(10),
		nombre_cliente	char(100),
		estado_cliente	char(1),
		direccion	char(80)
    )WITH NO LOG;
    
	IF trim(tipo_busqueda) = 'nro_suministro' THEN
		LET nro_cliente = TO_NUMBER(valor_busqueda);
		
	ELSE
		-- validar la barra
		LET len_barra= LENGTH(valor_busqueda);
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
		
		LET aux_cod_barra=valor_busqueda;
		LET aux_tipo_deuda='BAR';
		LET aux_monto_deuda=to_char(fMonto);
		LET aux_tipo_documento=tipo_mov_barra;
		LET aux_fecha_vencimiento=to_char(dFechaVcto1, '%d/%m/%Y');

	END IF; 

	SET ISOLATION TO DIRTY READ;
	    
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

	LET aux_nombre_cliente=cli_nombre;
	LET aux_estado_cliente=cli_estado_cliente;
	LET aux_direccion_sum= 'Calle ' || trim(cli_calle) || ' ' || trim(cli_altura) || ' Piso ' || trim(cli_piso) || ' Dpto ' || trim(cli_depto) || ' Partido ' || trim(cli_partido) || ' Comuna ' || trim(cli_comuna);
	
	IF trim(tipo_busqueda) = 'nro_suministro' THEN
		-- en este caso tengo que levantar la ultima factura.
		EXECUTE PROCEDURE rdd_get_ultifactu(nro_cliente) INTO aux_cod_barra, aux_monto_deuda, aux_nro_documento, aux_fecha_emision, aux_fecha_vencimiento;
		
		LET aux_tipo_deuda='UF';
		LET aux_tipo_documento=aux_cod_barra[44,45];
	ELSE
		-- en este caso, tengo que recuperar el documento origen de la barra.
		EXECUTE PROCEDURE rdd_get_documento(valor_busqueda) INTO cod_gd, descri_gd, aux_monto_deuda, aux_nro_documento, aux_fecha_emision, aux_fecha_vencimiento;
		
		IF cod_gd != '0' THEN
			RETURN '', '', 0, '', '', '', '', '', '', '', '', '';
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


    -- insertar data en la temporal
    INSERT INTO tempo1(
		cod_barra, tipo_deuda, monto_deuda, tipo_documento, nro_documento, fecha_emision,
		fecha_vencimiento, nombre_cliente , estado_cliente, direccion
		)VALUES(
		aux_cod_barra, aux_tipo_deuda, aux_monto_deuda, aux_tipo_documento, aux_nro_documento, aux_fecha_emision,
		aux_fecha_vencimiento, aux_nombre_cliente, aux_estado_cliente, aux_direccion_sum);
{		
    -- si corresponde calcular sin saldo anterior y grabar en la temporal
    IF trim(tipo_busqueda) = 'nro_suministro' THEN
		EXECUTE PROCEDURE rdd_get_ultifactu_ss(nro_cliente) INTO aux_cod_barra, aux_monto_deuda, aux_nro_documento, aux_fecha_emision, aux_fecha_vencimiento;

		-- insertar data en la temporal
		INSERT INTO tempo1(
			cod_barra, tipo_deuda, monto_deuda, tipo_documento, nro_documento, fecha_emision,
			fecha_vencimiento, nombre_cliente , estado_cliente, direccion
			)VALUES(
			aux_cod_barra, aux_tipo_deuda, aux_monto_deuda, aux_tipo_documento, aux_nro_documento, aux_fecha_emision,
			aux_fecha_vencimiento, aux_nombre_cliente, aux_estado_cliente, aux_direccion_sum);
		
    ELIF tipo_mov_barra = '06' THEN
		EXECUTE PROCEDURE rdd_get_documento_ss(valor_busqueda) INTO cod_gd, descri_gd, aux_monto_deuda, aux_nro_documento, aux_fecha_emision, aux_fecha_vencimiento;

		-- insertar data en la temporal
		INSERT INTO tempo1(
			cod_barra, tipo_deuda, monto_deuda, tipo_documento, nro_documento, fecha_emision,
			fecha_vencimiento, nombre_cliente , estado_cliente, direccion
			)VALUES(
			aux_cod_barra, aux_tipo_deuda, aux_monto_deuda, aux_tipo_documento, aux_nro_documento, aux_fecha_emision,
			aux_fecha_vencimiento, aux_nombre_cliente, aux_estado_cliente, aux_direccion_sum);
		
    END IF;
}

	FOREACH
	
		SELECT cod_barra, tipo_deuda, monto_deuda, tipo_documento, nro_documento, fecha_emision,
			fecha_vencimiento, nombre_cliente , estado_cliente, direccion
		INTO ret_cod_barra, ret_tipo_deuda, ret_monto_deuda, ret_tipo_documento, ret_nro_documento, 
			ret_fecha_emision, ret_fecha_vencimiento, ret_nombre_cliente, ret_estado_cliente, ret_direccion_sum
		FROM tempo1
		
		RETURN ret_cod_barra, ret_tipo_deuda, round(ret_monto_deuda,2), ret_tipo_documento, ret_nro_documento, ret_fecha_emision, ret_fecha_vencimiento, ret_nombre_cliente, ret_estado_cliente, ret_direccion_sum, '', '' WITH RESUME;
		
	END FOREACH

END PROCEDURE;

GRANT EXECUTE ON rdd_consulta_deuda_v2 TO
superpjp, supersre, supersbl, supersc, corbacho,
guardt1, fuse,
ctousu, batchsyn, procbatc, "UCENTRO", "OVIRTUAL",
pjp, sreyes, sbl, ssalve, gtricoci,
pablop, aarrien, vdiaz, ldvalle, vaz;

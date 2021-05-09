DROP PROCEDURE rdd_get_documento;
 
CREATE PROCEDURE rdd_get_documento(valor_busqueda char(46))
RETURNING char(3) as codigo, 
char(100) as descri, 
float as monto, 
char(12) as nro_documento, 
char(10) as fecha_emision, 
char(10) as fecha_vcto; 

DEFINE ret_monto_deuda	float;
DEFINE ret_nro_documento	char(12);
DEFINE ret_fecha_emision	char(10);
DEFINE ret_fecha_vencimiento	char(10);

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

DEFINE nro_cliente			integer;
DEFINE dFechaVcto1			date;
DEFINE dFechaVcto2			date;
DEFINE sFechaVcto2			char(6);
DEFINE fMonto				float;
DEFINE fRecargo				float;
DEFINE dFecha_actual		date;
DEFINE dFecha_emision		date;
DEFINE icorrelativo			int;
DEFINE nrows				int;
DEFINE ndias				int;
DEFINE sNroDocumento		char(12);

    SET ISOLATION TO DIRTY READ;
    
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
	
	LET nro_cliente = TO_NUMBER(nro_cliente_barra);
	LET dFechaVcto1=TO_DATE(vcto1_barra, '%y%m%d');
    
    IF vcto2_barra != '0000' THEN
        LET sFechaVcto2=valor_busqueda[25,26] || valor_busqueda[37,40];
        LET dFechaVcto2=TO_DATE(sFechaVcto2, '%y%m%d');
    ELSE
        LET dFechaVcto2=dFechaVcto1;
    END IF;
	
	LET fMonto = (TO_NUMBER(importe_barra)/100);
	LET fRecargo = (TO_NUMBER(recargo_barra)/100);
	LET icorrelativo=TO_NUMBER(corr_factu_barra);
	
	SELECT TODAY INTO dFecha_actual FROM dual;
	
	IF tipo_mov_barra = '05' THEN
		-- Pago anticipo Convenio
		SELECT fecha_creacion, fecha_vto_1 INTO dFecha_emision, dFechaVcto1
		FROM conve
		WHERE numero_cliente = nro_cliente
		AND nro_docto = icorrelativo
		AND estado = 'S';

		LET nrows = DBINFO('sqlca.sqlerrd2');
		IF nrows=0 THEN
			RETURN '110', 'Cliente no tiene convenio solicitado', 0, '', '', '';
		END IF;
		
		LET ret_monto_deuda=fMonto;
		LET ret_nro_documento= lpad(nro_cliente,8, '0') || lpad(icorrelativo, 4, '0');
		LET ret_fecha_emision=to_char(dFecha_emision, '%d/%m/%Y');
		LET ret_fecha_vencimiento=to_char(dFechaVcto1, '%d/%m/%Y');
		
	ELIF tipo_mov_barra = '06' OR tipo_mov_barra = '96' THEN
		-- Factura energia
		SELECT fecha_facturacion, fecha_vencimiento1, fecha_vencimiento2, centro_emisor || tipo_docto || lpad(numero_factura, 8, '0')
		INTO dFecha_emision, dFechaVcto1, dFechaVcto2, sNroDocumento
		FROM hisfac
		WHERE numero_cliente = nro_cliente
		AND corr_facturacion = icorrelativo;
		
		LET nrows = DBINFO('sqlca.sqlerrd2');
		IF nrows=0 THEN
			RETURN '111', 'No se encuentra factura asociada a la barra.', 0, '', '', '';
		END IF;	
		
		LET ret_fecha_emision=to_char(dFecha_emision, '%d/%m/%Y');
		LET ret_nro_documento= sNroDocumento;
		
		IF dFechaVcto1 < dFecha_actual THEN
			LET ret_monto_deuda=fMonto + fRecargo;
			LET ret_fecha_vencimiento=to_char(dFechaVcto2, '%d/%m/%Y');
		ELSE
			LET ret_monto_deuda=fMonto;
			LET ret_fecha_vencimiento=to_char(dFechaVcto2, '%d/%m/%Y');		
		END IF;
		
		
	ELIF tipo_mov_barra = '10' OR tipo_mov_barra = '45' THEN
		-- pvd ó pcp
		
		SELECT round(valor,0) INTO ndias
		FROM tabla
		WHERE sucursal = '0000'
		AND nomtabla = 'COMPAG'
		AND codigo   = 'EXTERN'
		AND fecha_activacion  <= TODAY
		AND (fecha_desactivac  > TODAY OR fecha_desactivac IS NULL);

		LET nrows = DBINFO('sqlca.sqlerrd2');
		IF nrows=0 THEN
			LET ndias=0;
		END IF;
		
		SELECT lpad(l1.numero_cliente, 8, '0') || lpad(l1.nro_comprob, 4, '0'), l1.fecha_emision
		INTO sNroDocumento, dFecha_emision
		FROM log_comprob l1
		WHERE l1.numero_cliente = nro_cliente
		AND l1.tipo_comprob = tipo_mov_barra
		AND l1.nro_comprob = icorrelativo
		AND l1.monto_comprob = fMonto
		AND l1.fecha_anulacion IS NULL
		AND l1.fecha_pago IS NULL
		AND l1.fecha_emision = (SELECT MAX(l2.fecha_emision) FROM log_comprob l2
				WHERE l2.numero_cliente = l1.numero_cliente
				AND l2.tipo_comprob = tipo_mov_barra
				AND l2.nro_comprob = l1.nro_comprob
				AND l2.monto_comprob = l1.monto_comprob
				AND l2.fecha_anulacion IS NULL
				AND l2.fecha_pago IS NULL
				AND l2.fecha_emision BETWEEN (TODAY - ndias) AND TODAY);

		LET nrows = DBINFO('sqlca.sqlerrd2');
		IF nrows=0 THEN
			RETURN '112', 'No se encuentra documento asociado a la barra.', 0, '', '', '';
		END IF;
				
		LET ret_monto_deuda=fMonto;
		LET ret_nro_documento= sNroDocumento;
		LET ret_fecha_emision=to_char(dFecha_emision, '%d/%m/%Y');
		LET ret_fecha_vencimiento=to_char(dFecha_actual, '%d/%m/%Y');
		
	ELSE
		RETURN '105', 'Tipo de barra invalida', 0, '', '', '';
	END IF;


RETURN '0', 'OK', ret_monto_deuda, ret_nro_documento, ret_fecha_emision, ret_fecha_vencimiento;

END PROCEDURE;

GRANT EXECUTE ON rdd_get_documento TO
superpjp, supersre, supersbl, supersc, corbacho,
guardt1, fuse,
ctousu, batchsyn, procbatc, "UCENTRO", "OVIRTUAL",
pjp, sreyes, sbl, ssalve, gtricoci,
pablop, aarrien, vdiaz, ldvalle, vaz;

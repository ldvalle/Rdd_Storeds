drop procedure rdd_get_ultifactu;

CREATE PROCEDURE rdd_get_ultifactu(nro_cliente int)
RETURNING char(46) as barra, float as monto, char(12) as nro_documento, char(10) as fecha_emision, char(10) as fecha_vcto; 

DEFINE ret_cod_barra	char(46);
DEFINE ret_monto_deuda	float;
DEFINE ret_nro_documento	char(12);
DEFINE ret_fecha_emision	char(10);
DEFINE ret_fecha_vencimiento	char(10);

DEFINE h_fecha_actual	date;
DEFINE h_corr_factu	int;
DEFINE h_centro_emisor	char(2);
DEFINE h_tipo_docto	char(2);
DEFINE h_nro_factura int;
DEFINE h_total_a_pagar decimal(12,2);
DEFINE h_suma_recargo	decimal(12,2);
DEFINE h_fecha_facturacion	date;
DEFINE h_fecha_vcto1	date;
DEFINE h_fecha_vcto2	date;
DEFINE c_cliente_fmt	char(8);
DEFINE c_cliente_sucur	char(2);
DEFINE c_cliente_plan	char(2);
DEFINE h_saldo_anterior decimal(12,2);

DEFINE r_suma_recargo	float;

DEFINE barra_aux		char(45);
DEFINE dv				char(1);
DEFINE fecha_vcto1_fmt	char(6);
DEFINE fecha_vcto2_fmt  char(4);
DEFINE recargo_barra	float;
DEFINE tipo_movimiento	char(2);
DEFINE nvoMontoBarra	float;
DEFINE nvoRecargoBarra	float;
DEFINE nrows			int;


	SELECT TODAY, h.corr_facturacion, h.centro_emisor, h.tipo_docto, h.numero_factura, 
	h.total_a_pagar, round(h.suma_recargo,2), h.fecha_facturacion, h.fecha_vencimiento1, h.fecha_vencimiento2,
	LPAD(c.numero_cliente, 8, '0'), c.sucursal[3,4], LPAD(c.sector, 2, '0'), h.saldo_anterior
	INTO h_fecha_actual, h_corr_factu, h_centro_emisor, h_tipo_docto, h_nro_factura,
		h_total_a_pagar, h_suma_recargo, h_fecha_facturacion, h_fecha_vcto1, h_fecha_vcto2,
		c_cliente_fmt, c_cliente_sucur, c_cliente_plan, h_saldo_anterior
	FROM cliente c, hisfac h
	WHERE c.numero_cliente = nro_cliente
	AND h.numero_cliente = c.numero_cliente
	AND h.corr_facturacion = c.corr_facturacion;

	LET nrows = DBINFO('sqlca.sqlerrd2');
	IF nrows = 0 THEN
		RETURN '', 0, '', '', '';
	END IF;
	
	
	IF h_suma_recargo <= 0 THEN
		SELECT SUM(valor_cargo) INTO r_suma_recargo FROM recargo
		WHERE numero_cliente = nro_cliente
		AND corr_fact = h_corr_factu;
	
		LET recargo_barra=round(r_suma_recargo, 2);
	ELSE
		LET recargo_barra=h_suma_recargo;
	END IF;

	IF h_fecha_vcto1 < h_fecha_actual THEN
		IF h_suma_recargo > 0 THEN
			LET ret_monto_deuda=h_total_a_pagar;
			LET ret_fecha_vencimiento= to_char(h_fecha_vcto2, '%d/%m/%Y');
			LET nvoMontoBarra=h_total_a_pagar - h_suma_recargo;
			LET nvoRecargoBarra=h_suma_recargo;
		ELSE
			LET ret_monto_deuda=h_total_a_pagar + NVL(r_suma_recargo, 0);
			LET ret_fecha_vencimiento= to_char(h_fecha_vcto2, '%d/%m/%Y');
			LET nvoMontoBarra=h_total_a_pagar;
			LET nvoRecargoBarra=recargo_barra;			
		END IF;
	ELSE
		LET ret_monto_deuda=h_total_a_pagar;
		LET ret_fecha_vencimiento= to_char(h_fecha_vcto1, '%d/%m/%Y');
		LET nvoMontoBarra=h_total_a_pagar;
		LET nvoRecargoBarra=recargo_barra;
	END IF;
	
	LET ret_nro_documento=h_centro_emisor || h_tipo_docto || LPAD(h_nro_factura, 8, '0');
	LET ret_fecha_emision=TO_CHAR(h_fecha_facturacion, '%d/%m/%Y');
	LET fecha_vcto1_fmt=TO_CHAR(h_fecha_vcto1, '%y%m%d');
	LET fecha_vcto2_fmt=TO_CHAR(h_fecha_vcto2, '%m%d');
	
	IF h_saldo_anterior > 0 THEN
		LET tipo_movimiento='96';
	ELSE
		LET tipo_movimiento='06';
	END IF;
	
	-- Tengo que armar la barra
	LET barra_aux = '009'|| c_cliente_sucur || c_cliente_plan || 
			c_cliente_fmt ||
			lpad(round((nvoMontoBarra * 100),0), 9, '0') || fecha_vcto1_fmt || lpad(round((nvl(nvoRecargoBarra,0) * 100),0), 6, '0') ||
			fecha_vcto2_fmt || lpad(h_corr_factu, 3, '0') || tipo_movimiento ;
	
	EXECUTE PROCEDURE sp_rdd_devuelve_dv(barra_aux) INTO dv;
	
	LET ret_cod_barra=barra_aux || dv;
	
	RETURN ret_cod_barra, ret_monto_deuda, ret_nro_documento, ret_fecha_emision, ret_fecha_vencimiento;

END PROCEDURE;

GRANT EXECUTE ON rdd_get_ultifactu TO
superpjp, supersre, supersbl, supersc, corbacho,
guardt1, fuse,
ctousu, batchsyn, procbatc, "UCENTRO", "OVIRTUAL",
pjp, sreyes, sbl, ssalve, gtricoci,
pablop, aarrien, vdiaz, ldvalle, vaz;

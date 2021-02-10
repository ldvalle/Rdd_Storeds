CREATE PROCEDURE rdd_get_ultifactu(nro_cliente int)
RETURNING char(3) as codigo_retorno, char(250) as descripcion_retorno;
RETURNING char(46) as barra, float as monto, char(8) as nro_documento, date as fecha_emision, date as fecha_vcto; 

DEFINE ret_cod_barra	char(46);
DEFINE ret_monto_deuda	float;
DEFINE ret_nro_documento	char(8);
DEFINE ret_fecha_emision	date;
DEFINE ret_fecha_vencimiento	date;

DEFINE h_fecha_actual;
DEFINE h_corr_factu	int;
DEFINE h_centro_emisor	char(2);
DEFINE h_tipo_docto	char(2);
DEFINE h_nro_factura int;
DEFINE h_total_a_pagar decimal(12,2);
DEFINE h_suma_recargo	decimal(12,2);
DEFINE h_fecha_facturacion	date;
DEFINE h_fecha_vcto1	date;


	SELECT TODAY, h.corr_facturacion, h.centro_emisor, h.tipo_docto, h.numero_factura, 
	h.total_a_pagar, h.suma_recargo, h.fecha_facturacion, h.fecha_vencimiento1
	INTO h_fecha_actual, h_corr_factu, h_centro_emisor, h_tipo_docto, h_nro_factura,
		h_total_a_pagar, h_suma_recargo, h_fecha_facturacion, h_fecha_vcto1
	FROM cliente c, hisfac h
	WHERE c.numero_cliente = nro_cliente
	AND h.numero_cliente = c.numero_cliente
	AND h.corr_facturacion = c.corr_facturacion;

	RETURN ret_cod_barra, ret_monto_deuda, ret_nro_documento, ret_fecha_emision, ret_fecha_vencimiento;

END PROCEDURE;

GRANT EXECUTE ON rdd_get_ultifactu TO
superpjp, supersre, supersbl, supersc, corbacho,
guardt1, fuse,
ctousu, batchsyn, procbatc, "UCENTRO", "OVIRTUAL",
pjp, sreyes, sbl, ssalve, gtricoci,
pablop, aarrien, vdiaz, ldvalle, vaz;

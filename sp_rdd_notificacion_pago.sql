drop procedure rdd_notificacion_pago;

CREATE PROCEDURE rdd_notificacion_pago(
codigo_empresa      	integer,
codigoRecaudador		char(20),
codigoOficinaRecaudador	char(4),
codigoCajaRecaudador	char(4),
codigoBarras			char(100),
numeroComprobante		char(25),
fechaRendicion			char(10),
fechaPagoRecaudador		char(10),
horaPagoRecaudador		char(10),
sesionBanco				char(25),
codigoMedioPago			char(250),
infoMedioPago1			char(250),
infoMedioPago2			char(250),
infoMedioPago3			char(250),
infoMedioPago4			char(250),
infoMedioPago5			char(250)
)

RETURNING char(3) as codigo_retorno, 
	char(50) as descripcion_retorno, 
	char(20) as transaccion_pago_enel,
	char(10) as fecha_pago_aplicado,
	char(10) as hora_pago_aplicado;

DEFINE len_barra			int;
DEFINE nro_cliente_barra	char(8);
DEFINE iNroCliente			int;
DEFINE nrows				int;
DEFINE dFechaRendicion		DATE;
DEFINE dFechaPagoReca		DATE;

-- Valores a devolver
DEFINE ret_transaccion 	char(20);
DEFINE ret_fecha_pago	char(10);
DEFINE ret_hora_pago	char(10);

    SET ISOLATION TO DIRTY READ;
    
    IF codigo_empresa != 4 THEN
        RETURN '013', 'EMPRESA INVALIDA','', '', '';
    END IF;
    
	-- validar la barra
	LET len_barra= LENGTH(codigoBarras);
	IF (len_barra != 46) THEN
		RETURN '105', 'LONGITUD DE BARRA INCORRECTO', '', '', '';
	END IF;
		
	LET nro_cliente_barra=codigoBarras[8,15];
	LET iNroCliente=to_number(nro_cliente_barra);
	LET dFechaRendicion=TO_DATE(fechaRendicion, '%d/%m/%Y');
	LET dFechaPagoReca=TO_DATE(fechaPagoRecaudador, '%d/%m/%Y');
	LET nrows=0;
	
	SELECT count(*) INTO nrows FROM rdd_notificaciones
	WHERE nro_comprobante_reca = trim(numeroComprobante)
	AND sesion_banco = trim(sesionBanco);
	
	IF nrows > 0 THEN
		RETURN '007', 'PAGO YA IMPUTADO','', '', '';
	END IF;
	
	--begin work;
    
    -- Insertar
	INSERT INTO rdd_notificaciones(
		numero_cliente,
		cod_recaudador,
		cod_oficina_recaudador,
		cod_caja_recaudador,
		cod_barra,
		nro_comprobante_reca,
		fecha_rendicion,
		fecha_pago_reca,
		hora_pago_reca,
		sesion_banco,
		cod_medio_pago,
		info_medio_pago1,
		info_medio_pago2,
		info_medio_pago3,
		info_medio_pago4,
		info_medio_pago5,
		fecha_pago_enel,
		hora_pago_enel
	)VALUES(
		iNroCliente,
		trim(codigoRecaudador),
		trim(codigoOficinaRecaudador),
		trim(codigoCajaRecaudador),
		trim(codigoBarras),
		trim(numeroComprobante),
		dFechaRendicion,
		dFechaPagoReca,
		trim(horaPagoRecaudador),
		trim(sesionBanco),
		trim(codigoMedioPago),
		trim(infoMedioPago1),
		trim(infoMedioPago2),
		trim(infoMedioPago3),
		trim(infoMedioPago4),
		trim(infoMedioPago5),
		TODAY,
		current);
		
    -- Recuperar Data
    SELECT 
		CASE
			WHEN length(to_char(id_movimiento)) < 6 THEN
				'M' || trim(cod_recaudador) || to_char(fecha_pago_enel, '%Y%m%d') || lpad(id_movimiento, 6, '0')
			ELSE
				'M' || trim(cod_recaudador) || to_char(fecha_pago_enel, '%Y%m%d') || lpad(substr(to_char(id_movimiento), -6), 6, '0')
		END,    
		TO_CHAR(fecha_pago_enel, '%d/%m/%Y'), TO_CHAR(hora_pago_enel, '%H:%M:%S')
    INTO ret_transaccion, ret_fecha_pago, ret_hora_pago
    FROM rdd_notificaciones
    WHERE nro_comprobante_reca = trim(numeroComprobante)
    AND sesion_banco = trim(sesionBanco);
    
    -- Updatear
    UPDATE rdd_notificaciones SET
		cod_trans_enel= ret_transaccion
    WHERE nro_comprobante_reca = trim(numeroComprobante)
    AND sesion_banco = trim(sesionBanco);		
		
    --commit work;
    
	RETURN '0', 'OK', ret_transaccion, ret_fecha_pago, ret_hora_pago;

END PROCEDURE;

GRANT EXECUTE ON rdd_notificacion_pago TO
superpjp, supersre, supersbl, supersc, corbacho,
guardt1, fuse,
ctousu, batchsyn, procbatc, "UCENTRO", "OVIRTUAL",
pjp, sreyes, sbl, ssalve, gtricoci,
pablop, aarrien, vdiaz, ldvalle, vaz;

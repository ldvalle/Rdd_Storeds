drop procedure rdd_reversa_pago;

CREATE PROCEDURE rdd_reversa_pago(
codigo_empresa      	integer,
codigoRecaudador		char(20),
codigoBarras			char(100),
montoPago				decimal(14,6),
trxPago					char(20)
)
RETURNING char(3) as codigo_retorno, 
	char(50) as descripcion_retorno;

DEFINE barraPago			char(100);
DEFINE len_barra			int;
DEFINE nro_cliente_barra	char(8);
DEFINE iNroCliente			int;
DEFINE nMontoImputado		decimal(14,6);
DEFINE nrows				int;


    SET ISOLATION TO DIRTY READ;
    
    -- validar empresa
    IF codigo_empresa != 4 THEN
        RETURN '013', 'EMPRESA INVALIDA';
    END IF;
    
    -- validar recaudador
    LET nrows=0;
    SELECT count(*) INTO nrows FROM rdd_recaudadores
    WHERE cod_recaudador = codigoRecaudador
    AND tarifa = 'T1'
    AND fecha_activacion <= TODAY
    AND (fecha_desactivac IS NULL OR fecha_desactivac > TODAY);

	IF nrows = 0 THEN
		RETURN '010', 'RECAUDADOR INVALIDO.';
	END IF;
    
	-- validar la barra
	LET len_barra= LENGTH(codigoBarras);
	IF (len_barra != 46) THEN
		RETURN '105', 'Longitud de barra incorrecto';
	END IF;
		
	LET nro_cliente_barra=codigoBarras[8,15];
	LET iNroCliente=to_number(nro_cliente_barra);
	
	
	-- Valido que el pago haya ingresado
	LET nrows=0;
	
	SELECT to_number(info_medio_pago1), cod_barra INTO nMontoImputado, barraPago FROM rdd_notificaciones
	WHERE cod_trans_enel = trim(trxPago);
	
	LET nrows = DBINFO('sqlca.sqlerrd2');
	
	IF nrows = 0 THEN
		RETURN 'XXX', 'PAGO NO INGRESADO';
	END IF;
	
	-- Valido el monto
	IF nMontoImputado != montoPago THEN
		RETURN 'XXX', 'MONTO REVERSION NO COINCIDE CON MONTO DEL PAGO';
	END IF;
	
	-- valido las codigoBarras
	IF trim(codigoBarras) != trim(barraPago) THEN
		RETURN 'XXX', 'LAS BARRAS DE PAGO Y REVERSION NO COINCIDEN';
	END IF;
		
	-- Valido Reversion preexistente
	LET nrows=0;
	
	SELECT COUNT(*) INTO nrows FROM rdd_reversiones
	WHERE cod_trans_enel = trim(trxPago);
	
	IF nrows > 0 THEN
		RETURN 'XXX', 'REVERSION INGRESADA ANTERIORMENTE';
	END IF;
	
	--begin work;
    
    -- Insertar
    INSERT INTO rdd_reversiones(
		cod_trans_enel,
		numero_cliente,
		cod_recaudador,
		cod_barra,
		monto_deuda,
		fecha_acuse
    )VALUES(
		trim(trxPago),
		iNroCliente,
		codigoRecaudador,
		codigoBarras,
		montoPago,
		CURRENT);
		
    --commit work;
    
	RETURN '000', 'OK';

END PROCEDURE;

GRANT EXECUTE ON rdd_reversa_pago TO
superpjp, supersre, supersbl, supersc, corbacho,
guardt1, fuse,
ctousu, batchsyn, procbatc, "UCENTRO", "OVIRTUAL",
pjp, sreyes, sbl, ssalve, gtricoci,
pablop, aarrien, vdiaz, ldvalle, vaz;

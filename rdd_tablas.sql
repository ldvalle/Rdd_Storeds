CREATE TABLE rdd_recaudadores(
cod_recaudador          char(20),
descripcion             char(50),
tarifa                  char(2),
tipo_documento          char(2),
monto_tope              decimal(12,2),
fecha_activacion        date,
fecha_desactivac        date);

create index inx01rdd_recauda on rdd_recaudadores(cod_recaudador);
    
GRANT select ON rdd_recaudadores  TO
supercal, superfat, supersre, superpjp, supersbl,
supercri, "UCENTRO", batchsyn,pjp, ftejera, sbl,
gtricoci, sreyes, ssalve, pablop, aarrien, vdiaz,
ldvalle, vaz, corbacho, pmf, ctousu, fuse;

GRANT insert ON rdd_recaudadores  TO
supercal, superfat, supersre, superpjp, supersbl,
supercri, "UCENTRO", batchsyn,pjp, ftejera, sbl,
gtricoci, sreyes, ssalve, pablop, aarrien, vdiaz,
ldvalle, vaz, corbacho, pmf, ctousu, fuse;

GRANT delete ON rdd_recaudadores  TO
supercal, superfat, supersre, superpjp, supersbl,
supercri, "UCENTRO", batchsyn,pjp, ftejera, sbl,
gtricoci, sreyes, ssalve, pablop, aarrien, vdiaz,
ldvalle, vaz, corbacho, pmf, ctousu, fuse;

GRANT update ON rdd_recaudadores  TO
supercal, superfat, supersre, superpjp, supersbl,
supercri, "UCENTRO", batchsyn,pjp, ftejera, sbl,
gtricoci, sreyes, ssalve, pablop, aarrien, vdiaz,
ldvalle, vaz, corbacho, pmf, ctousu, fuse;


CREATE TABLE rdd_notificaciones(
id_movimiento	SERIAL not null,
numero_cliente	int,
cod_recaudador	char(20),
cod_oficina_recaudador	char(4),
cod_caja_recaudador		char(4),
cod_barra				char(100),
nro_comprobante_reca	char(25),
fecha_rendicion			date,
fecha_pago_reca			date,
hora_pago_reca			datetime hour to second,
sesion_banco			char(25),
cod_medio_pago			char(250),
info_medio_pago1		char(250),
info_medio_pago2		char(250),
info_medio_pago3		char(250),
info_medio_pago4		char(250),
info_medio_pago5		char(250),
cod_trans_enel			char(20),
fecha_pago_enel			date,
hora_pago_enel			datetime hour to second,
fecha_procesado_mac		datetime hour to second,
estado                  char(1) default 'N'
);

create unique index inx01rdd_notifica on rdd_notificaciones(id_movimiento);
create index inx02rdd_notifica on rdd_notificaciones(nro_comprobante_reca, sesion_banco);
create index inx03rdd_notifica on rdd_notificaciones(numero_cliente, fecha_pago_reca);
create index inx04rdd_notifica on rdd_notificaciones(cod_trans_enel);
    
GRANT select ON rdd_notificaciones  TO
supercal, superfat, supersre, superpjp, supersbl,
supercri, "UCENTRO", batchsyn,pjp, ftejera, sbl,
gtricoci, sreyes, ssalve, pablop, aarrien, vdiaz,
ldvalle, vaz, corbacho, pmf, ctousu, fuse;

GRANT insert ON rdd_notificaciones  TO
supercal, superfat, supersre, superpjp, supersbl,
supercri, "UCENTRO", batchsyn,pjp, ftejera, sbl,
gtricoci, sreyes, ssalve, pablop, aarrien, vdiaz,
ldvalle, vaz, corbacho, pmf, ctousu, fuse;

GRANT delete ON rdd_notificaciones  TO
supercal, superfat, supersre, superpjp, supersbl,
supercri, "UCENTRO", batchsyn,pjp, ftejera, sbl,
gtricoci, sreyes, ssalve, pablop, aarrien, vdiaz,
ldvalle, vaz, corbacho, pmf, ctousu, fuse;

GRANT update ON rdd_notificaciones  TO
supercal, superfat, supersre, superpjp, supersbl,
supercri, "UCENTRO", batchsyn,pjp, ftejera, sbl,
gtricoci, sreyes, ssalve, pablop, aarrien, vdiaz,
ldvalle, vaz, corbacho, pmf, ctousu, fuse;

----------------

CREATE TABLE rdd_reversiones(
cod_trans_enel	char(20) not null,
numero_cliente	int,
cod_recaudador	char(20),
cod_barra		char(100),
monto_deuda		decimal(14,6),
fecha_acuse			datetime year to second,
fecha_procesado_mac	datetime year to second
);

GRANT select ON rdd_reversiones  TO
supercal, superfat, supersre, superpjp, supersbl,
supercri, "UCENTRO", batchsyn,pjp, ftejera, sbl,
gtricoci, sreyes, ssalve, pablop, aarrien, vdiaz,
ldvalle, vaz, corbacho, pmf, ctousu, fuse;

GRANT insert ON rdd_reversiones  TO
supercal, superfat, supersre, superpjp, supersbl,
supercri, "UCENTRO", batchsyn,pjp, ftejera, sbl,
gtricoci, sreyes, ssalve, pablop, aarrien, vdiaz,
ldvalle, vaz, corbacho, pmf, ctousu, fuse;

GRANT delete ON rdd_reversiones  TO
supercal, superfat, supersre, superpjp, supersbl,
supercri, "UCENTRO", batchsyn,pjp, ftejera, sbl,
gtricoci, sreyes, ssalve, pablop, aarrien, vdiaz,
ldvalle, vaz, corbacho, pmf, ctousu, fuse;

GRANT update ON rdd_reversiones  TO
supercal, superfat, supersre, superpjp, supersbl,
supercri, "UCENTRO", batchsyn,pjp, ftejera, sbl,
gtricoci, sreyes, ssalve, pablop, aarrien, vdiaz,
ldvalle, vaz, corbacho, pmf, ctousu, fuse;

create index inx01rdd_reversa on rdd_reversiones(cod_trans_enel);
create index inx02rdd_reversa on rdd_reversiones(numero_cliente);

begin work;

INSERT INTO tabla (sucursal, nomtabla, codigo, descripcion, fecha_activacion
)values('0000', 'RDDECO', '3', 'EstCob Judicial', today);
INSERT INTO tabla (sucursal, nomtabla, codigo, descripcion, fecha_activacion
)values('0000', 'RDDECO', '5', 'EstCob Convocatoria', today);
INSERT INTO tabla (sucursal, nomtabla, codigo, descripcion, fecha_activacion
)values('0000', 'RDDECO', 'D', 'EstCob Concurso Preventivo', today);

insert into tabla (sucursal, nomtabla, codigo, descripcion, fecha_activacion)
select s.sucursal, 'MOTREF', '51', 'REVERSA PAGO', today from sucur s;

INSERT INTO tabla (sucursal, nomtabla, codigo, descripcion, valor_alf, fecha_activacion
)values('0000', 'PATH', 'RDDREV', 'Path reversas rdd', '/synergia/mac/arch/prod/RDD/EXT/reversas/',today);

INSERT INTO tabla (sucursal, nomtabla, codigo, descripcion, valor, fecha_activacion
)values('0000', 'RDDIAS', '1', 'Antig.Vencto.1', 90, today);

commit work;

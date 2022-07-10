/*################################################################################*/
/* Creazione Database */

drop database if exists accessi;
create database if not exists accessi;

use accessi;

/*################################################################################*/
/* Creazione Tabelle */

create table if not exists badge(
    codice varchar(16) not null,
    descrizione varchar(64),
    stato enum("valido", "scaduto", "ritirato", "riconsegnato") default "valido",
    ubicazione varchar(16),
    primary key (codice)
) engine = innodb;

create table if not exists persona(
    ndoc varchar(16) not null,
    tdoc enum("carta-identita", "patente", "tessera-studente") not null,
    nome varchar(32),
    cognome varchar(32),
    ditta varchar(64),
    primary key(ndoc, tdoc)
) engine = innodb;

create table if not exists nominativo(
    badge_cod varchar(16) not null,
    ndoc varchar(16) not null,
    tdoc enum("carta-identita", "patente", "tessera-studente") not null,
    primary key(badge_cod),
    foreign key(badge_cod) references badge(codice),
    foreign key(ndoc, tdoc) references persona(ndoc, tdoc)
) engine = innodb;

create table if not exists chiave(
    badge_cod varchar(16) not null,
    indirizzo varchar(64),
    citta varchar(32),
    piano char(3),
    primary key (badge_cod),
    foreign key (badge_cod) references badge(codice)
) engine = innodb;

create table if not exists instrutt_nom(
    id int unsigned auto_increment not null,
    entrata datetime default now() not null,
    badge_doc varchar(16) not null,
    primary key(id),
    foreign key (badge_doc) references nominativo(badge_cod)
) engine = innodb;

create table if not exists archivio_nom(
    id int unsigned auto_increment not null,
    uscita datetime default now() not null,
    primary key(id),
    foreign key (id) references instrutt_nom(id)
) engine = innodb;

create table if not exists instrutt_osp(
    id int unsigned auto_increment not null,
    entrata datetime default now() not null,
    badge_doc varchar(16) not null,
    ndoc varchar(16) not null,
    tdoc enum("carta-identita", "patente", "tessera-studente") not null,
    primary key(id),
    foreign key (badge_doc) references badge(codice),
    foreign key (ndoc, tdoc) references persona(ndoc, tdoc)
) engine = innodb;

create table if not exists archivio_osp(
    id int unsigned auto_increment not null,
    uscita datetime default now() not null,
    primary key(id),
    foreign key (id) references instrutt_osp(id)
) engine = innodb;

create table if not exists instrutt_chiave(
    id int unsigned auto_increment not null,
    prestito datetime default now() not null,
    cod_nom varchar(16) not null,
    primary key(id),
    foreign key (cod_nom) references nominativo(badge_cod)
) engine = innodb;

create table if not exists chiave_in_prestito(
    id_archivio int unsigned auto_increment not null,
    cod_chiave varchar(16) not null,
    primary key(id_archivio, cod_chiave),
    foreign key (id_archivio) references instrutt_chiave(id),
    foreign key (cod_chiave) references chiave(badge_cod)
) engine = innodb;

create table if not exists archivio_chiave(
    id int unsigned auto_increment not null,
    reso datetime default now() not null,
    primary key(id),
    foreign key (id) references instrutt_chiave(id)
) engine = innodb;

/*################################################################################*/
/* Triggers */

/* ubicazione è null se badge è nominativo */
drop trigger if exists set_ubicazione_null_se_nom;
create trigger if not exists set_ubicazione_null_se_nom
before insert on nominativo
for each row
update badge set ubicazione = null where codice = new.badge_cod;


/* entrata badge non valida se dipendente è già in struttura */
drop trigger if exists check_nom_is_instrutt;
delimiter $$ ;

create trigger if not exists check_nom_is_instrutt
before insert on instrutt_nom
for each row
begin
set @check = (select count(*) 
from instrutt_nom as i
left join archivio_nom as a on i.id = a.id
where i.badge_doc = new.badge_doc and a.id is null);

if @check <> 0 then
signal sqlstate '69420'
set message_text = 'dipendente è già in struttura';
end if;
end $$

delimiter ; $$

/* entrata badge non valida se ospite è già in struttura */
drop trigger if exists check_osp_is_instrutt;
delimiter $$ ;

create trigger if not exists check_osp_is_instrutt
before insert on instrutt_osp
for each row
begin
set @check = (select count(*) 
from instrutt_osp as i
left join archivio_osp as a on i.id = a.id
where i.badge_doc = new.badge_doc and a.id is null);

if @check <> 0 then
signal sqlstate '69421'
set message_text = 'ospite è già in struttura';
end if;
end $$

delimiter ; $$

/* impiegato ha già preso in prestito chiavi senza reso */
drop trigger if exists check_non_reso;
delimiter $$ ;

create trigger if not exists check_non_reso
before insert on instrutt_chiave
for each row
begin
set @check = (select count(*) 
from instrutt_chiave as i
left join archivio_chiave as a on i.id = a.id
where i.cod_nom = new.cod_nom and a.id is null);

if @check <> 0 then
signal sqlstate '69422'
set message_text = 'dipendente ha già chiavi in prestito';
end if;
end $$

delimiter ; $$

/* controlla se chiave è già in prestito */
drop trigger if exists check_chiave_in_prestito;
delimiter $$ ;

create trigger if not exists check_chiave_in_prestito
before insert on chiave_in_prestito
for each row
begin
set @check = (select count(*) 
from chiave_in_prestito as c
left join archivio_chiave as a on c.id_archivio = a.id
where c.cod_chiave = new.cod_chiave and a.id is null);

if @check <> 0 then
signal sqlstate '69423'
set message_text = 'chiave è in prestito';
end if;
end $$

delimiter ; $$

/*################################################################################*/
/* Inserimento dati tabelle */

/* inserimento badges da file
SPECIFICARE IL PERCORSO FILE CORRETTO */
load data local infile "/home/owen/db-progetto/badges.txt"
into table badge
fields terminated by '~'
lines terminated by '\n'
ignore 1 rows;

-- insert into badge values
-- ("P-MAR", "collaboratore", "valido", "bad value"),
-- ("C-LUC", "associazione", "valido", null),
-- ("F-ALD", "collaboratore", "valido", null),
-- ("C-GIO", "inserviente", "scaduto", null),
-- ("OO1", "provvisorio", "valido", "cassetto 1"),
-- ("OO2", "provvisorio", "valido", "cassetto 3"),
-- ("OO3", "provvisorio", "valido", "cassetto 2"),
-- ("CHIAVE1", "chiave", "valido", "cassetto 3"),
-- ("CHIAVE2", "chiave", "valido", "cassetto 2"),
-- ("CHIAVE3", "chiave", "valido", "cassetto 2");

/* inserimento persone da file
SPECIFICARE IL PERCORSO FILE CORRETTO */
load data local infile "/home/owen/db-progetto/persone.csv"
into table persona
fields terminated by ',' 
enclosed by '"'
lines terminated by '\n'
ignore 1 rows;

-- insert into persona values
-- ("AUX69420", "carta-identita", "Marco", "Pierattini", "Agliana Electronics - Fortnite & Association"),
-- ("AUX69000", "carta-identita", "Aldo", "Fedonni", null),
-- ("AUX42069", "patente", "Luca", "Cecchi", "PetrolChimica Factorio"),
-- ("AUX69690", "carta-identita", "Paolo", "Giorgio Coda", "MontaleRobotics"),
-- ("0123456", "tessera-studente", null, null, null),
-- ("AUX00069", "patente", null, "Patara", null),
-- ("6543210", "tessera-studente", "Andrea", "Bongianni", null);

insert into nominativo values
("P-MAR", "AUX69420", "carta-identita"),
("C-LUC", "AUX42069", "patente"),
("F-ALD", "AUX69000", "carta-identita"),
("C-GIO", "AUX69690", "carta-identita");

insert into chiave values
("CHIAVE1", "via Calcinaia 420", "Carmignano", "0"),
("CHIAVE2", "viale Montegrappa 69", "Prato", "1B"),
("CHIAVE3", "Groove Street 23", "Grignano", "2");

insert into instrutt_nom values
(1, now(), "P-MAR"),
(2, now(), "C-LUC")/*,
(3, now(), "C-LUC")*/;

insert into archivio_nom values
(1, now()),
(2, now());

insert into instrutt_nom values
(3, now(), "C-LUC");

insert into instrutt_osp values
-- (1001, now(), "OO1", "0123456", "tessera-studente"),
(1002, now(), "OO1", "AUX00069", "patente");

insert into archivio_osp values
(1002, now());

insert into instrutt_osp values
(1001, now(), "OO1", "0123456", "tessera-studente");

insert into instrutt_chiave values
(2001, now(), "P-MAR")/*,
(2002, now(), "P-MAR")*/;

insert into chiave_in_prestito values
(2001, "CHIAVE2"),
(2001, "CHIAVE3")/*,
(2002, "CHIAVE2")*/;

insert into archivio_chiave values
(2001, now());

insert into instrutt_chiave values
(2002, now(), "P-MAR");

insert into chiave_in_prestito values
(2002, "CHIAVE2");

-- insert into archivio_chiave values
-- (2001, now());

/*################################################################################*/
/* Views */

/* tutti i dipendenti in struttura, non ancora usciti */
drop view if exists dipendenti_instrutt;
create view if not exists dipendenti_instrutt as
select i.id as id, i.entrata as entrata, i.badge_doc as badge_doc, p.nome as nome, p.cognome as cognome, n.ndoc as ndoc, n.tdoc as tdoc
from instrutt_nom as i
left join nominativo as n
on i.badge_doc=n.badge_cod
left join persona as p
on p.ndoc=n.ndoc and p.tdoc=n.tdoc
left join archivio_nom as a
on a.id=i.id
where a.id is null;

/* tutti gli ospiti in struttura, non ancora usciti */
drop view if exists ospiti_instrutt;
create view if not exists ospiti_instrutt as
select i.id as id, i.entrata as entrata, i.badge_doc as badge_doc, p.nome as nome, p.cognome as cognome, i.ndoc as ndoc, i.tdoc as tdoc
from instrutt_osp as i
left join persona as p
on p.ndoc=i.ndoc and p.tdoc=i.tdoc
left join archivio_osp as a
on a.id=i.id
where a.id is null;

/* archivio dipendenti (resoconto entrate + uscite) */
drop view if exists resoconto_dipendenti;
create view if not exists resoconto_dipendenti as
select i.id as id, i.entrata as entrata, a.uscita as uscita, i.badge_doc as badge_doc, p.nome as nome, p.cognome as cognome, n.ndoc as ndoc, n.tdoc as tdoc
from instrutt_nom as i
inner join nominativo as n
on i.badge_doc=n.badge_cod
inner join persona as p
on p.ndoc=n.ndoc and p.tdoc=n.tdoc
inner join archivio_nom as a
on a.id=i.id;

/* archivio ospiti (resoconto entrate + uscite) */
drop view if exists resoconto_ospiti;
create view if not exists resoconto_ospiti as
select i.id as id, i.entrata as entrata, a.uscita as uscita, i.badge_doc as badge_doc, p.nome as nome, p.cognome as cognome, i.ndoc as ndoc, i.tdoc as tdoc
from instrutt_osp as i
inner join persona as p
on p.ndoc=i.ndoc and p.tdoc=i.tdoc
inner join archivio_osp as a
on a.id=i.id;

/*################################################################################*/
/* Query interrogazione */

/* tutte le persone in struttura, non ancora usciti */
select * from dipendenti_instrutt
union
select * from ospiti_instrutt;

/* dipendente che ha in prestito una determinata chiave */
select i.id as id, i.cod_nom as cod_nom, i.prestito as prestito, p.nome as nome, p.cognome as cognome, n.ndoc as ndoc, n.tdoc as tdoc
from chiave_in_prestito as c
left join instrutt_chiave as i
on c.id_archivio=i.id
left join nominativo as n
on i.cod_nom=n.badge_cod
left join persona as p
on n.ndoc=p.ndoc and n.tdoc=p.tdoc
left join archivio_chiave as a
on a.id=i.id 
where c.cod_chiave="CHIAVE2" and a.id is null;

/* resoconto archivio in un certo lasso di tempo */
select *
from (
    select * from resoconto_dipendenti
    union
    select * from resoconto_ospiti
) t
where entrata between "2022-07-01" and "2022-08-01";

/* chiavi attualmente in prestito */
select cod_chiave
from chiave_in_prestito
left join archivio_chiave
on id_archivio = id
where id is null;
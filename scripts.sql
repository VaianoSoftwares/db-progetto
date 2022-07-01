/*################################################################################*/
/* Creazione Database */

drop database if exists accessi
create database if not exists accessi

/*################################################################################*/
/* Creazione Tabelle */

create table if not exists badge(
    codice varchar(16) not null,
    descrizione varchar(64),
    stato enum("valido", "scaduto", "ritirato", "riconsegnato") default "valido",
    ubicazione varchar(8),
    primary key (codice)
) engine = innodb;

create table if not exists persona(
    ndoc varchar(16) not null,
    tdoc enum("carta-identita", "patente", "tessera-studente") not null,
    nome varchar(32),
    cognome varchar(32),
    ditta varchar(32),
    primary key(ndoc, tdoc)
) engine = innodb;

create table if not exists nominativo(
    badge_cod varchar(16) not null,
    ndoc varchar(16) not null,
    tdoc varchar(16) not null,
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
    entrata datetime default now(),
    badge_doc varchar(16) not null,
    primary key(id),
    foreign key (badge_doc) references nominativo(badge_doc)
) engine = innodb;

create table if not exists archivio_nom(
    id int unsigned auto_increment not null,
    uscita datetime default now(),
    primary key(id),
    foreign key (id) references instrutt_nom(id)
) engine = innodb;

create table if not exists instrutt_osp(
    id int unsigned auto_increment not null,
    entrata datetime default now(),
    badge_doc varchar(16) not null,
    ndoc varchar(16) not null,
    tdoc enum("id", "patente", "tessera-studente") not null,
    primary key(id),
    foreign key (badge_doc) references badge(codice),
    foreign key (ndoc, tdoc) references persona(ndoc, tdoc)
) engine = innodb;

create table if not exists archivio_osp(
    id int unsigned auto_increment not null,
    uscita datetime default now(),
    primary key(id),
    foreign key (id) references instrutt_osp(id)
) engine = innodb;

create table if not exists instrutt_chiave(
    id int unsigned auto_increment not null,
    prestito datetime default now(),
    cod_nom varchar(16) not null,
    primary key(id),
    foreign key (cod_nom) references nominativo(badge_cod)
) engine = innodb;

create table if not exists chiave_in_prestito(
    id_archivio int unsigned auto_increment not null,
    cod_chiave varchar(16) not null,
    primary key(id_archivio, cod_chiave),
    foreign key (id_archivio) references archivio_chiave(id),
    foreign key (cod_chiave) references chiave(badge_cod)
) engine = innodb;

create table if not exists archivio_chiave(
    id int unsigned auto_increment not null,
    reso datetime default now(),
    primary key(id),
    foreign key (id) references instrutt_chiave(id)
) engine = innodb;

/*################################################################################*/
/* Triggers */

/* ubicazione è null se badge non è ospite */
delimeter $$
create trigger check_ubicazione_null_se_nom
before insert on badge
for each row
begin
    if (new.ubicazione is not null) and (select count(*) from nominativo n where n.codice = new.codice > 0) then 
        set new.ubicazione = null;
end $$
delimeter ;

/*################################################################################*/
/* Inserimento dati tabelle */

insert into badge values
("P-MAR", "collaboratore", "valido", null),
("C-LUC", "associazione", "valido", null),
("F-ALD", "collaboratore", "valido", null),
("C-GIO", "inserviente", "scaduto", null),
("OO1", "provvisorio", "valido", "cassetto 1"),
("OO2", "provvisorio", "valido", "cassetto 3"),
("OO3", "provvisorio", "valido", "cassetto 2"),
("CHIAVE1", "chiave", "valido", "cassetto 3"),
("CHIAVE2", "chiave", "valido", "cassetto 2"),
("CHIAVE3", "chiave", "valido", "cassetto 2");

insert into persona values
("AUX69420", "carta-identita", "Marco", "Pierattini", "Agliana Electronics - Fortnite & Association"),
("AUX69000", "carta-identita", "Aldo", "Fedonni", null),
("AUX42069", "patente", "Luca", "Cecchi", "PetrolChimica Factorio"),
("AUX69690", "carta-identita", "Paolo", "Giorgio Coda", "VaianoSoftwares"),
("0123456", "tessera-studente", null, null, null),
("AUX00069", "patente", null, "Patara", null),
("6543210", "tessera-studente", "Andrea", "Bongianni", null);

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
(1, null, "P-MAR"),
(2, null, "C-LUC"),
(3, null, "C-LUC");

insert into archivio_nom values
(1, null),
(2, null);

insert into instrutt_osp values
(1001, null, "OO1", "0123456", "tessera-studente"),
(1002, null, "OO1", "AUX00069", "carta-identita");

insert into archivio_osp values
(1002, null);

insert into instrutt_chiave values
(2001, null, "P-MAR"),
(2002, null, "P-MAR");

insert into chiave_in_prestito values
(2001, "CHIAVE2"),
(2001, "CHIAVE3"),
(2002, "CHIAVE2");

insert into archivio_chiave values
(2001, null);
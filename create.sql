create table CAT -- OK
(
	idcat NUMBER(6) PRIMARY KEY,
	catname VARCHAR(15) NOT NULL
);

create table EMISSION -- OK
(
	idemission NUMBER(6) PRIMARY KEY,
	nameemission VARCHAR(255) NOT NULL,
	episodenb NUMBER(3) NOT NULL,
	idcat NUMBER(6) NOT NULL,
	FOREIGN KEY (idcat) REFERENCES CAT
);

-- TODO : penser à mettre une remarque sur le sysdate, la raison pour laquelle certaines dates sont à 2021
-- TODO mettre date plus précise dans l'historique, permettant de savoir si l'user a lancé
-- plus que 3 vidéos/minute

create table VIDEO -- OK
(
    idvideo NUMBER(6) PRIMARY KEY,
    idemission NUMBER(6) NOT NULL,
    link VARCHAR(2083) NOT NULL,
    ordernb NUMBER(6) NOT NULL,
    namevideo VARCHAR(255) NOT NULL,
    descr VARCHAR(1024) NOT NULL,
    length NUMBER(3) NOT NULL,
    firstbcastyear NUMBER(4) NOT NULL,
    country VARCHAR(4) NOT NULL, -- TODO : table à part
    multilang NUMBER(1) NOT NULL, -- TODO table à part avec toutes les langues
    ext VARCHAR(10) NOT NULL, -- extension
    bcastnb NUMBER(4) NOT NULL,
    FOREIGN KEY (idemission) REFERENCES EMISSION
);

create table DIFFUSION -- OK
(
	idvideo NUMBER(6) NOT NULL,
	date_diffusion DATE NOT NULL,
	date_findiffusion DATE NOT NULL,
    FOREIGN KEY (idvideo) REFERENCES VIDEO
);

create table VIEWS_ONDATE -- OK
(
	idvideo NUMBER(6) NOT NULL,
	dateviews DATE NOT NULL,
	viewsnb NUMBER(9) NOT NULL,
    FOREIGN KEY (idvideo) REFERENCES VIDEO
);

create table REGUSER -- OK
(
	iduser NUMBER(9) PRIMARY KEY,
	nationality VARCHAR(6) NOT NULL,
	login VARCHAR(24) NOT NULL,
	psswdhash VARCHAR(40) NOT NULL,
	firstname VARCHAR(25) NOT NULL,
	lastname VARCHAR(25) NOT NULL,
	DOB DATE NOT NULL,
	mailusr varchar(320) NOT NULL
);

create table FAV
(
	iduser NUMBER(6) NOT NULL,
	idvideo NUMBER(6) NOT NULL,
	FOREIGN KEY (iduser) REFERENCES REGUSER,
	FOREIGN KEY (idvideo) REFERENCES VIDEO
);

create table USERHISTORY -- OK
(
	iduser NUMBER(6) NOT NULL,
	idvideo NUMBER(6) NOT NULL,
	dateofview DATE NOT NULL,
	FOREIGN KEY (iduser) REFERENCES REGUSER,
	FOREIGN KEY (idvideo) REFERENCES VIDEO
);

create table NEWSLETTER -- OK
(
	iduser NUMBER(6) NOT NULL,
	FOREIGN KEY (iduser) REFERENCES REGUSER
);

create table INTEREST -- OK
(
	iduser NUMBER(9) NOT NULL,
	idcat NUMBER(6) NOT NULL,
	FOREIGN KEY (iduser) REFERENCES REGUSER,
	FOREIGN KEY (idcat) REFERENCES CAT
);

create table SUB  -- OK
(
	iduser NUMBER(6) NOT NULL,
	idemission NUMBER(6) NOT NULL,
	FOREIGN KEY (iduser) REFERENCES REGUSER,
    FOREIGN KEY (idemission) REFERENCES EMISSION
);

create or replace view SUGGESTION_SUB as
SELECT reguser.iduser, video.idvideo
FROM reguser, sub, emission, video, diffusion
WHERE reguser.iduser = sub.iduser
AND sub.idemission = emission.idemission
AND emission.idemission = video.idemission
AND video.idvideo = diffusion.idvideo
AND sysdate-diffusion.date_diffusion < 7;


create or replace view SUGGESTION_DEMISE as
SELECT idvideo FROM diffusion WHERE sysdate - date_findiffusion < 7;

create or replace view SUGGESTION_FAV as 
SELECT * from fav; --pas forcément utile, mais colle au sujet

create or replace view SUGGESTION_POPU as
SELECT cat.idcat, video.idvideo, sum(viewsnb) views 
FROM views_ondate, video, cat, emission
WHERE views_ondate.idvideo = video.idvideo
AND video.idemission = emission.idemission
AND emission.idcat = cat.idcat
AND sysdate-dateviews < 14
GROUP BY video.idvideo, cat.idcat
ORDER BY cat.idcat asc, views desc;

create table EMISSION_ARCHIVED -- émission archivée si toutes ses vidéos sont archivées
(
	idemission NUMBER(6) PRIMARY KEY,
	nameemission VARCHAR(255) NOT NULL,
	episodenb NUMBER(3) NOT NULL,
	idcat NUMBER(6) NOT NULL,
	FOREIGN KEY (idcat) REFERENCES CAT
);

create table VIDEO_ARCHIVED -- OK
(
    idvideo NUMBER(6) PRIMARY KEY,
    idemission NUMBER(6) NOT NULL,
    link VARCHAR(2083) NOT NULL,
    ordernb NUMBER(6) NOT NULL,
    namevideo VARCHAR(255) NOT NULL,
    descr VARCHAR(1024) NOT NULL,
    length NUMBER(3) NOT NULL,
    firstbcastyear NUMBER(4) NOT NULL,
    country VARCHAR(4) NOT NULL,
    multilang NUMBER(1) NOT NULL,
    ext VARCHAR(10) NOT NULL, -- extension
    bcastnb NUMBER(4) NOT NULL,
    FOREIGN KEY (idemission) REFERENCES EMISSION_ARCHIVED
);

create table DIFFUSION_ARCHIVED
(
	idvideo NUMBER(6) NOT NULL,
	date_diffusion DATE NOT NULL,
	date_findiffusion DATE NOT NULL,
    FOREIGN KEY (idvideo) REFERENCES VIDEO_ARCHIVED
);

create table VIEWS_ONDATE_ARCHIVED
(
	idvideo NUMBER(6) NOT NULL,
	dateviews DATE NOT NULL,
	viewsnb NUMBER(9) NOT NULL,
    FOREIGN KEY (idvideo) REFERENCES VIDEO_ARCHIVED
);

create sequence idvideo_seq;
create sequence idcat_seq;
create sequence idemission_seq;

CREATE OR REPLACE TRIGGER AI_VIDEO 
BEFORE INSERT ON VIDEO
FOR EACH ROW
BEGIN
    SELECT idvideo_seq.nextval - 1
    INTO :new.idvideo
    FROM dual;
END;
/
show err

create or replace TRIGGER AI_CAT 
BEFORE INSERT ON CAT
FOR EACH ROW
BEGIN
    SELECT idcat_seq.nextval - 1
    INTO :new.idcat
    FROM dual;
END;
/
show errors

create or replace TRIGGER AI_EMISSION
BEFORE INSERT ON EMISSION
FOR EACH ROW
BEGIN
    SELECT idemission_seq.nextval - 1
    INTO :new.idemission
    FROM dual;
END;
/
show errors

select * from video;

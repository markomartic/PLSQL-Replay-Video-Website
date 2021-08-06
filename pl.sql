-- Q1
-- select vitojson(15) from dual;
CREATE OR REPLACE FUNCTION vitojson (idvid IN number) RETURN VARCHAR2
IS
  ret VARCHAR2(8196); --str de retour
  CURSOR cur_vid IS --récup 
    SELECT * FROM VIDEO WHERE VIDEO.idvideo = idvid;
  res cur_vid%ROWTYPE;
BEGIN
  OPEN cur_vid;
  FETCH cur_vid INTO res;
  
  ret := '{' || chr(10) ||
          '"idvideo": "' || res.idvideo || '",' || chr(10) ||
          '"idemission": "' || res.idemission || '",' || chr(10) ||
          '"link": "' || res.link || '",' || chr(10) ||
          '"ordernb": "' || res.ordernb || '",' || chr(10) ||
          '"namevideo": "' || res.namevideo || '",' || chr(10) ||
          '"descr": "' || res.descr || '",' || chr(10) ||
          '"length": "' || res.length || '",' || chr(10) ||
          '"firstbcastyear": "' || res.firstbcastyear || '",' || chr(10) ||
          '"country": "' || res.country || '",' || chr(10) ||
          '"multilang": "' || res.multilang || '",' || chr(10) ||
          '"ext": "' || res.ext || '",' || chr(10) ||
          '"bcastnb": "' || res.bcastnb|| '"' || chr(10) ||
          '}';
          
 close cur_vid;
return ret;
END vitojson;
/
SHOW ERRORS

-- Q2
SET SERVEROUTPUT ON;
--EXECUTE create_newsletter
CREATE OR REPLACE PROCEDURE create_newsletter IS
  ret VARCHAR2(8196);
  tmp VARCHAR2(2048);
  CURSOR cur_vids IS
    SELECT * FROM DIFFUSION WHERE sysdate - DIFFUSION.date_diffusion < 7;
BEGIN
    ret := 'Les sorties de cette semaine sont : ' || chr(10);
    
    FOR cur_row IN cur_vids
    LOOP
      SELECT video.namevideo INTO tmp FROM video WHERE video.idvideo = cur_row.idvideo;
      ret := ret || tmp || chr(10);
    END LOOP;
    dbms_output.put_line(ret);
END;
/
SHOW ERRORS

-- Q3
-- Génération de la liste des vidéos populaires pour un user, en fct des
-- catégories qu'il suit
SET SERVEROUTPUT ON;
CREATE OR REPLACE PROCEDURE create_interest_vidlistz (iduserr IN number)
IS
  ret VARCHAR2(8196); -- str de retour
  tmps VARCHAR2(6);
  tmp NUMBER;
  CURSOR cur_cat IS -- récup
    SELECT video.idvideo idvideo, nvl(sum(views_ondate.viewsnb),0) nb_vues, video.idemission idemission
    FROM video
    LEFT JOIN views_ondate ON video.idvideo = views_ondate.idvideo
    GROUP BY video.idvideo, video.idemission
    ORDER BY nb_vues DESC;

  res_cat cur_cat%ROWTYPE;
BEGIN
  ret := '';
  FOR res_cat IN cur_cat
  LOOP 
    BEGIN
      SELECT res_cat.idvideo INTO tmps FROM INTEREST 
      LEFT JOIN EMISSION ON EMISSION.idcat = INTEREST.idcat
      WHERE INTEREST.iduser = iduserr
      AND EMISSION.idemission = res_cat.idemission;
      EXCEPTION when NO_DATA_FOUND then
      continue;
      ret := ret || res_cat.idvideo || chr(10);
    END;
    --ret := ret || res_cat.idvideo || chr(10);
  END LOOP;
  dbms_output.put_line(ret);
END create_interest_vidlistz;
/
SHOW ERRORS


-- Contraintes
-- Q1 : Un utilisateur aura un maximum de 300 vidéos en favoris
CREATE OR REPLACE TRIGGER USER_MAX
BEFORE INSERT OR UPDATE 
ON fav
FOR EACH ROW 
DECLARE
    nb_de_fav INTEGER;
BEGIN
    SELECT count(*) INTO nb_de_fav
    FROM fav
    WHERE fav.iduser = :new.iduser;

    IF nb_de_fav >= 300
        THEN RAISE_APPLICATION_ERROR(-20110,'Nombre max de favoris atteint');
    END IF ;
END ;
/
SHOW ERRORS trigger USER_MAX;


-- Q2 : INSERT TRIGGER
CREATE OR REPLACE TRIGGER MISE_DIFF_IN
BEFORE INSERT
ON diffusion
FOR EACH ROW
DECLARE 
    nouv_date diffusion.date_findiffusion%type;
BEGIN 
    SELECT date_findiffusion
      INTO nouv_date
      FROM diffusion
     WHERE idvideo = :new.idvideo and ROWNUM <=1;
     
    IF nouv_date != NULL
        THEN 
        --nouv_date := :new.date_diffusion + 14;
        :new.date_findiffusion := :new.date_diffusion + 14;
        
    ELSE 
        :new.date_findiffusion := :new.date_diffusion + 14;
    END IF;
END;
/
SHOW ERROR trigger MISE_DIFF_IN;

-- Q2 : UPDATE TRIGGER
CREATE OR REPLACE TRIGGER MISE_DIFF_UP
AFTER UPDATE
ON diffusion
FOR EACH ROW
DECLARE 
    nouv_date diffusion.date_findiffusion%type;
    video diffusion.idvideo%type;
BEGIN 
    delete from diffusion where idvideo= :new.idvideo;
    insert into diffusion values (:new.idvideo,:new.date_diffusion,to_date('0000/00/00', 'yyyy/mm/dd'));
    
END;
/
SHOW ERROR trigger MISE_DIFF_UP;

-- Q3 : suppression d'une vidéo donne lieu à un archivage de celle-ci
create or replace TRIGGER ARCHIVAGE
BEFORE DELETE ON video 
FOR EACH ROW
DECLARE
    nbvid integer;
    emm integer;
    rowem emission%ROWTYPE;
BEGIN
    SELECT count(*) INTO emm from emission_archived where idemission = :old.idemission; 
    IF emm = 0 THEN
        SELECT * INTO rowem FROM emission WHERE idemission= :old.idemission;
        INSERT INTO emission_archived VALUES (rowem.idemission,rowem.nameemission,rowem.episodenb,rowem.idcat);
    END IF;
    
    INSERT INTO video_archived VALUES (:old.idvideo,:old.idemission,:old.link,
            :old.ordernb,:old.namevideo,:old.descr,:old.length,:old.firstbcastyear,
            :old.country,:old.multilang,:old.ext,:old.bcastnb);
    
    SELECT count(*) INTO nbvid FROM video
        WHERE idemission = :old.idemission;

    IF nbvid = 0 THEN   
        DELETE FROM emission WHERE idemission= :old.idemission;
        
    END IF;    
END;
/
show errors trigger archivage;

-- Q4 : limiter le nombre de vidéos lancées par utilisateur à 3
CREATE OR REPLACE TRIGGER LIMIT_SPAM
BEFORE INSERT ON USERHISTORY
FOR EACH ROW
DECLARE
    nb_vu_der_min INTEGER;
BEGIN
    SELECT count(*) INTO nb_vu_der_min FROM userhistory  WHERE iduser = :new.iduser and sysdate-dateofview < 1/(24*60);
    IF nb_vu_der_min >= 3 THEN 
         RAISE_APPLICATION_ERROR(-20111,'Nombre de visionnage a la minute atteind');
    END IF;
END;

/
SHOW ERRORS TRIGGER LIMIT_SPAM;
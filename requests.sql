-- question 1
-- nb de visionnages de vidéos par cat de vidéos, pour les visio de moins de 2 semaines
SELECT cat.idcat, cat.catname, sum(views_ondate.viewsnb) all_recent_views
FROM views_ondate 
LEFT JOIN video ON views_ondate.idvideo = video.idvideo
LEFT JOIN emission ON video.idemission = emission.idemission
LEFT JOIN cat ON emission.idcat = cat.idcat
WHERE sysdate - views_ondate.dateviews < 14
GROUP BY cat.idcat, cat.catname
ORDER BY cat.idcat;

-- question 2
-- par utilisateur, le nb d'abonnements, de favoris et de vidéos visionnées
SELECT reguser.iduser, count(fav.idvideo) favoris, count(userhistory.idvideo) nb_vid_history, count(sub.idemission) nb_subs
FROM reguser
LEFT JOIN fav ON fav.iduser = reguser.iduser
LEFT JOIN sub ON sub.iduser = reguser.iduser
LEFT JOIN userhistory ON userhistory.iduser = reguser.iduser
GROUP BY reguser.iduser
ORDER BY reguser.iduser;

-- question 3
-- pour chaque vidéo, le nb de visio par les user fr, deutsche et la différence entre les deux
WITH 
nb_fr AS
(
SELECT userhistory.idvideo as idvideo, count(userhistory.iduser) as nb
FROM userhistory 
LEFT JOIN reguser ON userhistory.iduser = reguser.iduser
WHERE reguser.nationality LIKE 'fr'
GROUP BY userhistory.idvideo
),
nb_de AS
(
SELECT userhistory.idvideo as idvideo, count(userhistory.iduser) as nb
FROM userhistory 
LEFT JOIN reguser ON userhistory.iduser = reguser.iduser
WHERE reguser.nationality LIKE 'de'
GROUP BY userhistory.idvideo
)
select video.idvideo, nvl(nb_fr.nb,0) AS fr, nvl(nb_de.nb, 0) AS de, abs(nvl(nb_fr.nb,0)-nvl(nb_de.nb, 0)) AS diff
FROM video
LEFT JOIN nb_fr ON video.idvideo = nb_fr.idvideo
LEFT JOIN nb_de ON video.idvideo = nb_de.idvideo
order by diff asc;

-- question 4
-- les vidéos d'émissions qui ont au moins deux fois plus de visio que la 
-- moyenne des visio des autres épisodes de l'émission
WITH -- moyenne de vues d'une émission
vues_video AS -- vues d'une vidéo
(
SELECT video.idvideo idvideo, nvl(sum(views_ondate.viewsnb),0) nb_vues, video.idemission idemission
FROM video
LEFT JOIN views_ondate ON video.idvideo = views_ondate.idvideo
GROUP BY video.idvideo, video.idemission
),
moy_emission AS
(
SELECT emission.idemission idemission, avg(vues_video.nb_vues) moyenne, count(vues_video.idvideo) nb_videos
FROM emission
LEFT JOIN vues_video ON emission.idemission = vues_video.idemission
GROUP BY emission.idemission
ORDER BY emission.idemission
)
SELECT vues_video.idvideo
FROM vues_video
LEFT JOIN moy_emission ON vues_video.idemission = moy_emission.idemission
WHERE vues_video.nb_vues >= ((moy_emission.moyenne*moy_emission.nb_videos)-moy_emission.nb_videos)/nvl(nullif(moy_emission.nb_videos-1, 0), 1);


create table userhistory
(
iduser number,
idvideo number
);

-- question 5
-- les 10 couples de vidéos apparaissant le plus souvent simultanément dans un historique
-- de visionnage utilisateur
WITH couples AS
(
SELECT a.idvideo c1, b.idvideo c2
FROM userhistory a
CROSS JOIN userhistory b
WHERE a.iduser = b.iduser
AND a.idvideo != b.idvideo
AND a.idvideo < b.idvideo
GROUP BY a.idvideo, b.idvideo, a.iduser
), no_limit AS
(
SELECT couples.c1, couples.c2, count(*) nb_apparitions
FROM couples
GROUP BY c1, c2
ORDER BY nb_apparitions desc
)
SELECT * from no_limit
WHERE ROWNUM<=10;
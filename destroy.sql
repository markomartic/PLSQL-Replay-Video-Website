-- auto-increment trigger
drop trigger ai_cat;
drop trigger ai_video;
drop trigger ai_emission;

-- séq pour l'auto-trigger
drop sequence idcat_seq;
drop sequence idvideo_seq;
drop sequence idemission_seq;

drop view suggestion_demise;
drop view suggestion_popu;
drop view suggestion_sub;
drop view suggestion_fav;
drop table userhistory;
drop table diffusion_archived;
drop table diffusion;
drop table fav;
drop table sub;
drop table newsletter;
drop table interest;
drop table reguser;
drop table views_ondate;
drop table views_ondate_archived;
drop table video;
drop table video_archived;
drop table emission;
drop table emission_archived;
drop table cat;
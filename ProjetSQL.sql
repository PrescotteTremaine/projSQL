----------------------------------
----------Table creation----------
----------------------------------

--------------------------
----------CLIENT----------
--------------------------


--drop table IF EXISTS client;
create table client 
(
	IDCLIENT_BRUT real primary key, 
	CIVILITE varchar(10),
	DATENAISSANCE timestamp,
	MAGASIN varchar(15),
	DATEDEBUTADHESION timestamp,
	DATEREADHESION timestamp,
	DATEFINADHESION timestamp,
	VIP integer,
	CODEINSEE varchar(10),
	PAYS varchar(10)
);

COPY client FROM 'F:\Data\doc\DATA_Projet_R\CLIENT.CSV' CSV HEADER delimiter '|' null '';

---TRANSFORMATION IDCLIENT_BRUT
ALTER TABLE client ADD IDCLIENT bigint;
UPDATE client SET IDCLIENT =  CAST(IDCLIENT_BRUT AS bigint);
ALTER TABLE client DROP IDCLIENT_BRUT;
ALTER TABLE client ADD PRIMARY KEY (IDCLIENT);

SELECT * FROM client limit 10;

--------------------------
------ENTETE_TICKET-------
--------------------------

--drop table IF EXISTS entete_ticket;
create table entete_ticket 
(
	IDTICKET bigint primary key,
	TIC_DATE timestamp,
	MAG_CODE varchar(15),
	IDCLIENT_BRUT real,
	TIC_TOTALTTC_BRUT varchar(10) --money
	
);

COPY entete_ticket FROM 'F:\Data\doc\DATA_Projet_R\ENTETES_TICKET_V4.CSV' CSV HEADER delimiter '|' null '';

---TRANSFORMATION TIC_TOTALTTC_BRUT
ALTER TABLE entete_ticket ADD TIC_TOTALTTC float;
UPDATE entete_ticket SET TIC_TOTALTTC =  CAST(REPLACE(TIC_TOTALTTC_BRUT , ',', '.') AS float);
ALTER TABLE entete_ticket DROP TIC_TOTALTTC_BRUT;

---TRANSFORMATION IDCLIENT_BRUT
ALTER TABLE entete_ticket ADD IDCLIENT bigint;
UPDATE entete_ticket SET IDCLIENT =  CAST(IDCLIENT_BRUT AS bigint);
ALTER TABLE entete_ticket DROP IDCLIENT_BRUT;

SELECT * from entete_ticket limit 10;

-------------------
---LIGNE_TICKET----
-------------------

--drop table IF EXISTS lignes_ticket;
create table lignes_ticket 
(
	IDTICKET bigint,
	NUMLIGNETICKET integer,
	IDARTICLE varchar(15), --ligne avec 'COUPON'
	QUANTITE_BRUT varchar(15),
	MONTANTREMISE_BRUT varchar(15),
	TOTAL_BRUT varchar(15),
	MARGESORTIE_BRUT varchar(15)
);


COPY lignes_ticket FROM 'F:\Data\doc\DATA_Projet_R\LIGNES_TICKET_V4.CSV' CSV HEADER delimiter '|' null '';

---TRANSFORMATION QUANTITE_BRUT
ALTER TABLE lignes_ticket ADD QUANTITE float;
UPDATE lignes_ticket SET QUANTITE =  CAST(REPLACE(QUANTITE_BRUT , ',', '.') AS float);
ALTER TABLE lignes_ticket DROP QUANTITE_BRUT;

---TRANSFORMATION MONTANTREMISE_BRUT
ALTER TABLE lignes_ticket ADD MONTANTREMISE float;
UPDATE lignes_ticket SET MONTANTREMISE =  CAST(REPLACE(MONTANTREMISE_BRUT , ',', '.') AS float);
ALTER TABLE lignes_ticket DROP MONTANTREMISE_BRUT;

---TRANSFORMATION TOTAL_BRUT
ALTER TABLE lignes_ticket ADD TOTAL float;
UPDATE lignes_ticket SET TOTAL =  CAST(REPLACE(TOTAL_BRUT , ',', '.') AS float);
ALTER TABLE lignes_ticket DROP TOTAL_BRUT;

---TRANSFORMATION MARGESORTIE_BRUT
ALTER TABLE lignes_ticket ADD MARGESORTIE float;
UPDATE lignes_ticket SET MARGESORTIE =  CAST(REPLACE(MARGESORTIE_BRUT , ',', '.') AS float);
ALTER TABLE lignes_ticket DROP MARGESORTIE_BRUT;

select * from lignes_ticket order by idticket limit 10;

-------------------
---REF_MAGASIN-----
-------------------

--drop table IF EXISTS ref_magasin;
create table ref_magasin 
(
	CODESOCIETE varchar(15) primary key,
	VILLE varchar(50),
	LIBELLEDEPARTEMENT integer,
	LIBELLEREGIONCOMMERCIALE varchar(15)
);

COPY ref_magasin FROM 'F:\Data\doc\DATA_Projet_R\REF_MAGASIN.CSV'

-------------------
---REF_ARTICLE-----
-------------------

--drop table IF EXISTS ref_article;
create table ref_article 
(
	CODEARTICLE varchar(15) primary key,
	CODEUNIVERS varchar(15),
	CODEFAMILLE varchar(15),
	CODESOUSFAMILLE varchar(15)
);

COPY ref_article FROM 'F:\Data\doc\DATA_Projet_R\REF_ARTICLE.CSV' CSV HEADER delimiter '|' null '';

SELECT * from ref_article limit 10;


----------------------------------------
-------------Etude globale--------------
----------------------------------------

--- 1.A* Répartition adhérent / VIP : 

---VIP : client étant VIP (VIP = 1) 
select count(idclient) as client_vip  
from client 
where vip = 1; 

---NEW_N2 : client ayant adhéré au cours de l'année N-2 (date début adhésion) 
select count(idclient) as adhéré_2016 from client 
where (extract(year from datedebutadhesion))= 2016 and vip = 0;

---NEW_N1 : client ayant adhéré au cours de l'année N-1 (date début adhésion) 
select count(idclient) as adhéré_2017 from client 
where (extract(year from datedebutadhesion))= 2017 and vip = 0;


---ADHÉRENT : client toujours en cours d'adhésion (date de fin d'adhésion > 2018/01/01) 
select count(idclient) as adhérent_présent from client
where (extract (year from datefinadhesion)) >= 2018 
and vip = 0 and (extract(year from datedebutadhesion)) not in ('2016','2017');

---CHURNER : client ayant churner (date de fin d'adhésion < 2018/01/01) 
select count(idclient) as churner from client
where (extract (year from datefinadhesion)) < 2018 
and vip = 0 and (extract(year from datedebutadhesion)) not in ('2016','2017');

----requete complete:
select count(idclient) as client_vip , 'VIP' as table_origine from client 
where vip = 1 
union select count(idclient) as adhéré_2016, 'New_N2' as table_origine from client 
where (extract(year from datedebutadhesion))= 2016 and vip = 0
union select count(idclient) as adhéré_2017, 'New_1' as table_origine from client 
where (extract(year from datedebutadhesion))= 2017 and vip = 0
union select count(idclient) as adhérent_présent, 'Adhérent' as table_origine from client
where (extract (year from datefinadhesion)) >= 2018 
and vip = 0 and (extract(year from datedebutadhesion)) not in ('2016','2017')
union select count(idclient) as churner, 'Churner' as table_origine from client
where (extract (year from datefinadhesion)) < 2018 
and vip = 0 and (extract(year from datedebutadhesion)) not in ('2016','2017');

----- l'extraction de la requetes : 

COPY (select count(idclient) as client_vip , 'VIP' as table_origine from client 
where vip = 1 
union select count(idclient) as adhéré_2016, 'New_N2' as table_origine from client 
where (extract(year from datedebutadhesion))= 2016 and vip = 0
union select count(idclient) as adhéré_2017, 'New_1' as table_origine from client 
where (extract(year from datedebutadhesion))= 2017 and vip = 0
union select count(idclient) as adhérent_présent, 'Adhérent' as table_origine from client
where (extract (year from datefinadhesion)) >= 2018 
and vip = 0 and (extract(year from datedebutadhesion)) not in ('2016','2017')
union select count(idclient) as churner, 'Churner' as table_origine from client
where (extract (year from datefinadhesion)) < 2018 
and vip = 0 and (extract(year from datedebutadhesion)) not in ('2016','2017')) 
TO 'F:\Data\doc\result\VIP.CSV' DELIMITER ',' CSV HEADER;

-----------------------------
--- 1.B. CA par clients : ---
-----------------------------

--- pour l'année 2016:
-- Je retire le client 36829 car à l'extracte des données le client cumule un CA de 3M environs
Select idclient, sum(tic_totalttc) 
from entete_ticket 
where extract (year from tic_date) = 2016 and idclient IS DISTINCT FROM '36829' 
group by idclient
order by sum(tic_totalttc)  desc; 

--- exportation du CA 2016 : 

copy (Select idclient, sum(tic_totalttc) 
	  from entete_ticket 
	  where extract (year from tic_date) = 2016 and idclient IS DISTINCT FROM '36829' 
	  group by idclient)
TO 'C:\Users\Public\CA_2016.CSV' DELIMITER ',' CSV HEADER


--- pour l'année 2017:
-- Je retire le client 62402 car à l'extracte des données le client cumule un CA de 2 229 999 999,00 €
Select idclient, sum(tic_totalttc) from entete_ticket 
where extract (year from tic_date) = 2017 and idclient IS DISTINCT FROM '62402' 
group by idclient
order by sum(tic_totalttc)  desc; 

--- exportation du CA 2017 : 

COPY (Select idclient, ROUNDsum(tic_totalttc)
	  from entete_ticket 
	  where extract (year from tic_date) = 2017 and idclient IS DISTINCT FROM '62402' 
	  group by idclient
	  order by sum(tic_totalttc)  desc) 
TO 'C:\Users\Public\CA_2017.CSV' DELIMITER ',' CSV HEADER;

----------------------------------
--- 1.C.répartition age* sexe: ---
----------------------------------

--- pour la répartition age * sexe j'ai fait le choix de créer en premier une colonne tranche d'age:

Alter table client add tranche_age varchar(10);

ALTER TABLE client ADD AGE integer;
update client set tranche_age = DATE_PART('year',current_date) - DATE_PART('year', datenaissance);

ALTER TABLE client add tranche_age_cat varchar(10);
UPDATE client set tranche_age_cat = ( case 
                 when tranche_age between '18' and  '24' then 'Jeune'
                 when tranche_age between '25' and '64' then 'Adulte'
				 when tranche_age between '65' and '100' then 'Senior'
				when tranche_age > '101' then 'extrême'
	             else 'manquante'
end);


--- Aprés avoir créer la tranche d'age, en sachant que j'ai pris un age entre 18 et 100
--- pour eviter les valeurs extrames et abberantes, aussi j'ai rajouté une tanche d'age appelé manquante
--- elle inclue les données manquantes et les 1000 valeurs aberrantes. 

-- Pour plus de cohérance nous allons réutiliser la query vus en cours 
ALTER TABLE client ADD civilite_new varchar(10);
UPDATE client set civilite_new = (case 
					when civilite in ('Mr','monsieur','MONSIEUR') then 'Monsieur'
					when civilite in ('Mme','madame','MADAME') then 'Madame'
					else null
	end); UPDATE client set civilite = civilite_new 
	
select count(idclient), civilite, tranche_age_cat from client group by civilite, tranche_age_cat;

--- exportation sexe * age :
COPY (select count(idclient), civilite, tranche_age_cat from client group by civilite, tranche_age_cat) 
TO 'C:\Users\Public\Tranche_age.CSV' DELIMITER ',' CSV HEADER;

------------------------------------
---------Etude par magasin---------- 
------------------------------------

-----A - Resultat par magasin ------
-----Nombre total par magasin 
Select codesociete as Magasin from ref_magasin inner join client
on client.magasin = ref_magasin.codesociete group by codesociete;

-----Nombre de client rattache par magasin 
select count (distinct idclient) as total_client , codesociete from entete_ticket 
inner join ref_magasin on entete_ticket.mag_code= ref_magasin.codesociete
group by codesociete;

-----Nombre de client actif sur N-2

select count (distinct idclient) as total_actif_N_2, codesociete from entete_ticket 
inner join ref_magasin on entete_ticket.mag_code= ref_magasin.codesociete
where extract(year from tic_date) = 2016 group by codesociete;

-----Nombre de client actif sur N-1
select count (distinct idclient) as total_actif_N_1, codesociete from entete_ticket 
inner join ref_magasin on entete_ticket.mag_code= ref_magasin.codesociete
where extract(year from tic_date) = 2017 group by codesociete;

-----% CLIENT N-2 vs N-1 (couleur police : vert si positif, rouge si négatif) 
select total_client, total_actif_N_2, total_actif_N_1,
((total_actif_N_1/ total_actif_N_2::numeric) * 100) as evolution_pourcentage
from (select count (distinct idclient) as total_client , codesociete from entete_ticket 
inner join ref_magasin on entete_ticket.mag_code= ref_magasin.codesociete
group by codesociete) t1 inner join (select count (distinct idclient) as total_actif_N_2, codesociete 
from entete_ticket 
inner join ref_magasin on entete_ticket.mag_code= ref_magasin.codesociete
where extract(year from tic_date) = 2016 group by codesociete) t2 on t1.codesociete = t2.codesociete 
inner join (select count (distinct idclient) as total_actif_N_1, codesociete from entete_ticket 
inner join ref_magasin on entete_ticket.mag_code= ref_magasin.codesociete
where extract(year from tic_date) = 2017 group by codesociete) t3 on t2.codesociete = t3.codesociete; 


------TOTAL_TTC N-2
select sum (tic_totalttc) as tic_totalttc_N_2, codesociete from entete_ticket 
inner join ref_magasin on entete_ticket.mag_code= ref_magasin.codesociete
where extract(year from tic_date) = 2016 group by codesociete, extract(year from tic_date);

------TOTAL_TTC N-1
select sum (tic_totalttc) as tic_totalttc_N_1, codesociete from entete_ticket 
inner join ref_magasin on entete_ticket.mag_code= ref_magasin.codesociete
where extract(year from tic_date) = 2017 group by extract(year from tic_date);

-----Différence entre N-2 et N-1 (couleur police : vert si positif, rouge si négatif) 
select tic_totalttc_N_2,tic_totalttc_N_1, (tic_totalttc_N_1 - tic_totalttc_N_2) as différence from 
(select sum (tic_totalttc) as tic_totalttc_N_2, codesociete from entete_ticket 
inner join ref_magasin on entete_ticket.mag_code= ref_magasin.codesociete
where extract(year from tic_date) = 2016 group by codesociete, extract(year from tic_date)) t4
inner join (select sum (tic_totalttc) as tic_totalttc_N_1, codesociete from entete_ticket 
inner join ref_magasin on entete_ticket.mag_code= ref_magasin.codesociete
where extract(year from tic_date) = 2017 group by codesociete, extract(year from tic_date)) t5 
on t4.codesociete = t5.codesociete;

-----indice évolution (icône de satisfaction : positif si %client actif évolue et total TTC aussi, 
-----négatif si diminution des 2 indicateurs, moyen seulement l'un des deux diminue)

---- la requète total 2.a :
select Magasin, total_client, total_actif_N_2, total_actif_N_1,
((total_actif_N_1/ total_actif_N_2::numeric) * 100)-100 as evolution_pourcentage, tic_totalttc_N_2,
tic_totalttc_N_1, (tic_totalttc_N_1 - tic_totalttc_N_2) as différence 
from (Select codesociete as Magasin from ref_magasin inner join client
on client.magasin = ref_magasin.codesociete group by codesociete) t6
inner join (select count (distinct idclient) as total_client , codesociete from entete_ticket 
inner join ref_magasin on entete_ticket.mag_code= ref_magasin.codesociete
group by codesociete) t1 on t6.Magasin = t1.codesociete
inner join (select count (distinct idclient) as total_actif_N_2, codesociete 
from entete_ticket 
inner join ref_magasin on entete_ticket.mag_code= ref_magasin.codesociete
where extract(year from tic_date) = 2016 group by codesociete) t2 on t1.codesociete = t2.codesociete 
inner join (select count (distinct idclient) as total_actif_N_1, codesociete from entete_ticket 
inner join ref_magasin on entete_ticket.mag_code= ref_magasin.codesociete
where extract(year from tic_date) = 2017 group by codesociete) t3 on t2.codesociete = t3.codesociete
inner join (select sum (tic_totalttc) as tic_totalttc_N_2, codesociete from entete_ticket 
inner join ref_magasin on entete_ticket.mag_code= ref_magasin.codesociete
where extract(year from tic_date) = 2016 group by codesociete, extract(year from tic_date)) t4
on t3.codesociete = t4.codesociete 
inner join (select sum (tic_totalttc) as tic_totalttc_N_1, codesociete from entete_ticket 
inner join ref_magasin on entete_ticket.mag_code= ref_magasin.codesociete
where extract(year from tic_date) = 2017 group by codesociete, extract(year from tic_date)) t5 
on t4.codesociete = t5.codesociete; 

select codesociete, total_actif_N_2, total_actif_N_1,((total_actif_N_1 - total_actif_N_2) * 100 / total_actif_N_2 > 0 ) as evolution_pourcentage
from(
select *
from
(select count (distinct idclient) as total_actif_N_2, codesociete from entete_ticket
inner join ref_magasin on entete_ticket.mag_code= ref_magasin.codesociete
where extract(year from tic_date) = 2016 group by codesociete ) t1
join
(select count (distinct idclient) as total_actif_N_1, codesociete from entete_ticket
inner join ref_magasin on entete_ticket.mag_code= ref_magasin.codesociete
where extract(year from tic_date) = 2017 group by codesociete) t2
using (codesociete)) as t3 

----extraction de la requète : * a adapter le % 
COPY (select Magasin, total_client, total_actif_N_2, total_actif_N_1,
((total_actif_N_1/ total_actif_N_2::numeric) * 100) as evolution_pourcentage, tic_totalttc_N_2,
tic_totalttc_N_1, (tic_totalttc_N_1 - tic_totalttc_N_2) as différence 
from (Select codesociete as Magasin from ref_magasin inner join client
on client.magasin = ref_magasin.codesociete group by codesociete) t6
inner join (select count (distinct idclient) as total_client , codesociete from entete_ticket 
inner join ref_magasin on entete_ticket.mag_code= ref_magasin.codesociete
group by codesociete) t1 on t6.Magasin = t1.codesociete
inner join (select count (distinct idclient) as total_actif_N_2, codesociete 
from entete_ticket 
inner join ref_magasin on entete_ticket.mag_code= ref_magasin.codesociete
where extract(year from tic_date) = 2016 group by codesociete) t2 on t1.codesociete = t2.codesociete 
inner join (select count (distinct idclient) as total_actif_N_1, codesociete from entete_ticket 
inner join ref_magasin on entete_ticket.mag_code= ref_magasin.codesociete
where extract(year from tic_date) = 2017 group by codesociete) t3 on t2.codesociete = t3.codesociete
inner join (select sum (tic_totalttc) as tic_totalttc_N_2, codesociete from entete_ticket 
inner join ref_magasin on entete_ticket.mag_code= ref_magasin.codesociete
where extract(year from tic_date) = 2016 group by codesociete, extract(year from tic_date)) t4
on t3.codesociete = t4.codesociete 
inner join (select sum (tic_totalttc) as tic_totalttc_N_1, codesociete from entete_ticket 
inner join ref_magasin on entete_ticket.mag_code= ref_magasin.codesociete
where extract(year from tic_date) = 2017 group by codesociete, extract(year from tic_date)) t5 
on t4.codesociete = t5.codesociete) 
TO 'C:\Users\Public\Resultat_magasin.CSV' DELIMITER ',' CSV HEADER;

------------------------------------
-----Distance CLIENT / MAGASIN------
------------------------------------

----- STEP 1 : création de la table INSEE -----
-- Attention ici on importe seulement 5 col du document insee ci joint (inseeV2): 
-- Code INSEE;Commune;geo_point_2d;Code Postal;Code Département

--drop table IF EXISTS insee;
create table insee
(
	codeinsee varchar(100) primary key, -- je ne peux pas mettre en integer car des départements code possèdes des lettres exemple http://www.linternaute.com/ville/bastia/ville-2B033 
	commune varchar(100),
	geopoint varchar(100),
	postalcode varchar(100), -- je ne peux pas mettre en integer car des départements code possèdes des lettres exemple http://www.linternaute.com/ville/bastia/ville-2B033
	departementcode varchar(100), -- je ne peux pas mettre en integer car des départements code possèdes des lettres exemple http://www.linternaute.com/ville/bastia/ville-2B033
	Région varchar(100)
);
Copy insee from 'F:\Data\doc\DATA_Projet_R\inseeV2.csv' WITH DELIMITER ';' CSV HEADER null '';


----- STEP 2 : Uniformiser les tables -----

-- On arrange les code_dpt spéciaux (ex : la corse)
UPDATE insee SET departementcode = REPLACE(departementcode, 'B', ''); 
UPDATE insee SET departementcode = REPLACE(departementcode, 'A', ''); 
ALTER TABLE insee ALTER COLUMN departementcode TYPE INT USING departementcode::integer;
ALTER TABLE insee ALTER COLUMN postalcode TYPE INT USING postalcode::integer;

-- On remplace tous les "ST" par "SAINT" dans la table magasin.
UPDATE ref_magasin
SET ville = REPLACE(ville, 'ST', 'SAINT')
where ville in (select ville
from ref_magasin 
where ville ilike 'ST %');


-- On retire le mot "CEDEX" trouvé dans la table magasin et insee.
UPDATE ref_magasin
SET ville = REPLACE(ville, 'CEDEX', ' ');

UPDATE insee
SET commune = REPLACE(commune, 'CEDEX', ' '); 

-- On retire tous les tirets "-" dans la table magasin et insee. 
UPDATE insee
SET commune = REPLACE(commune, '-', ' '); 

UPDATE ref_magasin
SET ville = REPLACE(ville, '-', ' ');

 ; 
 
----- STEP 3 : Jointures magasin x client x insee -----

---- 3.1 preparation : ----
-- rappel des noms de colonnes 
-- TAB Insee > codeinsee, commune, postalcode, departementcode, région
-- TAB ref_magasin > x,ville,x, libelledepartement, libelleregioncommerciale
-- TAB client > codeinsee,x,x,x,x

---- 3.1.1 Uniformisation des noms de colonnes ----
-- Colonne "Code INSEE" en "CODEINSEE"
ALTER TABLE insee RENAME COLUMN codeinsee TO codeinsee;

--Colonne "Commune" en "VILLE".
ALTER TABLE insee RENAME COLUMN commune TO ville;

--Colonne "libelleregioncommerciale" en "region".
ALTER TABLE ref_magasin RENAME COLUMN libelleregioncommerciale TO region;

--Colonne "libelledepartement" en "departementcode".
ALTER TABLE ref_magasin RENAME COLUMN libelledepartement TO departementcode;

---- 3.1.2 Splite du geopoint en deux colonnes LATITUDE x LONGITUDE ----

-- Création des tables latitude et longitude 
 	ALTER TABLE insee ADD LATITUDE varchar(100);
	ALTER TABLE insee ADD LONGITUDE varchar(100);


-- Ajout des données 
UPDATE insee
SET    LATITUDE = geopoint; 
UPDATE insee
SET    LONGITUDE = geopoint;

-- On garde la latitude et on supprime la longitude 
update insee set LATITUDE = left(LATITUDE, position(',' in LATITUDE));
-- On garde la longitude et on supprime la tatitude 
update insee set LONGITUDE = right(LONGITUDE, LENgth(LONGITUDE) - position(',' in LONGITUDE));
-- on uniformise            
UPDATE insee
SET LATITUDE = REPLACE(LATITUDE, ',', ''); 
UPDATE insee
SET LATITUDE = REPLACE(LATITUDE, '"', ''); 
UPDATE insee
SET LATITUDE = REPLACE(LATITUDE, '(', ''); 
UPDATE insee
SET LATITUDE = REPLACE(LATITUDE, ')', ''); 

UPDATE insee
SET LONGITUDE = REPLACE(LONGITUDE, ',', ''); 
UPDATE insee
SET LONGITUDE = REPLACE(LONGITUDE, '"', ''); 
UPDATE insee
SET LONGITUDE = REPLACE(LONGITUDE, '(', ''); 
UPDATE insee
SET LONGITUDE = REPLACE(LONGITUDE, ')', ''); 

---- 3.1.3 tronc du code postal pour l'utiliser par la suite ----

--ALTER TABLE insee drop COLUMN IF EXISTS postalcodetronc;
ALTER TABLE insee ADD postalcode2 varchar(100);
UPDATE insee SET postalcode2 = postalcode ; 
UPDATE insee SET postalcode2 = SUBSTR(postalcode2 , 1, 2);


---- STEP 3.2 création de la table location.magasin (jointure des tables magasin x insee) ----
--ref_magasin = ville departementcode region
--insee = departementcode region latitude longitude ville

--drop table IF EXISTS location_magasin ;
CREATE TABLE location_magasin3 
AS
SELECT insee.codeinsee, insee.postalcode, insee.longitude, insee.latitude, ref_magasin.departementcode, ref_magasin.ville, ref_magasin.region, ref_magasin.codesociete
FROM ref_magasin
left join insee on insee.departementcode = ref_magasin.departementcode;
-- Renommage certaine collonne 

ALTER TABLE location_magasin3 RENAME COLUMN longitude TO latitude_mag;
ALTER TABLE location_magasin3 RENAME COLUMN latitude TO longitude_mag;

-- Après exploration des données il manque les villes 'LES MILLES'; laberge;Nevers; Saint julien genevoois; dans la table insee il faut ajouter toute la ligne automatiquement 
select ref_magasin.ville
from ref_magasin
left join insee on insee.ville = ref_magasin.ville
where insee.ville is null;
--resulte
--ville ; departement code ; region
--"LES MILLES" ; 13 ; "Littoral"
-- trouver sur maps : lattitudemag = '43.503340' longitudemag = '5.385634': code postal 13290
INSERT INTO location_magasin3
--(postalcode,  longitude_mag, latitudemag, departementcode, ville, region)
VALUES (13290,'5.385634', '43.503340', '13', 'LES MILLES', 'Littoral');



---- STEP 3.3 création de la table location.client (jointure des tables client x insee) ----
--  🚨 Attention de bien avoir traiter les valeurs null avant auparament ici certain id client n'ont pas de codeinsee
select count(idclient)
from client
where codeinsee is null;

CREATE TABLE location_client  
AS
SELECT insee.postalcode, insee.codeinsee, client.idclient, client.vip, insee.VILLE, client.MAGASIN, insee.LATITUDE, insee.LONGITUDE 
FROM client
left join insee on insee.CODEINSEE = client.codeinsee  
where client.codeinsee is not null;

-- Renommage certaine collonne 
ALTER TABLE location_client RENAME COLUMN longitude TO latitude_client;
ALTER TABLE location_client RENAME COLUMN latitude TO longitude_client;


  
---- step 3.4  création de la table location.geoloc (jointure des tables location.magasin x location.client ) ----
-- ERROR: out of memory for query result
--drop table IF EXISTS location_geoloc;  

drop table location_geoloc 
(	IDCLIENT real primary key, 
	VIP integer, 
	LATITUDE_CLIENT varchar(100), 
	LONGITUDE_CLIENT varchar(100),  
	MAGASIN varchar(100), 
	codesociete varchar(10), 
	LATITUDE_MAG varchar(100), 
	LONGITUDE_MAG varchar(100)
);


create view location_geoloc7
AS
select 	cli.MAGASIN, cli.codeinsee, cli.IDCLIENT, cli.vip, cli.LATITUDE_CLIENT, cli.LONGITUDE_CLIENT, cli.ville_client,
		mag.codesociete, mag.LATITUDE_MAG, mag.LONGITUDE_MAG, mag.ville_magasin, mag.region_magasin
from ( 
		select location_client.MAGASIN, location_client.codeinsee, location_client.IDCLIENT, location_client.vip, location_client.LATITUDE_CLIENT, location_client.LONGITUDE_CLIENT, location_client.ville as ville_client
		from location_client 
) as cli,
	 ( 	
		 select location_magasin.codesociete, location_magasin.LATITUDE_MAG, location_magasin.LONGITUDE_MAG, location_magasin.ville as ville_magasin, location_magasin.region as region_magasin
		from location_magasin
) as mag 


		create view location_geoloc6
AS
select location_client.codeinsee, location_client.IDCLIENT, location_client.LATITUDE_CLIENT, location_client.LONGITUDE_CLIENT, location_client.MAGASIN, 
location_magasin.codesociete, location_magasin.LATITUDE_MAG, location_magasin.LONGITUDE_MAG as lc
from location_magasin
join location_client as lm on lc.codeinsee = lm.codeinsee


--- exportation pour le mapping :
COPY ( select distinct IDCLIENT, LATITUDE_CLIENT, LONGITUDE_CLIENT, MAGASIN, LATITUDE_MAG, LONGITUDE_MAG from location_geoloc ) 
TO 'F:\Data\doc\DATA_Projet_R\maps.CSV' DELIMITER ',' CSV HEADER;


-- nombre de client par magasin
select magasin, count(distinct idclient)
from  location_geoloc 
group by magasin

-- nombre de client par magasin x ville x région 
select region_magasin, ville_client, magasin, count(idclient)
from  location_geoloc 
group by region_magasin, ville_client, magasin

-- nombre de magasin x ville x région 
select region_magasin, ville_magasin, count(magasin)
from  location_geoloc 
group by region_magasin, ville_magasin


------ fonction qui détermine la distance ----------
Créer une fonction qui détermine la distance entre 2 points. La fonction doit prendre 4 variable en
compte : latitude1, longitude1, latitude2, longitude2
pour savoir si la fonction est correct : http://www.lexilogos.com/calcul_distances.htm
Constituer une représentation (tableau ou graphique --> au choix) représentant le nombre de client par
distance : 0 à 5km, 5km à 10km, 10km à 20km, 20km à 50km, plus de 50km


-- export pour jointure Python/R/Excel							   
		COPY (select *
			 from location_magasin3)
TO 'C:\Users\Public\location_magasin3.CSV' DELIMITER ',' CSV HEADER;					   
							   
					COPY (select *
			 from location_client)
TO 'C:\Users\Public\location_client3.CSV' DELIMITER ',' CSV HEADER;  
				   
							   
							   
---- fonction ->>> https://www.geodatasource.com/developers/postgresql <<<-
CREATE OR REPLACE FUNCTION calculate_distance(lat1 float, lon1 float, lat2 float, lon2 float, units varchar)
RETURNS float AS $dist$
    DECLARE
        dist float = 0;
        radlat1 float;
        radlat2 float;
        theta float;
        radtheta float;
    BEGIN
        IF lat1 = lat2 OR lon1 = lon2
            THEN RETURN dist;
        ELSE
            radlat1 = pi() * lat1 / 180;
            radlat2 = pi() * lat2 / 180;
            theta = lon1 - lon2;
            radtheta = pi() * theta / 180;
            dist = sin(radlat1) * sin(radlat2) + cos(radlat1) * cos(radlat2) * cos(radtheta);

            IF dist > 1 THEN dist = 1; END IF;

            dist = acos(dist);
            dist = dist * 180 / pi();
            dist = dist * 60 * 1.1515;

            IF units = 'K' THEN dist = dist * 1.609344; END IF;
            IF units = 'N' THEN dist = dist * 0.8684; END IF;

            RETURN dist;
        END IF;
    END;
$dist$ LANGUAGE plpgsql;

-- https://medium.com/sroze/postgresql-changer-le-type-dune-colonne-9ce272bee2b5			   
ALTER TABLE location_geoloc ALTER COLUMN LATITUDE_CLIENT TYPE float--; USING LATITUDE_CLIENT::float;	
ALTER TABLE location_geoloc ALTER COLUMN LONGITUDE_CLIENT TYPE float;-- USING LONGITUDE_CLIENT::float;	
ALTER TABLE location_geoloc ALTER COLUMN LATITUDE_MAG TYPE float;-- USING LATITUDE_MAG::float;	
ALTER TABLE location_geoloc ALTER COLUMN LONGITUDE_MAG TYPE float;-- USING LONGITUDE_MAG::float;	

ALTER TABLE location_client  ALTER COLUMN LATITUDE_CLIENT TYPE float USING LATITUDE_CLIENT::float;	
ALTER TABLE location_client  ALTER COLUMN LONGITUDE_CLIENT TYPE float USING LONGITUDE_CLIENT::float;	
ALTER TABLE location_magasin3 ALTER COLUMN LATITUDE_MAG TYPE float USING LATITUDE_MAG::float;	
ALTER TABLE location_magasin3 ALTER COLUMN LONGITUDE_MAG TYPE float USING LONGITUDE_MAG::float;		


							   -- Itération --
--create view distance11 AS SELECT location_client.idclient, location_magasin3.codesociete,  calculate_distance(location_client.LATITUDE_CLIENT, location_client.LONGITUDE_CLIENT, location_magasin3.LATITUDE_MAG, location_magasin3.LONGITUDE_MAG, 'k') as distance from location_client 
--right join location_magasin3 on location_magasin3.codesociete = location_client.magasin limit 1000 ;
--alter table location_client add distance_CM varchar(200);	
--update location_client
--set distance_CM = distance   from distance					   
		 					   
--sELECT calculate_distance(location_geoloc.LATITUDE_CLIENT, location_geoloc.LONGITUDE_CLIENT, location_geoloc.LATITUDE_MAG, location_geoloc.LONGITUDE_MAG, 'k')from location_geoloc;
--sELECT calculate_distance(location_client .LATITUDE_CLIENT, location_client .LONGITUDE_CLIENT, location_magasin3.LATITUDE_MAG, location_magasin3.LONGITUDE_MAG, 'k')from location_client join location_magasin3 on location_magasin3.codesociete = location_client.magasin;
							   
alter table location_client add distance_CM varchar(200);	
update location_client
	set distance_CM = (case
		when calculate_distance(subq.LATITUDE_CLIENT, subq.LONGITUDE_CLIENT, subq.LATITUDE_MAG, subq.LONGITUDE_MAG, 'k') <= 5 then  '> 5km'
		when calculate_distance(subq.LATITUDE_CLIENT, subq.LONGITUDE_CLIENT, subq.LATITUDE_MAG, subq.LONGITUDE_MAG, 'k') <= 10 then '5 > 10km'
		when calculate_distance(subq.LATITUDE_CLIENT, subq.LONGITUDE_CLIENT, subq.LATITUDE_MAG, subq.LONGITUDE_MAG, 'k') <= 20 then '10 > 20km'
		when calculate_distance(subq.LATITUDE_CLIENT, subq.LONGITUDE_CLIENT, subq.LATITUDE_MAG, subq.LONGITUDE_MAG, 'k') <= 50 then '20 > 50km'
		when calculate_distance(subq.LATITUDE_CLIENT, subq.LONGITUDE_CLIENT, subq.LATITUDE_MAG, subq.LONGITUDE_MAG, 'k') > 50 then  '50km >'
		else null
	end)
from (select location_client.idclient as idclient, location_client.LATITUDE_CLIENT as LATITUDE_CLIENT, location_client.LONGITUDE_CLIENT as LONGITUDE_CLIENT, location_magasin3.LATITUDE_MAG as LATITUDE_MAG, location_magasin3.LONGITUDE_MAG as LONGITUDE_MAG 
	  from location_client 
	join location_magasin3 on location_magasin3.codesociete = location_client.magasin) as subq
	where location_client.idclient = subq.idclient;
							   
	 --  
 ------------------------------------
--------- Etude par univers ---------
-------------------------------------


-- a) histogramme N-2 / N-1 évolution du CA par univers
select * from lignes_ticket limit 20
select * from ref_article limit 20
-- Total CA par univers N-2 (2016)
ROUND((sum (tic_totalttc), 2)

select sum (tic_totalttc) as CA_2016,codeunivers from entete_ticket 
inner join lignes_ticket 
on entete_ticket.idticket = lignes_ticket.idticket
inner join ref_article
on lignes_ticket.idarticle = ref_article.codearticle
where extract(year from tic_date) = 2016 group by codeunivers
	  
-- Total CA par univers N-1 (2017)
select sum(tic_totalttc) as CA_2017,codeunivers from entete_ticket 
inner join lignes_ticket 
on entete_ticket.idticket = lignes_ticket.idticket
inner join ref_article
on lignes_ticket.idarticle = ref_article.codearticle
where extract(year from tic_date) = 2017 group by codeunivers
	  
-- extraction de la requete pour CA 2016: 
copy (select sum (tic_totalttc) as CA_2016,codeunivers from entete_ticket 
inner join lignes_ticket 
on entete_ticket.idticket = lignes_ticket.idticket
inner join ref_article
on lignes_ticket.idarticle = ref_article.codearticle
where extract(year from tic_date) = 2016 group by codeunivers)
TO 'C:\Users\Public\CA_2016_UNIVERS.CSV' DELIMITER ',' CSV HEADER;
	  
-- extraction de la requete pour CA 2017
COPY (select sum(tic_totalttc) as CA_2017,codeunivers from entete_ticket 
inner join lignes_ticket 
on entete_ticket.idticket = lignes_ticket.idticket
inner join ref_article
on lignes_ticket.idarticle = ref_article.codearticle
where extract(year from tic_date) = 2017 group by codeunivers)
TO 'C:\Users\Public\CA_2017_UNIVERS.CSV' DELIMITER ',' CSV HEADER;
	  
--b) 
--Afficher le top 5 des familles les plus rentable par univers (en fonction de la marge obtenu) 
--Une famille rentable , c'est une famille qui génére une marge positif (donc margesortie > 0)
--l'univers coupon ne contient pas de famille, sert a comptabiliser les CA générer par les coupons 

	  -- ajout du code univers le plus rentable
Select distinct codefamille from ref_article 
	  
select codeunivers, codefamille, sum(margesortie) from ref_article
inner join lignes_ticket
on ref_article.codearticle = lignes_ticket.idarticle
group by codeunivers,codefamille
having sum(margesortie) > 0 order by sum(margesortie) desc limit 5
	  
	  
--Top familles , les plus rentable au sein de l'univers U0:
Select distinct codefamille from ref_article where codeunivers = 'U0'
select distinct codefamille, sum(margesortie),codeunivers from ref_article
inner join lignes_ticket
on ref_article.codearticle = lignes_ticket.idarticle
group by codefamille,codeunivers
having codeunivers = 'U0' and sum(margesortie) > 0 order by sum(margesortie) desc limit 5
	  
-- Remarque : les codes famille 900 et 990 ne génerent pas de marge positif, elles sert surement a des rembourssement / retour client
--Top familles , les plus rentable au sein de l'univers U1:
Select distinct codefamille from ref_article where codeunivers = 'U1'
select distinct codefamille, sum(margesortie),codeunivers from ref_article
inner join lignes_ticket
on ref_article.codearticle = lignes_ticket.idarticle
group by codefamille,codeunivers
having codeunivers = 'U1' and sum(margesortie) > 0 order by sum(margesortie) desc limit 5
	  
--Top familles , les plus rentable au sein de l'univers U2:
Select distinct codefamille from ref_article where codeunivers = 'U2'-- (il n'y a que 4 familles au sein de l'univers U2)
select distinct codefamille, sum(margesortie),codeunivers from ref_article
inner join lignes_ticket
on ref_article.codearticle = lignes_ticket.idarticle
group by codefamille,codeunivers
having codeunivers = 'U2' and sum(margesortie) > 0 order by sum(margesortie) desc limit 5
	  
--Top familles , les plus rentable au sein de l'univers U3:
Select distinct codefamille from ref_article where codeunivers = 'U3'-- (il n'ya que 2 familles au sein de l'univer U3)
select distinct codefamille, sum(margesortie),codeunivers from ref_article
inner join lignes_ticket
on ref_article.codearticle = lignes_ticket.idarticle
group by codefamille,codeunivers
having codeunivers = 'U3' and sum(margesortie) > 0 order by sum(margesortie) desc limit 5
	  
--Top familles , les plus rentable au sein de l'univers U4:
Select distinct codefamille from ref_article where codeunivers = 'U4' -- (il n'y a que 3 codes famille au sein de l'univer U4)
select distinct codefamille, sum(margesortie),codeunivers from ref_article
inner join lignes_ticket
on ref_article.codearticle = lignes_ticket.idarticle
group by codefamille,codeunivers
having codeunivers = 'U4' and sum(margesortie) > 0 order by sum(margesortie) desc limit 5
	  
	  
	  select codeunivers,codefamille, sum(margesortie) from ref_article
inner join lignes_ticket
on ref_article.codearticle = lignes_ticket.idarticle
group by codeunivers,codefamille
having sum(margesortie) > 0 order by sum(margesortie) desc limit 5
	 
	  
	  
 
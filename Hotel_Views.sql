﻿-- VIEWS

-- freieZimmerView 
-- zeigt Hotels an, die noch freie Zimmer haben, mit Kategorie und Anzahlzimmer in Kategorie
CREATE OR REPLACE VIEW freieZimmerView AS
SELECT hotelid,COALESCE(ezmm,0) as ezmm,COALESCE(ezom,0) as ezom,COALESCE(dzmm,0) as dzmm ,COALESCE(dzom,0) as dzom,COALESCE (suit,0) as suit,COALESCE(trmm,0) as trmm,COALESCE(trom,0)as trom
FROM

(SELECT hotelid from hotel) AS HOTELSA
LEFT OUTER JOIN
(WITH B AS  (
WITH A AS (SELECT *
	FROM reservierungen
	WHERE Anreise=current_date OR Gaestestatus = 'IN-HOUSE')
SELECT zimmer.gehoertzuhotel as hotela, zimmer.zimmerkategorie
	FROM zimmer LEFT OUTER JOIN A
	 ON (zimmernummer = zimmer AND zimmer.gehoertzuhotel = A.gehoertzuhotel)
	 ORDER By hotela ASC)	 
SELECT B.hotela, count(zimmerkategorie) as EZMM
FROM B
WHERE zimmerkategorie = 'EZMM'
GROUP BY B.hotela) as C
on hotelid=hotela
LEFT OUTER JOIN
(WITH E AS  (
WITH D AS (SELECT *
	FROM reservierungen
	WHERE Anreise=current_date OR Gaestestatus = 'IN-HOUSE' )
SELECT zimmer.gehoertzuhotel as hotelB, zimmer.zimmerkategorie
	FROM zimmer LEFT OUTER JOIN D
	 ON (zimmernummer = zimmer AND zimmer.gehoertzuhotel = D.gehoertzuhotel)
	 ORDER By hotelB ASC)	 
SELECT E.hotelB, count(zimmerkategorie) as EZOM
FROM E
WHERE zimmerkategorie = 'EZOM'
GROUP BY E.hotelB) AS F
on hotelid=hotelb
LEFT OUTER JOIN

(WITH Z AS  (
WITH Y AS (SELECT *
	FROM reservierungen
	WHERE Anreise=current_date OR Gaestestatus = 'IN-HOUSE' )
SELECT zimmer.gehoertzuhotel as hotelC, zimmer.zimmerkategorie
	FROM zimmer LEFT OUTER JOIN Y
	 ON (zimmernummer = zimmer AND zimmer.gehoertzuhotel = Y.gehoertzuhotel)
	 ORDER By hotelC ASC)	 
SELECT Z.hotelC, count(zimmerkategorie) as DZMM
FROM Z
WHERE zimmerkategorie = 'DZMM'
GROUP BY Z.hotelC) AS G
ON hotelid=hotelc

LEFT OUTER JOIN
(WITH X AS  (
WITH V AS (SELECT *
	FROM reservierungen
	WHERE Anreise=current_date OR Gaestestatus = 'IN-HOUSE' )
SELECT zimmer.gehoertzuhotel as hotelD, zimmer.zimmerkategorie
	FROM zimmer LEFT OUTER JOIN V
	 ON (zimmernummer = zimmer AND zimmer.gehoertzuhotel = V.gehoertzuhotel)
	 ORDER BY hotelD ASC)	 
SELECT X.hotelD, count(zimmerkategorie) as DZOM
FROM X
WHERE zimmerkategorie = 'DZOM'
GROUP BY X.hotelD) AS H
ON hotelid=hoteld

LEFT OUTER JOIN

(WITH O AS  (
WITH P AS (SELECT *
	FROM reservierungen
	WHERE Anreise=current_date OR Gaestestatus = 'IN-HOUSE' )
SELECT zimmer.gehoertzuhotel AS hotelF , zimmer.zimmerkategorie
	FROM zimmer LEFT OUTER JOIN P
	 ON (zimmernummer = zimmer AND zimmer.gehoertzuhotel = P.gehoertzuhotel)
	 ORDER By hotelF  ASC)	 
SELECT O.hotelF , count(zimmerkategorie) as SUIT
FROM O
WHERE zimmerkategorie = 'SUIT'
GROUP BY O.hotelF ) AS I
on hotelid=hotelf

LEFT OUTER JOIN

(WITH Q AS  (
WITH R AS (SELECT *
	FROM reservierungen
	WHERE Anreise=current_date OR Gaestestatus = 'IN-HOUSE' )
SELECT zimmer.gehoertzuhotel as hotelE, zimmer.zimmerkategorie
	FROM zimmer LEFT OUTER JOIN R
	 ON (zimmernummer = zimmer AND zimmer.gehoertzuhotel = R.gehoertzuhotel)
	 ORDER By hotelE ASC)	 
SELECT Q.hotelE, count(zimmerkategorie) as TRMM
FROM Q
WHERE zimmerkategorie = 'TRMM'
GROUP BY Q.hotelE) AS J
ON hotelid = hotelE

LEFT OUTER JOIN

(WITH T AS  (
WITH U AS (SELECT *
	FROM reservierungen
	WHERE Anreise=current_date OR Gaestestatus = 'IN-HOUSE' )
SELECT zimmer.gehoertzuhotel as hotelG, zimmer.zimmerkategorie
	FROM zimmer LEFT OUTER JOIN U
	 ON (zimmernummer = zimmer AND zimmer.gehoertzuhotel = U.gehoertzuhotel)
	 ORDER By hotelG ASC)	 
SELECT T.hotelG, count(zimmerkategorie) as TROM
FROM T
WHERE zimmerkategorie = 'TROM'
GROUP BY T.hotelG) as K
on hotelid = hotelg;

-- belegteZimmerView
-- Belegte Zimmer, sortiert nach Hotel und Zimmernummer
CREATE OR REPLACE VIEW belegteZimmerView AS
SELECT zugewiesenesZimmer, ZimmerInHotel, anreise, abreise, dreckig
	FROM Reservierungen JOIN Zimmer ON (zugewiesenesZimmer = Zimmernummer AND  ZimmerInHotel = gehoertZuHotel)
	WHERE Gaestestatus = 'IN-HOUSE'
	ORDER BY gehoertZuHotel ASC, ZimmerNummer ASC;

-- ReinigungspersonalView
-- Zeigt Zimmer an, die vom Personal gereinigt werden muessen, sortiert nach Hotel und Zimmernummer
CREATE OR REPLACE VIEW ReinigungspersonalView AS 
SELECT ZimmerInHotel, zugewiesenesZimmer, CASE WHEN ((current_date - Anreise > 14)OR abreise = current_date) THEN TRUE ELSE FALSE END AS grossputz
FROM belegteZimmerView
WHERE dreckig
ORDER BY ZimmerInHotel ASC, zugewiesenesZimmer ASC;

-- HotelManager 
-- Hotels sortiert nach Umsatz, mit dazugehoerigen Bars sortiert nach Umsatz, dazu die beliebteste Zimmerkategorie
CREATE OR REPLACE VIEW HotelmanagerView AS
SELECT hotelid, (umsatzrooms+konsum+mieteinnahmen+benutzteinnahmen) as gesamtumsatz
FROM
(SELECT hotelid,COALESCE (umsatzrooms, '0,00€') as umsatzrooms, COALESCE(konsum, '0,00 €') as konsum , COALESCE(mieteneinahmen, '0,00 €') as mieteinnahmen , COALESCE (benutzteinnahmen, '0,00 €') as benutzteinnahmen 
FROM (SELECT hotelid from hotel) as hotels
LEFT OUTER JOIN
(SELECT gehoertzuhotel as hotelsresa, sum(gesamtbetrag) as Umsatzrooms
FROM
(SELECT gehoertzuhotel,zimmerpreis,zimmerkategorie,reserviertvonkunde,anreise,abreise, reservierungsnummer, gaestestatus, ((abreise-anreise)*zimmerpreis) as gesamtbetrag
FROM reservierungen
WHERE gaestestatus = 'CHECKED-OUT' OR gaestestatus = 'IN-HOUSE'
ORDER BY gehoertzuHotel) AS GesamtproResa
GROUP BY hotelsresa) as umsatz --gesamtumsatz Zimmerpreis betrachtet

on hotelid=hotelsresa

LEFT OUTER JOIN

(SELECT gehoertzuhotel as hotelskonsum, sum(preis) as konsum
FROM
(SELECT DISTINCT *
FROM (konsumieren
CROSS JOIN
(SELECT gehoertzuhotel, reserviertvonkunde, anreise, abreise, reservierungsnummer, gaestestatus
FROM reservierungen
WHERE gaestestatus = 'CHECKED-OUT' OR gaestestatus = 'IN-HOUSE'
ORDER BY gehoertzuHotel) as Kunden) as Kombis
WHERE kid = reserviertvonkunde) as KonsumationenzuREsas
JOIN speisenundgetraenke
ON speisenundgetraenke.speiseid = KonsumationenzuREsas.Speiseid
GROUP BY hotelskonsum) as konsum --extraskonsumieren per hotel

ON hotelid=hotelskonsum

LEFT OUTER JOIN

(SELECT hotelid1 as hotelidmieten, sum(preis) as mieteneinahmen
FROM
(SELECT DISTINCT *
FROM (mieten
CROSS JOIN
(SELECT gehoertzuhotel as hotelid1, reserviertvonkunde, anreise, abreise, reservierungsnummer, gaestestatus
FROM reservierungen
WHERE gaestestatus = 'CHECKED-OUT' OR gaestestatus = 'IN-HOUSE'
ORDER BY hotelid1) as Kunden) as Kombis
WHERE kid = reserviertvonkunde) as Gemietet
JOIN sporteinrichtungen
ON sporteinrichtungen.aid = Gemietet.aid
GROUP BY hotelidmieten) mieteinnahmens --extramietenprohotel

ON hotelid=hotelidmieten

LEFT OUTER JOIN

(SELECT hotelid1 as hotelbe, sum(preis) as benutzteinnahmen
FROM
(SELECT DISTINCT *
FROM (benutzen
CROSS JOIN
(SELECT gehoertzuhotel as hotelid1, reserviertvonkunde, anreise, abreise, reservierungsnummer, gaestestatus
FROM reservierungen
WHERE gaestestatus = 'CHECKED-OUT' OR gaestestatus = 'IN-HOUSE'
ORDER BY hotelid1) as Kunden) as Kombis
WHERE kid = reserviertvonkunde and von >= anreise) as Benutzt
JOIN schwimmbad
ON schwimmbad.aid = Benutzt.aid
GROUP BY hotelbe) as Benutzen --extrabenutzen 

ON hotelid=hotelbe) as Umsatzkomplett



-- UnbezahlteReservierungView
-- Zeigt Kundennummer und Gesamtrechnungspreis von allen Kunden die ihre Rechnungen noch nicht bezahlt haben



-- AnreisendeView
-- Zeigt Kundenname und Zimmer aller anreisenden Gaeste des Tages an
-- sortiert nach Hotel und Kunden Nachname
CREATE OR REPLACE VIEW AnreisendeView AS
WITH Anreisende AS
	(SELECT Reservierungsnummer
	FROM Reservierungen
	WHERE Stornierungsnummer = NULL AND Anreise = current_date
	EXCEPT ALL 
	(SELECT Reservierungsnummer
	FROM Ablehnungen))

	SELECT gehoertZuHotel, Nachname, Zimmernummer, VIP 
	FROM Anreisende JOIN Reservierungen ON Anreisende.Reservierungsnummer = Reservierungen.Reservierungsnummer






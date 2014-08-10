﻿-- VIEWS

-- freieZimmerView 
-- zeigt Hotels an, die noch freie Zimmer haben, mit Kategorie und Anzahlzimmer in Kategorie
CREATE OR REPLACE VIEW freieZimmerView AS
SELECT hotelid, count(CASE WHEN zimmerkategorie='EZOM' THEN 1 ELSE NULL END) as ezom, count(CASE WHEN zimmerkategorie='EZMM' THEN 1 ELSE NULL END) as ezmm, count(CASE WHEN zimmerkategorie='DZOM' THEN 1 ELSE NULL END) as dzom, count(CASE WHEN zimmerkategorie='DZMM' THEN 1 ELSE NULL END) as dzmm, count(CASE WHEN zimmerkategorie='TROM' THEN 1 ELSE NULL END) as trom, count(CASE WHEN zimmerkategorie='TRMM' THEN 1 ELSE NULL END) as trmm, count(CASE WHEN zimmerkategorie='SUIT' THEN 1 ELSE NULL END) as suit
FROM
(WITH BelegtenZimmer AS (SELECT *
	FROM reservierungen
	WHERE Anreise=current_date OR Gaestestatus = 'IN-HOUSE')
SELECT zimmer.gehoertzuhotel as hotelid, zimmer.zimmerkategorie
	FROM zimmer LEFT OUTER JOIN BelegtenZimmer
	 ON (zimmernummer = zimmer AND zimmer.gehoertzuhotel = BelegtenZimmer.gehoertzuhotel)
	 ORDER By hotelid ASC) freieZimmer
GROUP BY hotelid;

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
SELECT hotelid,(umsatzrooms+konsum+mieteinnahmen+benutzteinnahmen) as gesamtumsatz, COALESCE (umsatzbar, '0,00 €') as Barumsatz, COALESCE (ezom, 0)as ezom, COALESCE(ezmm,0) as ezmm, COALESCE(dzom,0) as dzom, COALESCE(dzmm,0) as dzmm, COALESCE (trom,0) as trom , COALESCE (trmm,0) as trmm, COALESCE (suit,0) as suit
FROM
((SELECT hotelid,COALESCE (umsatzrooms, '0,00€') as umsatzrooms, COALESCE(konsum, '0,00 €') as konsum , COALESCE(mieteneinahmen, '0,00 €') as mieteinnahmen , COALESCE (benutzteinnahmen, '0,00 €') as benutzteinnahmen 
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

ON hotelid=hotelbe)as Gesamtumsatz--GEsamtumsatz


LEFT OUTER JOIN

(SELECT gehoertzuhotel as wo, count(CASE WHEN zimmerkategorie='EZOM' THEN 1 ELSE NULL END) as ezom, count(CASE WHEN zimmerkategorie='EZMM' THEN 1 ELSE NULL END) as ezmm, count(CASE WHEN zimmerkategorie='DZOM' THEN 1 ELSE NULL END) as dzom, count(CASE WHEN zimmerkategorie='DZMM' THEN 1 ELSE NULL END) as dzmm, count(CASE WHEN zimmerkategorie='TROM' THEN 1 ELSE NULL END) as trom, count(CASE WHEN zimmerkategorie='TRMM' THEN 1 ELSE NULL END) as trmm, count(CASE WHEN zimmerkategorie='SUIT' THEN 1 ELSE NULL END) as suit
FROM reservierungen
WHERE gaestestatus = 'CHECKED-OUT' OR gaestestatus = 'IN-HOUSE'
GROUP BY wo
ORDER BY wo) as TOTALGebuchteZImmer --alle kategorieszimmerreservierungen checked-out und in-house
on hotelid=wo) as alles

LEFT OUTER JOIN

(SELECT imhotel, sum(preis) UmsatzBar
from (konsumieren join hotelbar ON imhotel=hotelbar.gehoertzuhotel and verspeistin = hotelbar.aid) as Hotelbars
JOIN
speisenundgetraenke
ON Hotelbars.speiseid = speisenundgetraenke.speiseid
GROUP BY imhotel) as Barumsatz
on Barumsatz.imhotel = hotelid
ORDER BY hotelid ASC;





-- UnbezahlteReservierungView
-- Zeigt Kundennummer und Gesamtrechnungspreis von allen Kunden die ihre Rechnungen noch nicht bezahlt haben


SELECT resa,kunde, anreise,abreise, Konsumsumme, Benutzensumme, mietensumme, zimmerpreis, (Konsumsumme+Benutzensumme+mietensumme+zimmerpreis) as OffeneREchnungssumme
FROM
(SELECT resa,kunde, anreise2 as anreise,abreise2 as abreise, COALESCE(sum(preis), '0,00 €') as Konsumsumme, COALESCE(sum(benutzensumme), '0,00 €') as Benutzensumme, COALESCE(sum(mietensumme), '0,00 €') as mietensumme, zimmerpreis
FROM
((((SELECT reservierungen.reservierungsnummer as resa,kunde, anreise, abreise
FROM
(SELECT reservierungsnummer,reserviertvonkunde as kunde
FROM reservierungen
WHERE gaestestatus='IN-HOUSE'
EXCEPT
SELECT reservierungsnummer,kid
from bezahlen) as NichtbezahlteREservierungen
JOIN
reservierungen
on NichtBezahlteReservierungen.reservierungsnummer = reservierungen.reservierungsnummer) NichtBezahlt
LEFT OUTER JOIN
konsumieren
JOIN
speisenundgetraenke ON konsumieren.speiseid = speisenundgetraenke.speiseid
on Nichtbezahlt.kunde=konsumieren.kid AND zeitpunkt >= anreise AND zeitpunkt <=Abreise) as konsum  -- extras speisen und getraenke

LEFT OUTER JOIN

(SELECT resanr,kunde2, preis as benutzensumme
FROM
((SELECT reservierungsnummer as resanr,reserviertvonkunde as kunde2
FROM reservierungen
WHERE gaestestatus='IN-HOUSE'
EXCEPT
SELECT reservierungsnummer,kid
from bezahlen) as NichtbezahlteREservierungen
JOIN
reservierungen
on NichtBezahlteReservierungen.resanr = reservierungen.reservierungsnummer ) as NichtBezahlt
LEFT OUTER join
benutzen
join 
schwimmbad on benutzen.aid = schwimmbad.aid
on Nichtbezahlt.kunde2 = benutzen.kid and von >= Anreise and bis <=Abreise) as Benutzensumme --BENUtzenSumme
ON Benutzensumme.resanr = konsum.resa) as STEP1


LEFT OUTER JOIN

(SELECT resanr,kunde3,preis as mietensumme
FROM
(((SELECT reservierungsnummer as resanr,reserviertvonkunde as kunde3
FROM reservierungen
WHERE gaestestatus='IN-HOUSE'
EXCEPT
SELECT reservierungsnummer,kid
from bezahlen) as NichtbezahlteReservierungen
JOIN
reservierungen
on NichtBezahlteReservierungen.resanr = reservierungen.reservierungsnummer ) NichtBezahlt
join
mieten
join 
sporteinrichtungen on sporteinrichtungen.aid= mieten.aid 
on Nichtbezahlt.kunde3 = mieten.kid and von >= Anreise and bis <=Abreise) as gemietet) as Summemiete --mieten SUMME
on step1.resanr = Summemiete.resanr) as STEP2

LEFT OUTER JOIN

(SELECT NichtbezahlteReservierungen.reservierungsnummer as resa2, kid,anreise as anreise2,abreise as abreise2, ((current_date-anreise)*zimmerpreis)as Zimmerpreis
FROM
(SELECT reservierungsnummer,reserviertvonkunde as kid
FROM reservierungen
WHERE gaestestatus='IN-HOUSE'
EXCEPT
SELECT reservierungsnummer,kid
from bezahlen) as NichtbezahlteREservierungen
JOIN
reservierungen
on NichtBezahlteReservierungen.reservierungsnummer = reservierungen.reservierungsnummer) as zimmersumme --Zimmerpeis Summe

ON Step2.resa=zimmersumme.resa2

GROUP BY resa, kunde, anreise2,abreise2, zimmerpreis) as AlleSummen;



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
	FROM Anreisende JOIN Reservierungen ON Anreisende.Reservierungsnummer = Reservierungen.Reservierungsnummer;






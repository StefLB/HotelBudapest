-- VIEWS

-- freieZimmerView 
-- zeigt Hotels an, die noch freie Zimmer haben, mit Kategorie und Anzahlzimmer in Kategorie
CREATE OR REPLACE VIEW freieZimmerView AS
WITH A AS (SELECT *
	FROM reservierungen
	WHERE Anreise=current_date OR Gaestestatus = 'IN-HOUSE' )
SELECT zimmer.gehoertzuhotel, zimmer.zimmerkategorie
	FROM zimmer LEFT OUTER JOIN A
	 ON (zimmernummer = zimmer AND zimmer.gehoertzuhotel = A.gehoertzuhotel)
	 ORDER By gehoertZuHotel ASC;


CREATE OR REPLACE VIEW freieZimmerView AS
SELECT hotelid, hotelb,hotelc,hoteld,hotela,hotelf, ezmm,ezom,dzmm,dzom,trmm,trom,suit

FROM

(SELECT *

FROM (SELECT hotelid FROM hotel) AS A

CROSS JOIN

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

CROSS JOIN

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

CROSS JOIN

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

CROSS JOIN

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

CROSS JOIN

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

CROSS JOIN

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

CROSS JOIN

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
GROUP BY T.hotelG) K ) as M

WHERE M.hotelid = M.hotelg ;


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






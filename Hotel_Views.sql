-- VIEWS

-- freieZimmerView - TO DO - Steffi
-- zeigt Hotels an, die noch freie Zimmer haben, mit Kategorie und Anzahlzimmer in Kategorie
CREATE OR REPLACE VIEW freieZimmerView AS
SELECT gehoertzuhotel, zimmernummer, zimmer.zimmerkategorie, dreckig, outoforder,maxpersonen 
	FROM zimmer LEFT OUTER JOIN reservierungen ON (zimmernummer = zugewieseneszimmer AND gehoertzuhotel = zimmerinhotel)
	WHERE Anreise=current_date AND Gaestestatus = 'IN-HOUSE'
	ORDER By gehoertZuHotel ASC, Zimmernummer ASC;





-- belegteZimmerView
-- Belegt Zimmer, sortiert nach Hotel und Zimmernummer
CREATE OR REPLACE VIEW belegteZimmerView AS
SELECT zugewiesenesZimmer, ZimmerInHotel, anreise, abreise, dreckig
	FROM Reservierungen JOIN Zimmer ON (zugewiesenesZimmer = Zimmernummer AND  ZimmerInHotel = gehoertZuHotel)
	WHERE Gaestestatus = 'IN-HOUSE'
	ORDER BY gehoertZuHotel ASC, ZimmerNummer ASC;

-- ReinigungspersonalView
-- Zeigt Zimmer an, die vom Personal gereinigt werden muessen, sortiert nach Hotel und Zimmernummer
CREATE OR REPLACE VIEW ReinigungspersonalView AS 
SELECT ZimmerInHotel, zugewiesenesZimmer, CASE WHEN ((current_date - Anreise > 14)OR abreise = current_date) THEN TRUE ELSE FALSE END AS bigClean
FROM belegteZimmerView
WHERE dreckig
ORDER BY ZimmerInHotel ASC, zugewiesenesZimmer ASC;

-- HotelManager 
-- Hotels sortiert nach Umsatz, mit dazugehoerigen Bars sortiert nach Umsatz, dazu die beliebteste Zimmerkategorie





-- UnbezahlteReservierungView



-- AnreisendeView
-- Zeigt alle anreisenden Gaeste des Tages an








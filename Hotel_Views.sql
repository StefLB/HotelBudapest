-- Views

-- belegteZimmerView: Belegt Zimmer, sortiert nach Hotel und Zimmernummer
CREATE OR REPLACE VIEW belegteZimmerView AS
SELECT zugewiesenesZimmer, ZimmerInHotel, dreckig
	FROM Reservierungen JOIN Zimmer ON (zugewiesenesZimmer = Zimmernummer AND  ZimmerInHotel = gehoertZuHotel)
	WHERE Gaestestatus = 'IN-HOUSE'
	ORDER BY gehoertZuHotel ASC, ZimmerNummer ASC;

-- Reinigungspersonal
-- Zeigt Zimmer an, die vom Personal gereinigt werden muessen, sortiert nach Hotel und Zimmernummer
CREATE OR REPLACE VIEW ReinigungspersonalView AS 
SELECT gehoertZuHotel, Zimmernummer
FROM Zimmer
WHERE dreckig
ORDER BY gehoertZuHotel ASC, ZimmerNummer ASC;

-- HotelManager 




-- Freie Sportplaetze
-- Ein Gast moechte sehen, welche Sportplaetze am jetzigen Tag noch zu vermieten sind
CREATE OR REPLACE VIEW 




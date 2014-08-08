-- VIEWS

-- 

-- belegteZimmerView
-- Belegt Zimmer, sortiert nach Hotel und Zimmernummer
CREATE OR REPLACE VIEW belegteZimmerView AS
SELECT zugewiesenesZimmer, ZimmerInHotel, dreckig
	FROM Reservierungen JOIN Zimmer ON (zugewiesenesZimmer = Zimmernummer AND  ZimmerInHotel = gehoertZuHotel)
	WHERE Gaestestatus = 'IN-HOUSE'
	ORDER BY gehoertZuHotel ASC, ZimmerNummer ASC;

-- ReinigungspersonalView
-- Zeigt Zimmer an, die vom Personal gereinigt werden muessen, sortiert nach Hotel und Zimmernummer
CREATE OR REPLACE VIEW ReinigungspersonalView AS 
SELECT gehoertZuHotel, Zimmernummer
FROM Zimmer
WHERE dreckig
ORDER BY gehoertZuHotel ASC, ZimmerNummer ASC;

-- HotelManager 





-- UnbezahlteReservierungView



-- GourmetGastView
-- Ein Gast moechte alle Hotel Restaurants angezeigt bekommen die mehr als 3 Sterne haben
CREATE OR REPLACE VIEW GourmetGastView AS 


-- FreieSportplaetzeView 
-- Ein Gast moechte sehen, welche Sportplaetze am jetzigen Tag noch zu vermieten sind
CREATE OR REPLACE VIEW FreieSportplaetzeView




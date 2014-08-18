/* LESEOPERATIONEN

10 Leseoperationen, vier davon keine skalaren Unteranfragen

INHALTSANGABE

1. Der Manager Herr 'Goldfish', der gleichzeitig zwei Hotels betreut, moechte vom 'Witz-Garlton', sowie vom 'The Octopus' den bis zum heutigen Tage angenommen Gesamtumsatz des 
Hotels betrachten, aufgesplittet.

2. Die leitende Hausdame, Frau '


*/

/* 1. 'Witz-Garlton' & 'The Octopus' Manager fragt an*/

	WITH Goldfish  as(
		SELECT hotelid,gesamtumsatz, umsatzrooms, barumsatz,konsumumsatz,mietumsatz,benutzenumsatz
		FROM HotelmanagerView
		WHERE hotelid=3 

		UNION

		SELECT hotelid, gesamtumsatz, umsatzrooms, barumsatz,konsumumsatz,mietumsatz,benutzenumsatz
		FROM HotelmanagerView
		WHERE hotelid=4)
	SELECT Goldfish.hotelid, hotelname, adresse, hoteltyp, gesamtumsatz, umsatzrooms, barumsatz,konsumumsatz,mietumsatz,benutzenumsatz
	FROM Goldfish
	JOIN hotel
	on Goldfish.hotelid = hotel.hotelid



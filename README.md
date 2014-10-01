BuscarTextoEnTablas
===================

BuscarTextoEnTablas
-------------------

Es un procedimiento almacenado desarrollado para SQL Server diseñado par buscar una cadena de texto especifica ya sea en todas las tabals o en un conjunto de tablas.


SINTAXIS:
---------

-Si se buscara el texto en todas las tablas:
				
				BuscarTextoEnTablas '<Texto a Buscar>'	
				Ej: BuscarTextoEnTablas 'A Bike Store',1 

-Si se buscara el texto en un grupo especifico de tablas:
				
				BuscarTextoEnTablas '<Texto a Buscar> IN <Tabla 1>,<Tabla 2>, <Tabla N>' 
				Ej: BuscarTextoEnTablas 'A Bike Store IN dimreseller,dimaccount,dimdate' 
				
-Opcionalmente se puede especificar 1 despues del texto para indicar si se requiere mostrar el query generado en la pestaña de "Mensajes". Si no se indica nada automaticamente asume que no se requiere.	 

REFERENCIAS:
------------
								
-Basado en la idea y trabajo de Narayana Vyas Kondreddi [SearchAllTables/http://vyaskn.tripod.com/search_all_columns_in_all_tables.htm]			

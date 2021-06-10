/**
 * Clase controladora para la integración de envíos de pedidos y sus seguimientos
 * @author jsetienr
 * @date 08/06/2021
*/
public without sharing class ShipmentController 
{

    //Método principal que recibida una petición mediante el WS_TrackShipments realiza el guardado en Salesforce de la información del envío y sus productos
    //Devolverá una lista con los resultados correctos
    public static List<WS_TrackShipments.ShipmentsResponse> trackShipments (Object shipments)
    {
        //Listas con las respuestas a la operación de inserción
        List<WS_TrackShipments.ShipmentsResponse> responses = new List<WS_TrackShipments.ShipmentsResponse>();
            
        try 
        {
            /**
             * CODE HERE
             */
        }
        catch (Exception ex) 
        {
            System.debug('upserting Shipment exception::' + ex.getMessage());
           //Devolvemos excepcion
           responses.add(
                    new WS_TrackShipments.ShipmentsResponse(null, Constants.RESPONSE_NOK, ex.getMessage())
           );
        }
        return responses;
    }

}

/**
 * Servicio Web de integración de envíos de pedidos.
 * Permite  el volcado de información y detalle de los envíos en la instancia de Salesforce
 * Invocado por el proveedor
 * 
 * @author jsetienr
 * @date 08/06/2021
 * 
 * Ejemplo petición JSON:
 * * /services/apexrest/trackShipments
 *
    {
        "envios" : [{
            "fecha_envio" : "yyyy-mm-dd",
            "id_producto" : "string",
            "descripción Producto" : "string",
            "cantidad" : integer,
            "almacen_Destino" : "string"
        }]
    }
*/


@RestResource(urlMapping='/trackShipments/*')
global without sharing class WS_TrackShipments 
{

    /** 
     * Metodo POST para la recepción de información de los envíos en el servicio rest
     *
     * @author jsetienr
     * @date 08/06/2021
    */
    @HttpPost
    global static void trackShipments()
    {
        WSShipmentResponse shipmentsResponse = new WSShipmentResponse();

        Blob body = RestContext.request.requestBody;

        //Validación de Datos
        if(body == null || String.isBlank(body.toString()))
        {                       
            shipmentsResponse.results = new List<ShipmentsResponse>{
                new ShipmentsResponse('', Constants.RESPONSE_NOK, Constants.RESPONSE_ERROR_NO_BODY)
            };
            shipmentsResponse.setResponse(Restcontext.response);
            return;
        }

        try 
        {
            // 1 - Parseamos petición
            // 1.1 - Convertimos el bruto del cuerpo de la petición
            Map<String, Object> wsShipmentRequest = (Map<String, Object>)JSON.deserializeUntyped(body.toString());

            // 1.2 - Extraemos la lista de envíos
            List<Object> shipmentsList = (List<Object>) wsShipmentRequest.get('envios');
            
            List<ShipmentObject> shipments = new List<ShipmentObject>();

            // 1.3 - Convertimos cada uno de los envíos en el objeto auxiliar ShipmentObject
            for(Object shipmentElement : shipmentsList)
            {
                ShipmentObject shipment = new ShipmentObject(shipmentElement);
                shipments.add(shipment);
            }

            // 2 - Elaboramos las respuestas del Servicio y realizamos el volcado de la información en Sf
            List<ShipmentsResponse> responses = ShipmentController.trackShipments(shipments);
            shipmentsResponse.results = responses; 
        } 
        catch (Exception ex) 
        {
            shipmentsResponse.results = new List<ShipmentsResponse>{
                new ShipmentsResponse('', Constants.RESPONSE_NOK, ex.getMessage())
            };
        }

        // 3 - Enviamos respuesta
        shipmentsResponse.setResponse(Restcontext.response);

    }

    /*
     * Clase wrapper para la respuesta del WS
    */
    global class WSShipmentResponse
    {
        webservice List<ShipmentsResponse> results {get;set;}
        
        public WSShipmentResponse()
        {
            
        }

        public string toStringJSON()
        {
            return JSON.serialize(this,true);
        }

        
        public void setResponse(RestResponse restResponse)
        {                         
            restResponse.addHeader('Content-Type', 'application/json; charset=UTF-8');
            restResponse.addHeader('Transfer-Encoding', null);
            restResponse.responseBody = Blob.valueOf(this.toStringJSON());
        }
    }
    
    /*
     * Clase wrapper con el resultado de un único registro
    */
    global class ShipmentsResponse
    {
        webservice String id { get; set; }          
        webservice String isSuccess { get; set; }
        webservice String error { get; set; }

        
        public ShipmentsResponse()
        {
            
        }

        public ShipmentsResponse(String id, String isSuccess, String error)
        {
            this.id = id;
            this.isSuccess = isSuccess;
            this.error = error;
        }
    }

}
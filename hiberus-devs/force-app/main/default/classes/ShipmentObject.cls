public with sharing class ShipmentObject {

    //#region Atributos del Objeto
    public Date sendDate;
    public String productId;
    public String description;
    public Integer quantity;
    public String warehouseCode;
    public String name;
    public String shipmentName;
    //#endregion

    /**
     * Método constructor principal de ShipmentObject
     * @author jsetienr
     * @date 10/06/2021
     * @param Object record - Objeto primo recibido en el WS que se convertirá en un objeto nuevo formato más amigable y gestionable en Salesforce
    */
    public ShipmentObject(Object record)
    {
        Map<String, Object> shipment = (Map<String, Object>) record;
        checkFields(shipment);
        try
        {
                this.sendDate       = Date.parse(getDate(String.valueOf(shipment.get('fecha_envio'))));
                this.productId      = String.valueOf(shipment.get('id_producto'));
                this.description    = String.valueOf(shipment.get('descripción Producto'));
                this.quantity       = Integer.valueOf(shipment.get('cantidad'));
                this.warehouseCode  = String.valueOf(shipment.get('almacen_Destino'));
                this.name           = getName(shipment);
                this.shipmentName   = calculateRandomShipmentName(shipment);
        } catch(Exception error) 
        {
            System.debug(error);
            throw new ShipmentController.ServiceException(error);
        }
    }

    //#region Métodos de utilidad
    /**
     * Método que recibe una estructura de fecha y la parsea para poder parsearla en Salesforce
     * @author jsetienr
     * @date 10/06/2021
     * @param String shipDate - Fecha recibida en el formato "yyyy-mm-dd"
     * @return String -> Fecha reestructurada para poder parsearla en Salesforce, con la estructura "dd/mm/yyyy"
    */
    private String getDate(String shipDate)
    {
        List<String> dateParams = shipDate.split('-', 0);
        return dateParams[2] + '/' + dateParams[1] + '/' + dateParams[0];
    }

    /**
     * Método que recibe el objeto primo y retorna un nombre compuesto
     * @author jsetienr
     * @date 10/06/2021
     * @param Map<String,Object> shipment - Objeto en bruto
     * @return String -> Valor del nombre calculado para el objeto
    */
    private String getName(Map<String, Object> shipment)
    {
        return  (String.valueOf(shipment.get('almacen_Destino'))
                + '-'
                + String.valueOf(shipment.get('id_producto')));
    }

    /**
     * Método que calcula un nombre aleatorio para el envío
     * @author jsetienr
     * @date 10/06/2021
     * @param Map<String,Object> shipment - Objeto en bruto
     * @return String -> Valor del nombre calculado para el código de envío
    */
    private String calculateRandomShipmentName(Map<String,Object> shipment)
    {
        String codeName = String.valueOfGmt(Datetime.now());

        codeName = codeName.replace('-', '');
        codeName = codeName.replace(':', '');
        codeName = codeName.replace(' ', '');
        codeName += String.valueOf(shipment.get('almacen_Destino'));
        codeName += String.valueOf(shipment.get('id_producto'));

        return codeName.toUpperCase();
    }

    /**
     * Método que comprobará si el código del almacén reportado es correcto y está entre los válidos
     * @author jsetienr
     * @date 10/06/2021
     * @return Boolean -> Si el código de almacén es válido, se devolverá true, en caso contrario, false
    */
    public Boolean checkForValidWarehouse()
    {
        if (Constants.VALID_WAREHOUSES.isEmpty() || !Constants.VALID_WAREHOUSES.contains(this.warehouseCode))
        {
            return false;
        }

        return true;
    }    

    /**
     * Método que comprobará la integridad de los campos recibidos en el objeto del servicio de integración
     * @author jsetienr
     * @date 11/06/2021
     * @param Map<String,Object> shipment - Mapa que representa el objeto de envío recibido en el servicio 
    */
    private static void checkFields(Map<String, Object> shipment)
    {
        for(String field : shipment.keySet())
        {
            if(!Constants.EXPECTED_FIELDS.contains(field))
            {
                System.debug('Se ha reportado un campo no contemplado:: ' + field);
                throw new ShipmentController.ServiceException(
                    Constants.RESPONSE_ERROR_INCORRECT_FIELD + ': ' + field + ' ('
                    + 'Expected Fields: ' + String.join(Constants.EXPECTED_FIELDS, ', ') + ')');
            }
        }
    }
    //#endregion
}
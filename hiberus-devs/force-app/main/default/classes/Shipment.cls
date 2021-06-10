public with sharing class Shipment {

    //#region Atributos del Objeto
    public Date sendDate;
    public String productId;
    public String description;
    public Integer quantity;
    public String warehouseCode;
    //#endregion

    /**
     * Método constructor principal de Shipment
     * @author jsetienr
     * @date 10/06/2021
     * @param Object record - Objeto primo recibido en el WS que se convertirá en un objeto nuevo formato más amigable y gestionable en Salesforce
    */
    public Shipment(Object record)
    {
        Map<String, Object> shipment = (Map<String, Object>) record;
        try
        {
                this.sendDate       = Date.parse(getDate(String.valueOf(shipment.get('fecha_envio'))));
                this.productId      = String.valueOf(shipment.get('id_producto'));
                this.description    = String.valueOf(shipment.get('descripción Producto'));
                this.quantity       = Integer.valueOf(shipment.get('cantidad'));
                this.warehouseCode  = String.valueOf(shipment.get('almacen_Destino'));
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
    //#endregion
}
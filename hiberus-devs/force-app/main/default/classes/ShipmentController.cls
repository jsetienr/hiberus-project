/**
 * Clase controladora para la integración de envíos de pedidos y sus seguimientos
 * @author jsetienr
 * @date 08/06/2021
*/
public without sharing class ShipmentController 
{
    //#region Variables auxiliares del proceso
        //#region Identificadores del proceso de Envío 
    private static Set<String> processedShipments = new Set<String>();
    private static Set<String> processedProducts = new Set<String>();
    private static Map<String, List<String>> productsByShipMap = new Map<String, List<String>>();
        //#endregion
        //#region Identificadores de Localizaciones y almacenes 
    private static Boolean hasInitializedLocations = false;
    private static Map<String, String> locationsMap = new Map<String, String>();
        //#endregion
        //#region Mapa asociativo de registros procesados por tipo
    private static Map<String, Map<String, String>> idRecordsMapByType = new Map<String, Map<String, String>>();
        //#endregion
    //#endregion

    /**
     * Método principal que recibida una petición mediante el WS_TrackShipments realiza el guardado
     * en Salesforce de la información del envío y sus productos
     * @author jsetienr
     * @date 08/06/2021
     * @param List<ShipmentObject> shipments - Lista de objetos con la información del envío
     * @return List<WS_TrackShipments.ShipmentsResponse> - Lista con los resultados correctos del procesamiento del WS
    */
    public static List<WS_TrackShipments.ShipmentsResponse> trackShipments(List<ShipmentObject> shipments)
    {
        //Listas con las respuestas a la operación de inserción
        List<WS_TrackShipments.ShipmentsResponse> responses = new List<WS_TrackShipments.ShipmentsResponse>();
        //Creamos la lista de los envíos registrados en el proceso
        List<Shipment> shipmentListToSave = new List<Shipment>();
        //Creamos la lista de los productos registrados en el proceso
        List<Product2> productListToSave = new List<Product2>();
        //Creamos la lista de los objetos relacionales envío-producto registrados en el proceso
        List<shipmentItem> shipmentItemListToSave = new List<shipmentItem>();
        try 
        {
            for(ShipmentObject shipment : shipments)
            {
                // 1 - Validamos si el envío tiene el formato adecuado (y código de almacén)
                if (shipment.checkForValidWarehouse())
                {
                    // 2.a - Extraemos la información para convertir en el SObject Shipment el objeto ShipmentObject
                    Shipment salesforceShipment = extractShipmentList(shipment);
                    shipmentListToSave.add(salesforceShipment);
    
                    // 2.b - Extraemos la información para convertir en el SObject Product2 el objeto ShipmentObject
                    Product2 salesforceProduct = extractProductList(shipment);
                    productListToSave.add(salesforceProduct);

                    // 3 - Almacenamos los Ids de los registros procesados
                    processedShipments.add(shipment.shipmentName);
                    processedProducts.add(shipment.name);

                    if(productsByShipMap.containsKey(shipment.shipmentName))
                    {
                        productsByShipMap.get(shipment.shipmentName).add(shipment.name);
                    }
                    else
                    {
                        List<String> shipmentNames = new List<String>();
                        shipmentNames.add(shipment.name);

                        productsByShipMap.put(shipment.shipmentName, shipmentNames);
                    }
                }
                else
                {
                    throw new ServiceException(
                        Constants.RESPONSE_ERROR_BAD_WAREHOUSE + ': '+ shipment.warehouseCode
                        + ' from External Id: ' + shipment.productId);    
                }          
            }

            // 4 - Realizamos la operación DML con los registros en Salesforce
            // 4.1 - Actualizamos, si procede, los stock de los registros antes de la inserción/actualización
            productListToSave = calculateStocksByWarehouse(productListToSave);
            // 4.2 - Salvamos los registros
            insert shipmentListToSave;
            upsert productListToSave ProductId__c;
    
            // 5 - Establecemos la relación entre los pedidos y los productos en ShipmentItem
            // 5.1 - Creamos la lista con los registros relacionales
            shipmentItemListToSave = extractShipmentItemList(shipments);
            // 5.2 - Salvamos los registros relacionales
            insert shipmentItemListToSave;

            // 6 - Construyo respuesta del WS
            for(ShipmentObject shipment : shipments)
            {
                responses.add(
                    new WS_TrackShipments.ShipmentsResponse(
                        shipment.productId,
                        Constants.RESPONSE_OK,
                        null
                    )
                );
            }
        }
        catch (Exception ex) 
        {
            System.debug('upserting ShipmentObject exception::' + ex.getMessage());
           //Devolvemos excepcion
           responses.add(
                    new WS_TrackShipments.ShipmentsResponse(null, Constants.RESPONSE_NOK, ex.getMessage())
           );
        }
        return responses;
    }

    //#region Métodos auxiliares de construcción
    /**
     * Método que, recibido un objeto del tipo ShipmentObject, elabora un registro Shipment con la información extraída del objeto
     * @author jsetienr
     * @date 10/06/2021
     * @param ShipmentObject shipment - Objeto del tipo ShipmentObject con la información necesaria
     * @return Shipment - Registro elaborado con la información necesaria para su inserción en Salesforce
    */
    @TestVisible private static Shipment extractShipmentList(ShipmentObject shipment) //TODO cambiar nombre, no devuelve una lista
    {
        // 1 - Si no se han inicializado ya los recursos de Localizaciones, los iniciamos
        if(!hasInitializedLocations)
        {
            initializeLocations();
        }

        // 2 - Construimos el registro Shipment con los parámetros del ShipmentObject
        Shipment salesforceShipment = new Shipment();
        salesforceShipment.DestinationLocationId = locationsMap.get(shipment.warehouseCode);
        salesforceShipment.ActualDeliveryDate = shipment.sendDate;
        salesforceShipment.ShipToName = shipment.shipmentName;

        // 3 - Devolvemos el registro
        return salesforceShipment;
    }

    /**
     * Método que, recibido un objeto del tipo ShipmentObject, elabora un registro Product2 con la información extraída del objeto
     * @author jsetienr
     * @date 10/06/2021
     * @param ShipmentObject shipment - Objeto del tipo ShipmentObject con la información necesaria
     * @return Product2 - Registro elaborado con la información necesaria para su inserción en Salesforce
    */
    @TestVisible private static Product2 extractProductList(ShipmentObject shipment)
    {
        // 1 - Construimos el registro Product2 con los parámetros del ShipmentObject
        Product2 item = new Product2();
        
        item.ExternalId = shipment.name;
        item.ProductId__c = shipment.name;
        item.Description = shipment.description;
        item.Stock__c = shipment.quantity;
        item.ProductCode = shipment.productId;
        item.IsActive = true;
        item.Warehouse__c = shipment.warehouseCode;
        item.Name = shipment.name;

        // 2 - Devolvemos el registro
        return item;
    }

    /**
     * Método que, recibida una lista de objetos del tipo ShipmentObject, 
     * elabora una lista con los registros ShipmentItem con la información extraída del objeto y su relación envío-producto
     * @author jsetienr
     * @date 10/06/2021
     * @param List<ShipmentObject> shipments - Lista de objetos del tipo ShipmentObject con la información necesaria
     * @return List<ShipmentItem> - Registros elaborados con la información necesaria para su inserción en Salesforce
    */
    @TestVisible private static List<ShipmentItem> extractShipmentItemList(List<ShipmentObject> shipments)
    {
        // 1 - Cargamos los recursos para realizar las consultas de información y construir el registro relacional
        buildShipmentItemsResources();
        
        // 2 - Creamos los registros ShipmentItem y los añadimos a la lista
        List<ShipmentItem> shipmentItemsList = new List<ShipmentItem>();
        for(String shipmentId : processedShipments) //Recorremos los Ids de la lista de Envíos procesados
        {
            for(String productId : productsByShipMap.get(shipmentId)) //Recorremos la lista de productos para cada envío en el mapa asociativo
            {
                ShipmentItem shipmentItem = new ShipmentItem();
                shipmentItem.Quantity = getShipmentObjectQuantityByContext(shipments, shipmentId, productId);
                shipmentItem.ShipmentId = idRecordsMapByType.get('shipments').get(shipmentId);
                shipmentItem.Product2Id = idRecordsMapByType.get('products').get(productId);
                shipmentItemsList.add(shipmentItem);
            }
        }

        // 3 - Devolvemos la lista
        return shipmentItemsList;
    }
    //#endregion

    //#region Métodos auxiliares de consulta a Salesforce
    /**
     * Método que recupera los registros de Shipment y Product2 en base a los registros guardados 
     * en el proceso en curso, y los almacena en un mapa para su consulta
     * @author jsetienr
     * @date 10/06/2021
     * @param List<ShipmentObject> shipments - Lista con los datos de los registros insertados, para elaborar consultas y obtener sus Ids
    */
    @TestVisible private static void buildShipmentItemsResources()
    {
        // 1 - Consultamos los registros insertados en Salesforce en el proceso
        List<Shipment> processedShipmentsSaved = Database.query('SELECT Id, ShipToName FROM Shipment WHERE ShipToName IN :processedShipments');
        List<Product2> processedProducts = getProductsStored();
        
        // 2 - Creamos y establecemos mapas con las equivalencias de Ids para identificarlos
        Map<String, String> shipmentsIdsMap = new Map<String, String>();
        Map<String, String> productsIdsMap = new Map<String, String>();
        
        for(Shipment shipment: processedShipmentsSaved)
        {
            shipmentsIdsMap.put(shipment.ShipToName, shipment.Id);
        }
        
        for(Product2 product: processedProducts)
        {
            productsIdsMap.put(product.ProductId__c, product.Id);
        }
        
        // 3 - Almacenamos en un único mapa las relaciones de Ids diferenciadas por tipo de registro
        if(!idRecordsMapByType.containsKey('shipments'))
        {
            idRecordsMapByType.put('shipments', shipmentsIdsMap);
        }
        
        if(!idRecordsMapByType.containsKey('products'))
        {
            idRecordsMapByType.put('products', productsIdsMap);
        }
    }

    /**
     * Método que recupera los registros de Product2 en base a los registros guardados 
     * en el proceso en curso
     * @author jsetienr
     * @date 11/06/2021
     * @return List<Product2> - Lista con los Productos registrados en Salesforce en el proceso
    */
    @TestVisible private static List<Product2> getProductsStored()
    {
        return Database.query('SELECT Id, ProductId__c, Stock__c FROM Product2 WHERE ProductId__c in :processedProducts');
    }

    /**
     * Método que recupera las distintas localizaciones existentes en la instancia Salesforce
     * y completa el mapa que las asocia con sus Códigos de Almacén
     * @author jsetienr
     * @date 11/06/2021
    */
    @TestVisible private static void initializeLocations()
    {
        // 1 - Recuperamos las localizaciones existentes
        List<SObject> warehousesLocations = Database.query('SELECT Id, Name, ExternalReference FROM Location');
        
        // 2 - Completamos el mapa que asocia las localizaciones con su código de Almacén
        for(SObject warehouseLocation : warehousesLocations)
        {
            locationsMap.put(String.valueOf(warehouseLocation.get('ExternalReference')), String.valueOf(warehouseLocation.get('Id'))); 
        }

        // 3 - Indicamos que la inicialización se ha realizado para prevenir volver a consultarlo
        hasInitializedLocations = true;
    }

    /**
     * Método que recupera los diferentes stocks de cada producto por almacén
     * y los actualiza para su actualización/inserción
     * @author jsetienr
     * @date 11/06/2021
    */
    @TestVisible private static List<Product2> calculateStocksByWarehouse(List<Product2> productListToSave)
    {
        // 1 - Recuperamos los productos procesados que existen ya en Salesforce con un stock establecido
        List<Product2> products = getProductsStored();
        
        // 2 - Creamos y completamos el mapa que asocia las localizaciones con su código de Almacén
        Map<String, Integer> productByWarehouseStockMap = new Map<String, Integer>();
        for(Product2 product : products)
        {
            productByWarehouseStockMap.put(product.ProductId__c, Integer.valueOf(product.Stock__c)); 
        }
        // 3 - Actualizamos, si existen en Salesforce, los stock de los productos que van a procesarse
        if(!productByWarehouseStockMap.isEmpty())
        {
            for(Product2 product : productListToSave)
            {
                if(productByWarehouseStockMap.containsKey(product.ProductId__c))
                {
                    product.Stock__c +=  productByWarehouseStockMap.get(product.ProductId__c);
                }
            }
        }

        // 4 - Devolvemos la lista de productos actualizada
        return productListToSave;
    }

    /**
     * Método que, recibida una lista de registros y los parámetros de su contexto, 
     * identificará el registro concreto y devolverá el valor de Quantity
     * @author jsetienr
     * @date 11/06/2021
     * @param List<ShipmentObject> shipments - Lista de registros
     * @param String shipmentId - Identificador del envío
     * @param String productId - Identificador del producto
     * @return Integer -> Devolverá el valor de quantity del registro identificado en la lista por su contexto
    */
    private static Integer getShipmentObjectQuantityByContext(List<ShipmentObject> shipments, String shipmentId, String productId)
    {
       for(ShipmentObject shipment : shipments)
       {
            if(shipment.name == productId && shipment.shipmentName == shipmentId)
            {
                return shipment.quantity;
            }
       }

       return 0;
    }
    //#endregion

    /**************************************************************************************************************************************************************/
    /************************************************************************CLASES AUXILIARES*********************************************************************/
    /**************************************************************************************************************************************************************/
    /**
     * Clase constructora de la emisión de excepción
     * @author jsetienr
     * @date 10/06/2021 
    */
    public class ServiceException extends Exception
    {
        String sourceStackTrace = '';

        public ServiceException(String message, String sourceStackTrace)
        {
            this();
            this.setMessage(message);
            this.sourceStackTrace = sourceStackTrace;
        }

        public String toString()
        {
            return this.getMessage() + '\n' + this.sourceStackTrace;
        }
    }

}
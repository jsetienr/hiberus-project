/**
 * Clase principal para el parseo del WS de integración de envíos de productos
 *
 * @author jsetienr
 * @date 08/06/2021
*/
public with sharing class WS_Parser 
{
    //Cache de getGlobalDescribe
    private static Map<String, Schema.SObjectType> entityTypeMap = new Map<String, Schema.SObjectType>();

    //Cache de campos
    private static Map<String,Map<String, Schema.SObjectField>> fieldsMapMap = new Map<String,Map<String, Schema.SObjectField>>();

    /**
     * Parsea un objeto del WS para estructurar objetos de salesforce
     *
     * @author jsetienr
     * @date 09/06/2021
     * @param Object objectWS - Objeto recibido en el WS
    */
    public static SObject parseSObject(Object objectWS)
    {
        System.debug('parseSObject:objectWS' + objectWS);
        Schema.SObjectType entityType;
        Map<String, Schema.SObjectField> fieldsMap;

        //Generamos objeto
        sObject objectResult = entityType.newSObject() ;

        //Casteamos el objeto recibido del WS para acceder a sus propiedades
        Map<String,Object> objectWSMap = (Map<String,Object>)objectWS;                
        
        return objectResult;
    }
}
/*
 * Clase con las constantes necesarias para la gestion de la integración de seguimiento de envíos de materiales
 * @author jsetienr
 * @date 08/06/2021
*/
public without sharing class Constants 
{
 
    //Respuestas del Servicio Web
    public static final String RESPONSE_OK = 'OK';
    public static final String RESPONSE_NOK = 'NOK';
    //Mensajes de error del Servicio Web
    public static final String RESPONSE_ERROR_NO_BODY = 'You must include a body request';
    public static final String RESPONSE_ERROR_BAD_WAREHOUSE = 'The reported warehouse is not allowed or is incorrect';

    //Formato fecha SALESFORCE
    public static final String DATE_FORMAT_SALESFORCE = 'yyyy-MM-dd\'T\'HH:mm:ss\'Z\'';

    //Campos donde se almacena la informacion de control en Salesforce sobre la configuración del proceso
    public static final List<String> VALID_WAREHOUSES;

    static 
    {                
        List<trackShipmentsSetup__mdt> setupConstants = [SELECT Id, DeveloperName, Value__c
                                                            FROM trackShipmentsSetup__mdt];

        Map<String, String> setupConstantsByDevName = new Map<String, String>();

        for(trackShipmentsSetup__mdt setup : setupConstants)
        {
            if(setup.DeveloperName != null)
            {
                setupConstantsByDevName.put( setup.DeveloperName, setup.Value__c);
            }
        }

        VALID_WAREHOUSES = setupConstantsByDevName.get( 'VALID_WAREHOUSES' ).split('-', 0);
    }

}
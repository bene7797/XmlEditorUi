using System.Collections.Generic;

namespace XmlEditorUi;

/// <summary>
/// Definiert die essentiellen Felder für XML-Header (Metadaten des XML-Dokumentes).
/// Diese Felder werden im Template-Editor in der DataGrid angezeigt.
/// 
/// Header-Felder sind Metadaten des XML-Dokumentes selbst (nicht des Inhalts).
/// </summary>
public static class HeaderTemplateFields
{
    /// <summary>
    /// Felder für XML-Header und Metadaten.
    /// Format: (Label für UI, XPath im XML oder spezielle Kennzeichnung)
    /// </summary>
    public static readonly List<(string Label, string Path)> EssentialFields = new()
    {
        // Generator Info
        ("Generator Info", "HEADER/GENERATOR_INFO"),
        
        // Catalog
        ("Catalog Language", "HEADER/CATALOG/LANGUAGE"),
        ("Catalog ID", "HEADER/CATALOG/CATALOG_ID"),
        ("Catalog Version", "HEADER/CATALOG/CATALOG_VERSION"),
        ("Catalog Name", "HEADER/CATALOG/CATALOG_NAME"),
        ("Generation Date", "HEADER/CATALOG/GENERATION_DATE"),
        
        // Document Creator
        ("Creator First Name", "HEADER/DOCUMENT_CREATOR/FIRST_NAME"),
        ("Creator Last Name", "HEADER/DOCUMENT_CREATOR/LAST_NAME"),
        ("Creator Phone", "HEADER/DOCUMENT_CREATOR/PHONE"),
        ("Creator ID", "HEADER/DOCUMENT_CREATOR/ID_DB"),
        ("Creator Address Name", "HEADER/DOCUMENT_CREATOR/ADDRESS/NAME"),
        ("Creator Address Street", "HEADER/DOCUMENT_CREATOR/ADDRESS/STREET"),
        ("Creator Address ZIP", "HEADER/DOCUMENT_CREATOR/ADDRESS/ZIP"),
        ("Creator Address City", "HEADER/DOCUMENT_CREATOR/ADDRESS/CITY"),
        ("Creator Address Country", "HEADER/DOCUMENT_CREATOR/ADDRESS/COUNTRY"),
        ("Creator Address URL", "HEADER/DOCUMENT_CREATOR/ADDRESS/URL"),
        ("Creator Address ID", "HEADER/DOCUMENT_CREATOR/ADDRESS/ID_DB"),
        ("Creator Contact Remarks", "HEADER/DOCUMENT_CREATOR/CONTACT_REMARKS"),
        
        // Recipient
        ("Recipient ID", "HEADER/RECIPIENT/RECIPIENT_ID"),
        ("Recipient Name", "HEADER/RECIPIENT/RECIPIENT_NAME"),
        ("Recipient Address Name", "HEADER/RECIPIENT/ADDRESS/NAME"),
        ("Recipient Address Street", "HEADER/RECIPIENT/ADDRESS/STREET"),
        ("Recipient Address ZIP", "HEADER/RECIPIENT/ADDRESS/ZIP"),
        ("Recipient Address City", "HEADER/RECIPIENT/ADDRESS/CITY"),
        ("Recipient Address Country", "HEADER/RECIPIENT/ADDRESS/COUNTRY"),
        ("Recipient Address URL", "HEADER/RECIPIENT/ADDRESS/URL"),
        
        // Supplier
        ("Supplier ID", "HEADER/SUPPLIER/SUPPLIER_ID"),
        ("Supplier Name", "HEADER/SUPPLIER/SUPPLIER_NAME"),
        ("Supplier Address Name", "HEADER/SUPPLIER/ADDRESS/NAME"),
        ("Supplier Address Name2", "HEADER/SUPPLIER/ADDRESS/NAME2"),
        ("Supplier Address Street", "HEADER/SUPPLIER/ADDRESS/STREET"),
        ("Supplier Address ZIP", "HEADER/SUPPLIER/ADDRESS/ZIP"),
        ("Supplier Address City", "HEADER/SUPPLIER/ADDRESS/CITY"),
        ("Supplier Address State", "HEADER/SUPPLIER/ADDRESS/STATE"),
        ("Supplier Address Country", "HEADER/SUPPLIER/ADDRESS/COUNTRY"),
        ("Supplier Address Phone", "HEADER/SUPPLIER/ADDRESS/PHONE"),
        ("Supplier Address Mobile", "HEADER/SUPPLIER/ADDRESS/MOBILE"),
        ("Supplier Address Email", "HEADER/SUPPLIER/ADDRESS/EMAILS/EMAIL"),
        ("Supplier Address URL", "HEADER/SUPPLIER/ADDRESS/URL"),
        ("Supplier Contact Role", "HEADER/SUPPLIER/CONTACT/CONTACT_ROLE"),
        ("Supplier Contact Salutation", "HEADER/SUPPLIER/CONTACT/SALUTATION"),
        ("Supplier Contact First Name", "HEADER/SUPPLIER/CONTACT/FIRST_NAME"),
        ("Supplier Contact Last Name", "HEADER/SUPPLIER/CONTACT/LAST_NAME"),
        ("Supplier Contact Phone", "HEADER/SUPPLIER/CONTACT/PHONE"),
        ("Supplier Contact Mobile", "HEADER/SUPPLIER/CONTACT/MOBILE"),
        ("Supplier Contact Email", "HEADER/SUPPLIER/CONTACT/EMAILS/EMAIL"),
        ("Supplier Contact URL", "HEADER/SUPPLIER/CONTACT/URL"),
        ("Supplier Contact ID", "HEADER/SUPPLIER/CONTACT/ID_DB"),
        ("Supplier Contact Remarks", "HEADER/SUPPLIER/CONTACT/CONTACT_REMARKS"),
    };
}

using System.Runtime.InteropServices;
using System.Xml.Linq;
using System.Xml.Schema;

namespace XsdValidator;

public static class NativeExports
{
    /// <summary>
    /// Validates [xmlPath] against [schemaPath].
    /// Returns 0 on success, non-zero on failure. Error text is written to [errorBuffer].
    /// </summary>
    [UnmanagedCallersOnly(EntryPoint = "ValidateXml")]
    public static int ValidateXml(
        IntPtr xmlPathPtr,
        IntPtr schemaPathPtr,
        IntPtr errorBufferPtr,
        int errorBufferLen)
    {
        try
        {
            var xmlPath = Marshal.PtrToStringUni(xmlPathPtr) ?? "";
            var schemaPath = Marshal.PtrToStringUni(schemaPathPtr) ?? "";

            if (!File.Exists(xmlPath))
            {
                WriteError(errorBufferPtr, errorBufferLen, "XML-Datei wurde nicht gefunden.");
                return 1;
            }

            if (!File.Exists(schemaPath))
            {
                WriteError(errorBufferPtr, errorBufferLen, "XSD-Datei wurde nicht gefunden.");
                return 2;
            }

            var xmlDoc = XDocument.Load(xmlPath);
            var schemas = new XmlSchemaSet();
            schemas.Add(null, schemaPath);

            xmlDoc.Validate(schemas, (_, args) =>
                throw new XmlSchemaValidationException(args.Message));

            WriteError(errorBufferPtr, errorBufferLen, "");
            return 0;
        }
        catch (Exception ex)
        {
            WriteError(errorBufferPtr, errorBufferLen, ex.Message);
            return 3;
        }
    }

    private static void WriteError(IntPtr buffer, int len, string message)
    {
        if (buffer == IntPtr.Zero || len <= 0)
            return;

        var chars = Math.Min(message.Length, len - 1);
        Marshal.Copy(message.ToCharArray(), 0, buffer, chars);
        Marshal.WriteInt16(buffer, chars * 2, 0);
    }
}

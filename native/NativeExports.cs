using System.Runtime.InteropServices;
using System.Text;
using System.Xml.Linq;
using System.Xml.Schema;

namespace XsdValidator;

public static class NativeExports
{
    static NativeExports()
    {
        Encoding.RegisterProvider(CodePagesEncodingProvider.Instance);
    }

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
            Encoding.RegisterProvider(CodePagesEncodingProvider.Instance);

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

            var xmlDoc = LoadXml(xmlPath);
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

    /// <summary>
    /// Loads OpenQCat XML that often declares encoding="iso-8859-15".
    /// Falls back to Latin-1 style decoding if the runtime encoding is unavailable.
    /// </summary>
    private static XDocument LoadXml(string path)
    {
        try
        {
            return XDocument.Load(path);
        }
        catch (ArgumentException)
        {
            // e.g. "System does not support 'iso-8859-15' encoding"
        }
        catch (NotSupportedException)
        {
        }

        var bytes = File.ReadAllBytes(path);
        var text = DecodeOpenQBytes(bytes);
        // Declaration may still say iso-8859-15 while content is now Unicode string.
        text = System.Text.RegularExpressions.Regex.Replace(
            text,
            @"encoding\s*=\s*[""'][^""']+[""']",
            "encoding=\"utf-8\"",
            System.Text.RegularExpressions.RegexOptions.IgnoreCase);

        return XDocument.Parse(text);
    }

    private static string DecodeOpenQBytes(byte[] bytes)
    {
        if (bytes.Length >= 3 && bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF)
            return Encoding.UTF8.GetString(bytes, 3, bytes.Length - 3);

        try
        {
            return Encoding.GetEncoding("iso-8859-15").GetString(bytes);
        }
        catch (ArgumentException)
        {
        }
        catch (NotSupportedException)
        {
        }

        try
        {
            return Encoding.GetEncoding(28591).GetString(bytes); // ISO-8859-1
        }
        catch
        {
            return Encoding.Latin1.GetString(bytes);
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

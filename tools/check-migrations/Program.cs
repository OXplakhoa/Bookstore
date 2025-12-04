using System.Reflection;
using System.Reflection.Metadata;
using System.Reflection.Metadata.Ecma335;
using System.Reflection.PortableExecutable;
using System.Runtime.Loader;

Console.WriteLine("Checking migrations present in assembly: bin/Debug/net9.0/Bookstore.dll");

// Try several likely paths to find the project assembly.
string[] possiblePaths = new[]
{
    Path.GetFullPath(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "..", "..", "..", "bin", "Debug", "net9.0", "Bookstore.dll")),
    Path.GetFullPath(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "..", "..", "bin", "Debug", "net9.0", "Bookstore.dll")),
    Path.GetFullPath(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "..", "..", "..", "..", "bin", "Debug", "net9.0", "Bookstore.dll")),
    Path.GetFullPath(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "..", "..", "..", "..", "..", "bin", "Debug", "net9.0", "Bookstore.dll")),
    Path.GetFullPath(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "..", "..", "..", "..", "..", "..", "bin", "Debug", "net9.0", "Bookstore.dll")),
    Path.GetFullPath(Path.Combine(Environment.CurrentDirectory, "bin", "Debug", "net9.0", "Bookstore.dll"))
};

string? assemblyPath = null;
foreach (var p in possiblePaths)
{
    if (File.Exists(p)) { assemblyPath = p; break; }
}

if (!File.Exists(assemblyPath))
{
    Console.WriteLine($"Assembly not found at {assemblyPath}");
    return;
}

var probeDir = Path.GetDirectoryName(assemblyPath)!;
var runtimeDlls = Directory.GetFiles(probeDir, "*.dll").ToList();
// Add current runtime core assembly and its directory to resolver paths
var coreAssemblyPath = Assembly.GetAssembly(typeof(object))!.Location;
if (!string.IsNullOrEmpty(coreAssemblyPath) && File.Exists(coreAssemblyPath))
{
    var coreDir = Path.GetDirectoryName(coreAssemblyPath)!;
    var coreDlls = Directory.GetFiles(coreDir, "*.dll");
    runtimeDlls.AddRange(coreDlls);
}
// Add shared ASP.NET Core framework assemblies (so references such as Microsoft.AspNetCore.Mvc.Razor can be resolved)
var aspNetSharedRoot = "/usr/local/share/dotnet/shared/Microsoft.AspNetCore.App";
if (Directory.Exists(aspNetSharedRoot))
{
    foreach (var versionDir in Directory.GetDirectories(aspNetSharedRoot))
    {
        runtimeDlls.AddRange(Directory.GetFiles(versionDir, "*.dll"));
    }
}
runtimeDlls = runtimeDlls.Distinct().ToList();
var resolver = new PathAssemblyResolver(runtimeDlls.Concat(new[] { assemblyPath }));
// Find the core assembly name (System.Private.CoreLib) from current runtime
var coreAssemblyName = Assembly.GetAssembly(typeof(object))!.GetName().Name!;
using var mlc = new MetadataLoadContext(resolver, coreAssemblyName);
var asm = mlc.LoadFromAssemblyPath(assemblyPath);

var migrationTypes = asm.GetTypes().Where(t =>
{
    var baseType = t.BaseType;
    while (baseType != null)
    {
        if (baseType.FullName == "Microsoft.EntityFrameworkCore.Migrations.Migration")
            return true;
        baseType = baseType.BaseType;
    }
    return false;
}).ToList();

Console.WriteLine($"Found {migrationTypes.Count} migration types:\n");
foreach(var mt in migrationTypes.OrderBy(t => t.Name))
{
    Console.WriteLine(mt.FullName);
}

if(!migrationTypes.Any())
    Console.WriteLine("No migration types found in assembly. This explains why EF commands say 'No migrations were found'.");
else
    Console.WriteLine("Migrations are present in assembly; EF should detect them. If EF still says 'No migrations', there may be another issue (e.g. design-time services or MigrationAssembly mismatch).");

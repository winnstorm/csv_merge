function MostrarBanner {
@"
 ________  ________  ________  _______           ________  ________  ___      ___ 
|\   ____\|\   __  \|\   __  \|\  ___ \         |\   ____\|\   ____\|\  \    /  /|
\ \  \___|\ \  \|\  \ \  \|\ /\ \   __/|        \ \  \___|\ \  \___|\ \  \  /  / /
 \ \  \  __\ \   __  \ \   __  \ \  \_|/__       \ \  \    \ \_____  \ \  \/  / / 
  \ \  \|\  \ \  \ \  \ \  \|\  \ \  \_|\ \       \ \  \____\|____|\  \ \    / /  
   \ \_______\ \__\ \__\ \_______\ \_______\       \ \_______\____\_\  \ \__/ /   
    \|_______|\|__|\|__|\|_______|\|_______|        \|_______|\_________\|__|/    
                                                             \|_________|         
                                                                                  
                                                                                  
 ________  ________  ________  ________  _______   ________                       
|\   __  \|\   __  \|\   __  \|\   ____\|\  ___ \ |\   __  \                      
\ \  \|\  \ \  \|\  \ \  \|\  \ \  \___|\ \   __/|\ \  \|\  \                     
 \ \   ____\ \   __  \ \   _  _\ \_____  \ \  \_|/_\ \   _  _\                    
  \ \  \___|\ \  \ \  \ \  \\  \\|____|\  \ \  \_|\ \ \  \\  \|                   
   \ \__\    \ \__\ \__\ \__\\ _\ ____\_\  \ \_______\ \__\\ _\                   
    \|__|     \|__|\|__|\|__|\|__|\_________\|_______|\|__|\|__|                  
                                 \|_________|                                     
                                                                                  
                                                                                                                          
"@
}

# Función para unificar archivos CSV
function UnificarArchivosCSV {
    param(
        [string]$mascara,
        [switch]$eliminarHeader,
        [switch]$eliminarArchivosOrigen,
        [string]$nombreArchivoUnificado,
        [string]$directorio = ""
    )

    # Obtener la ruta del directorio donde se encuentra el script
    $directorioActual = if ($null -eq $MyInvocation.MyCommand.Path) { $PWD } else { Split-Path -Parent $MyInvocation.MyCommand.Path }

    # Obtener la lista de archivos CSV que coinciden con la máscara
    $archivosCSV = Get-ChildItem -Path $directorioActual -Filter $mascara -File | Where-Object { $_.Extension -eq ".csv" }

    # Verificar si se encontraron archivos CSV
    if ($archivosCSV.Count -eq 0) {
        Write-Host "No se encontraron archivos CSV que coincidan con la máscara '$mascara' en el directorio actual."
        return
    }

    # Mostrar archivos encontrados y solicitar confirmación al usuario
    Write-Host "Archivos encontrados que coinciden con la máscara '$mascara':"
    $archivosCSV | ForEach-Object { Write-Host $_.Name }
    $confirmacion = Read-Host "¿Desea continuar con estos archivos? (S/N):"

    if ($confirmacion -ne "S") {
        return
    }

    # Verificar si se proporcionó un nombre para el archivo CSV unificado
    if ([string]::IsNullOrWhiteSpace($nombreArchivoUnificado)) {
        $nombreArchivoUnificado = "Unificado.csv"
    }

    # Crear el archivo CSV unificado
    $rutaArchivoUnificado = Join-Path -Path $directorioActual -ChildPath $nombreArchivoUnificado
    $primeraVez = $true
    $totalFilas = ($archivosCSV | Measure-Object -Property Length -Sum).Sum
    $filasRestantes = $totalFilas
    $contadorFilas = 0

    foreach ($archivo in $archivosCSV) {
        # Leer el contenido del archivo CSV actual
        $contenido = Get-Content $archivo.FullName

        # Verificar si se debe eliminar el encabezado
        if ($eliminarHeader -and $primeraVez) {
            $contenido = $contenido[1..($contenido.Count - 1)]
            $primeraVez = $false
        }

        # Escribir el contenido en el archivo unificado
        Add-Content -Path $rutaArchivoUnificado -Value $contenido

        # Actualizar la barra de progreso
        $contadorFilas += $contenido.Count
        $porcentaje = ($contadorFilas / $totalFilas) * 100
        Write-Progress -Activity "Unificando archivos CSV..." -Status "Escribiendo archivo unificado..." -PercentComplete $porcentaje -CurrentOperation "Filas restantes: $($totalFilas - $contadorFilas)"
    }

    # Mostrar mensaje de finalización
    Write-Host "La unificación de archivos CSV ha sido completada."

    # Eliminar archivos CSV originales si se solicita
    if ($eliminarArchivosOrigen) {
        foreach ($archivo in $archivosCSV) {
            Remove-Item $archivo.FullName -Force
        }
        Write-Host "Los archivos CSV originales han sido eliminados."
    }

    # Abrir la carpeta con el archivo CSV unificado
    Invoke-Item -Path $directorioActual
}

# Mostrar banner
MostrarBanner

# Obtener la ruta del directorio donde se encuentra el script
$rutaScript = if ($null -eq $MyInvocation.MyCommand.Path) { $PWD } else { Split-Path -Parent $MyInvocation.MyCommand.Path }

# Solicitar al usuario la máscara para buscar archivos CSV
do {
    $mascara = Read-Host "Ingrese la máscara para buscar archivos CSV (por ejemplo, '*.csv'):"
    # Verificar si se encontraron archivos CSV que coincidan con la máscara
    $archivosCSV = Get-ChildItem -Path $rutaScript -Filter $mascara -File | Where-Object { $_.Extension -eq ".csv" }
    if ($archivosCSV.Count -eq 0) {
        Write-Host "No se encontraron archivos CSV que coincidan con la máscara '$mascara' en el directorio actual."
    } else {
        Write-Host "Archivos encontrados que coinciden con la máscara '$mascara':"
        $archivosCSV | ForEach-Object { Write-Host $_.Name }
        $confirmacion = Read-Host "¿Desea continuar con estos archivos? (S/N):"
        if ($confirmacion -eq "S") {
            break
        }
    }
} while ($true)

# Solicitar al usuario si desea eliminar el encabezado de los archivos CSV
$eliminarHeaderInput = Read-Host "¿Desea eliminar el encabezado de los archivos CSV? (S/N):"
if ($eliminarHeaderInput -eq "S") {
    $eliminarHeader = $true
} else {
    $eliminarHeader = $false
}
# Solicitar al usuario si desea eliminar los archivos CSV originales después de la unificación
$eliminarArchivosOrigenInput = Read-Host "¿Desea eliminar los archivos CSV originales después de la unificación? (S/N):"
if ($eliminarArchivosOrigenInput -eq "S") {
    $eliminarArchivosOrigen = $true
} else {
    $eliminarArchivosOrigen = $false
}
# Solicitar al usuario el nombre del archivo CSV unificado
$nombreArchivoUnificado = Read-Host "Ingrese el nombre para el archivo CSV unificado:"
# Solicitar al usuario el directorio donde se encuentran los archivos CSV (opcional)
$directorio = Read-Host "Ingrese la ruta del directorio donde se encuentran los archivos CSV (presione Enter para utilizar el directorio actual):"

# Mostrar confirmación final
Write-Host "Resumen de acciones:"
Write-Host "  - Máscara de archivos: $mascara"
Write-Host "  - Eliminar encabezado: $eliminarHeader"
Write-Host "  - Eliminar archivos originales: $eliminarArchivosOrigen"
Write-Host "  - Nombre del archivo unificado: $nombreArchivoUnificado"
$confirmacionFinal = Read-Host "¿Desea continuar con estas acciones? (S/N):"

if ($confirmacionFinal -ne "S") {
    Write-Host "Operación cancelada."
    return
}

# Ejecutar la función para unificar archivos CSV
UnificarArchivosCSV -mascara $mascara -eliminarHeader:$eliminarHeader -eliminarArchivosOrigen:$eliminarArchivosOrigen -nombreArchivoUnificado $nombreArchivoUnificado -directorio $directorio